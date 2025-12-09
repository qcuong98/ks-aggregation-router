# IKSAggregationRouterV3
[Git Source](https://github.com/KyberNetwork/ks-aggregation-router/blob/117711a92311a1ccde02acb925aa9f797123a2af/src/interfaces/IKSAggregationRouterV3.sol)


## Functions
### swap

Entry point for swapping


```solidity
function swap(SwapParams calldata params)
  external
  payable
  returns (uint256[] memory outputAmounts, uint256 gasUsed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SwapParams`|The parameters for the swap|


### msgSender

Returns the address of who called the swap function


```solidity
function msgSender() external view returns (address);
```

## Events
### Swap
Emitted when a swap is executed


```solidity
event Swap(
  address indexed sender,
  address indexed executor,
  address indexed recipient,
  address[] inputTokens,
  uint256[] inputAmounts,
  address[] outputTokens,
  uint256[] outputAmounts
);
```

### ClientData
Emitted when the client data is set


```solidity
event ClientData(bytes clientData);
```

### CollectFee
Emitted when the fee is collected


```solidity
event CollectFee(address token, uint256 totalAmount, uint256 feeAmount, address recipient);
```

## Errors
### DeadlinePassed
Thrown when the deadline is passed


```solidity
error DeadlinePassed(uint256 deadline, uint256 blockTimestamp);
```

### InvalidMsgValue
Thrown when the msg.value is less than the required amount


```solidity
error InvalidMsgValue(uint256 required, uint256 provided);
```

### NotEnoughOutputAmount
Thrown when the output amount is less than the minimum amount


```solidity
error NotEnoughOutputAmount(uint256 minAmount, uint256 outputAmount);
```

### TooLargeInputAmount
Thrown when the input amount is too large


```solidity
error TooLargeInputAmount(uint256 inputAmount);
```

### CallExecutorFailed
Thrown when failed to call the executor


```solidity
error CallExecutorFailed();
```

### Permit2Failed
Thrown when failed to call permit2


```solidity
error Permit2Failed();
```

### TotalTransferredExceeded
Thrown when the total transferred amount exceeds the total amount


```solidity
error TotalTransferredExceeded(uint256 totalAmount, uint256 totalTransferred);
```

## Structs
### InputTokenData
Contains the additional data for an input token


```solidity
struct InputTokenData {
  // Permit method selection:
  // length = 5 * 32: use ERC20 `permit`
  // length = 6 * 32: use DAI `permit`
  // Transfer method selection:
  // length == 0: use Permit2 `transferFrom`
  // length != 0: use ERC20 `transferFrom`
  bytes permitData;
  address[] feeRecipients;
  uint256[] fees;
  address[] targets;
  uint256[] amounts;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`permitData`|`bytes`|The permit data|
|`feeRecipients`|`address[]`|The fee recipients|
|`fees`|`uint256[]`|The fees, either in bps or absolute value|
|`targets`|`address[]`|The targets to transfer the input token to|
|`amounts`|`uint256[]`|The amounts to transfer to the targets|

### OutputTokenData
Contains the additional data for an output token


```solidity
struct OutputTokenData {
  uint256 minAmount;
  address[] feeRecipients;
  uint256[] fees;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`minAmount`|`uint256`|The minimum output amount|
|`feeRecipients`|`address[]`|The fee recipients|
|`fees`|`uint256[]`|The fees, either in bps or absolute value|

### SwapParams
Contains the parameters for a swap


```solidity
struct SwapParams {
  address[] inputTokens;
  uint256[] inputAmounts;
  InputTokenData[] inputData;
  address[] outputTokens;
  OutputTokenData[] outputData;
  bytes permit2Data;
  address executor;
  bytes executorData;
  address recipient;
  uint256 deadline;
  bytes clientData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`inputTokens`|`address[]`|The input tokens|
|`inputAmounts`|`uint256[]`|The input amounts (only used for fee calculation)|
|`inputData`|`InputTokenData[]`|The additional data for the input tokens|
|`outputTokens`|`address[]`|The output tokens|
|`outputData`|`OutputTokenData[]`|The additional data for the output tokens|
|`permit2Data`|`bytes`|The data to call permit2 with|
|`executor`|`address`|The executor to call|
|`executorData`|`bytes`|The data to pass to the executor|
|`recipient`|`address`|The recipient of the output tokens|
|`deadline`|`uint256`|The deadline for the swap|
|`clientData`|`bytes`|The client data|

