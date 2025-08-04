// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Lock} from './Lock.sol';

import {IKSAggregationExecutor} from './interfaces/IKSAggregationExecutor.sol';
import {IKSAggregationRouterV3} from './interfaces/IKSAggregationRouterV3.sol';

import {IAllowanceTransfer} from 'ks-common-sc/src/interfaces/IAllowanceTransfer.sol';

import {CustomRevert} from 'ks-common-sc/src/libraries/CustomRevert.sol';
import {KSRoles} from 'ks-common-sc/src/libraries/KSRoles.sol';
import {PermitHelper} from 'ks-common-sc/src/libraries/token/PermitHelper.sol';
import {TokenHelper} from 'ks-common-sc/src/libraries/token/TokenHelper.sol';

import {ManagementBase} from 'ks-common-sc/src/base/ManagementBase.sol';
import {ManagementPausable} from 'ks-common-sc/src/base/ManagementPausable.sol';
import {ManagementRescuable} from 'ks-common-sc/src/base/ManagementRescuable.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

contract KSAggregationRouterV3 is
  IKSAggregationRouterV3,
  ManagementPausable,
  ManagementRescuable,
  Lock
{
  using TokenHelper for address;
  using PermitHelper for address;

  uint256 constant FLAG_MASK = 1 << 255;

  uint256 constant AMOUNT_MASK = (1 << 255) - 1;

  uint256 constant FEE_DENOMINATOR = 1_000_000;

  IAllowanceTransfer public immutable permit2;

  constructor(
    address initialAdmin,
    address[] memory initialGuardians,
    address[] memory initialRescuers,
    IAllowanceTransfer _permit2
  ) ManagementBase(0, initialAdmin) {
    _batchGrantRole(KSRoles.GUARDIAN_ROLE, initialGuardians);
    _batchGrantRole(KSRoles.RESCUER_ROLE, initialRescuers);

    permit2 = _permit2;
  }

  receive() external payable {}

  /// @inheritdoc IKSAggregationRouterV3
  function swap(SwapParams calldata params) external payable isNotLocked whenNotPaused {
    uint256[] memory inputBalances = _recordInputBalances(params.inputTokens);
    uint256[] memory outputBalances =
      _recordOutputBalances(params.outputTokens, params.outputData, params.recipient);
    uint256 nativeBalanceBefore = address(this).balance - msg.value;

    _callPermit2(params.permit2Data);
    _collectInputTokens(params.inputTokens, params.inputAmounts, params.inputData);

    _callExecutor(params.executor, address(this).balance - nativeBalanceBefore, params.executorData);

    uint256[] memory outputAmounts =
      _processOutputTokens(params.outputTokens, params.outputData, outputBalances, params.recipient);
    _refundInputTokens(params.inputTokens, inputBalances);

    emit Swap(
      msg.sender,
      params.executor,
      params.recipient,
      params.inputTokens,
      params.inputAmounts,
      params.outputTokens,
      outputAmounts
    );

    emit ClientData(params.clientData);
  }

  function msgSender() external view returns (address) {
    return _getLocker();
  }

  /// @dev Record the balances of the input tokens before the swap
  function _recordInputBalances(address[] calldata inputTokens)
    internal
    view
    returns (uint256[] memory inputBalances)
  {
    inputBalances = new uint256[](inputTokens.length);
    for (uint256 i = 0; i < inputTokens.length; i++) {
      inputBalances[i] = _selfBalanceMinusMsgValue(inputTokens[i]);
    }
  }

  /// @dev Call the permit2 contract to transfer the input tokens
  function _callPermit2(bytes calldata permit2Data) internal {
    if (permit2Data.length > 0) {
      (bool success,) =
        address(permit2).call(abi.encodePacked(IAllowanceTransfer.permit.selector, permit2Data));
      if (!success) {
        CustomRevert.bubbleUpAndRevertWith(
          address(permit2), IAllowanceTransfer.permit.selector, Permit2Failed.selector
        );
      }
    }
  }

  /// @dev Transfer the input tokens to the destinations
  function _collectInputTokens(
    address[] calldata inputTokens,
    uint256[] calldata inputAmounts,
    InputTokenData[] calldata inputData
  ) internal {
    for (uint256 i = 0; i < inputData.length; i++) {
      _collectInputToken(
        inputTokens[i],
        inputAmounts[i],
        inputData[i].permitData,
        inputData[i].feeRecipients,
        inputData[i].fees,
        inputData[i].targets,
        inputData[i].amounts
      );
    }
  }

  /// @dev Take fees and transfer the input token to the destinations
  function _collectInputToken(
    address token,
    uint256 totalAmount,
    bytes calldata permitData,
    address[] calldata feeRecipients,
    uint256[] calldata fees,
    address[] calldata targets,
    uint256[] calldata amounts
  )
    internal
    checkLengths(feeRecipients.length, fees.length)
    checkLengths(targets.length, amounts.length)
  {
    if (!token.erc20Permit(msg.sender, permitData) && permitData.length > 0) {
      IAllowanceTransfer.AllowanceTransferDetails[] memory details =
        new IAllowanceTransfer.AllowanceTransferDetails[](feeRecipients.length + targets.length);

      for (uint256 i = 0; i < feeRecipients.length; i++) {
        uint256 feeAmount = _computeFeeAmount(totalAmount, fees[i]);
        details[i] = IAllowanceTransfer.AllowanceTransferDetails({
          from: msg.sender,
          to: feeRecipients[i],
          amount: uint160(feeAmount),
          token: token
        });

        if (feeAmount > 0) {
          emit CollectFee(token, totalAmount, feeAmount, feeRecipients[i]);
        }
      }
      for (uint256 i = 0; i < targets.length; i++) {
        details[i + feeRecipients.length] = IAllowanceTransfer.AllowanceTransferDetails({
          from: msg.sender,
          to: targets[i],
          amount: uint160(amounts[i]),
          token: token
        });
      }

      permit2.transferFrom(details);
    } else if (token.isNative()) {
      require(totalAmount <= msg.value, NotEnoughMsgValue(totalAmount, msg.value));

      for (uint256 i = 0; i < feeRecipients.length; i++) {
        uint256 feeAmount = _computeFeeAmount(totalAmount, fees[i]);

        if (feeAmount > 0) {
          feeRecipients[i].safeTransferNative(feeAmount);

          emit CollectFee(token, totalAmount, feeAmount, feeRecipients[i]);
        }
      }
    } else {
      for (uint256 i = 0; i < feeRecipients.length; i++) {
        uint256 feeAmount = _computeFeeAmount(totalAmount, fees[i]);

        if (feeAmount > 0) {
          token.safeTransferFrom(msg.sender, feeRecipients[i], feeAmount);

          emit CollectFee(token, totalAmount, feeAmount, feeRecipients[i]);
        }
      }
      for (uint256 i = 0; i < targets.length; i++) {
        token.safeTransferFrom(msg.sender, targets[i], amounts[i]);
      }
    }
  }

  /// @dev Record the balances of the output tokens before the swap
  function _recordOutputBalances(
    address[] calldata outputTokens,
    OutputTokenData[] calldata outputData,
    address recipient
  ) internal view returns (uint256[] memory outputBalances) {
    outputBalances = new uint256[](outputTokens.length);
    for (uint256 i = 0; i < outputTokens.length; i++) {
      if (outputData[i].feeRecipients.length == 0) {
        outputBalances[i] = outputTokens[i].balanceOf(recipient);
      } else {
        outputBalances[i] = _selfBalanceMinusMsgValue(outputTokens[i]);
      }
    }
  }

  /// @dev Call the executor contract to execute the swap
  function _callExecutor(address executor, uint256 nativeValue, bytes calldata executorData)
    internal
  {
    (bool success,) = executor.call{value: nativeValue}(
      abi.encodePacked(IKSAggregationExecutor.callBytes.selector, executorData)
    );
    if (!success) {
      CustomRevert.bubbleUpAndRevertWith(
        executor, IKSAggregationExecutor.callBytes.selector, CallExecutorFailed.selector
      );
    }
  }

  /// @dev Refund the remaining input tokens to the sender
  function _refundInputTokens(address[] calldata inputTokens, uint256[] memory inputBalances)
    internal
  {
    for (uint256 i = 0; i < inputTokens.length; i++) {
      address token = inputTokens[i];
      uint256 refundAmount = token.selfBalance() - inputBalances[i];
      // Keep at least one token in the contract
      if (refundAmount > 0 && inputBalances[i] == 0) {
        unchecked {
          refundAmount--;
        }
      }
      token.safeTransfer(msg.sender, refundAmount);
    }
  }

  /// @dev Take fees and transfer the output tokens to the recipient
  function _processOutputTokens(
    address[] calldata outputTokens,
    OutputTokenData[] calldata outputData,
    uint256[] memory outputBalances,
    address recipient
  ) internal returns (uint256[] memory outputAmounts) {
    outputAmounts = new uint256[](outputTokens.length);
    for (uint256 i = 0; i < outputData.length; i++) {
      outputAmounts[i] = _processOutputToken(
        outputTokens[i],
        outputBalances[i],
        outputData[i].minAmount,
        outputData[i].feeRecipients,
        outputData[i].fees,
        recipient
      );
    }
  }

  /// @dev Take fees and transfer the output token to the recipient
  function _processOutputToken(
    address token,
    uint256 previousBalance,
    uint256 minAmount,
    address[] calldata feeRecipients,
    uint256[] calldata fees,
    address recipient
  ) internal checkLengths(feeRecipients.length, fees.length) returns (uint256 outputAmount) {
    if (feeRecipients.length > 0) {
      outputAmount = token.selfBalance() - previousBalance;
      // Keep at least one token in the contract
      if (outputAmount > 0 && previousBalance == 0) {
        unchecked {
          outputAmount--;
        }
      }

      uint256 totalFeeAmount = 0;
      for (uint256 i = 0; i < feeRecipients.length; i++) {
        uint256 feeAmount = _computeFeeAmount(outputAmount, fees[i]);

        if (feeAmount > 0) {
          token.safeTransfer(feeRecipients[i], feeAmount);
          totalFeeAmount += feeAmount;

          emit CollectFee(token, outputAmount, feeAmount, feeRecipients[i]);
        }
      }

      outputAmount -= totalFeeAmount;
      require(outputAmount >= minAmount, NotEnoughOutputAmount(minAmount, outputAmount));

      token.safeTransfer(recipient, outputAmount);
    } else {
      outputAmount = token.balanceOf(recipient) - previousBalance;
      require(outputAmount >= minAmount, NotEnoughOutputAmount(minAmount, outputAmount));
    }
  }

  /// @dev Get the balance of the token, minus the msg.value if the token is native token
  function _selfBalanceMinusMsgValue(address token) internal view returns (uint256 balance) {
    if (token.isNative()) {
      balance = address(this).balance - msg.value;
    } else {
      balance = IERC20(token).balanceOf(address(this));
    }
  }

  /// @dev Compute the fee amount, either in bps or absolute value
  function _computeFeeAmount(uint256 totalAmount, uint256 fee) internal pure returns (uint256) {
    if ((fee & FLAG_MASK) == 0) {
      return totalAmount * fee / FEE_DENOMINATOR;
    } else {
      return fee & AMOUNT_MASK;
    }
  }
}
