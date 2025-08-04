// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKSAggregationExecutor {
  /// @notice Entry point for the executor to execute the swap
  /// @param data The encoded data for the swap
  function callBytes(bytes calldata data) external payable;
}
