# KSAggregationRouterV3
[Git Source](https://github.com/KyberNetwork/ks-aggregation-router/blob/117711a92311a1ccde02acb925aa9f797123a2af/src/KSAggregationRouterV3.sol)

**Inherits:**
[IKSAggregationRouterV3](/Users/tqcuong/Projects/KyberNetwork/ks-aggregation-router/docs/src/src/interfaces/IKSAggregationRouterV3.sol/interface.IKSAggregationRouterV3.md), ManagementPausable, ManagementRescuable, Lock


## State Variables
### FLAG_MASK

```solidity
uint256 internal constant FLAG_MASK = 1 << 255
```


### AMOUNT_MASK

```solidity
uint256 internal constant AMOUNT_MASK = (1 << 255) - 1
```


### FEE_DENOMINATOR

```solidity
uint256 internal constant FEE_DENOMINATOR = 1_000_000
```


### EXECUTOR_ROLE

```solidity
bytes32 public constant EXECUTOR_ROLE = keccak256('EXECUTOR_ROLE')
```


### PERMIT2

```solidity
IAllowanceTransfer public immutable PERMIT2
```


## Functions
### constructor


```solidity
constructor(
  address initialAdmin,
  address[] memory initialGuardians,
  address[] memory initialRescuers,
  address[] memory initialExecutors,
  IAllowanceTransfer _permit2
) ManagementBase(0, initialAdmin);
```

### receive


```solidity
receive() external payable;
```

### swap

Entry point for swapping


```solidity
function swap(SwapParams calldata params)
  external
  payable
  isNotLocked
  whenNotPaused
  returns (uint256[] memory outputAmounts, uint256 gasUsed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SwapParams`|The parameters for the swap|


### msgSender


```solidity
function msgSender() external view returns (address);
```

### _recordInputBalances

Record the balances of the input tokens before the swap


```solidity
function _recordInputBalances(address[] calldata inputTokens)
  internal
  view
  returns (uint256[] memory inputBalances);
```

### _collectInputTokens

Transfer the input tokens to the destinations


```solidity
function _collectInputTokens(
  address[] calldata inputTokens,
  uint256[] calldata inputAmounts,
  InputTokenData[] calldata inputData
)
  internal
  checkLengths(inputTokens.length, inputAmounts.length)
  checkLengths(inputTokens.length, inputData.length);
```

### _collectInputToken

Take fees and transfer the input token to the destinations


```solidity
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
  checkLengths(targets.length, amounts.length);
```

### _recordOutputBalances

Record the balances of the output tokens before the swap


```solidity
function _recordOutputBalances(
  address[] calldata outputTokens,
  OutputTokenData[] calldata outputData,
  address recipient
)
  internal
  view
  checkLengths(outputTokens.length, outputData.length)
  returns (uint256[] memory outputBalances);
```

### _callExecutor

Call the executor contract to execute the swap


```solidity
function _callExecutor(address executor, uint256 nativeValue, bytes calldata executorData)
  internal;
```

### _refundInputTokens

Refund the remaining input tokens to the sender


```solidity
function _refundInputTokens(
  address[] calldata inputTokens,
  uint256[] memory inputBalances,
  address recipient
) internal;
```

### _processOutputTokens

Take fees and transfer the output tokens to the recipient


```solidity
function _processOutputTokens(
  address[] calldata outputTokens,
  OutputTokenData[] calldata outputData,
  uint256[] memory outputBalances,
  address recipient
) internal returns (uint256[] memory outputAmounts);
```

### _processOutputToken

Take fees and transfer the output token to the recipient


```solidity
function _processOutputToken(
  address token,
  uint256 previousBalance,
  uint256 minAmount,
  address[] calldata feeRecipients,
  uint256[] calldata fees,
  address recipient
) internal checkLengths(feeRecipients.length, fees.length) returns (uint256 outputAmount);
```

### _safeTransferFrom


```solidity
function _safeTransferFrom(address token, address from, address to, uint256 amount) internal;
```

### _selfBalanceMinusMsgValue

Get the balance of the token, minus the msg.value if the token is native token


```solidity
function _selfBalanceMinusMsgValue(address token) internal view returns (uint256 balance);
```

### _computeFeeAmount

Compute the fee amount, either in bps or absolute value


```solidity
function _computeFeeAmount(uint256 totalAmount, uint256 fee) internal pure returns (uint256);
```

