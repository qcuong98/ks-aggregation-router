// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKSAggregationExecutor {
  function callBytes(bytes calldata data) external payable;
}
