# KSAggregationRouterV3 Architecture

## Overview

KSAggregationRouterV3 is a sophisticated DeFi aggregation router smart contract built on Solidity 0.8.30. It enables efficient token swapping with advanced features including fee collection, permit-based approvals, and modular execution through external executors.

## Core Components

### Main Contract: `KSAggregationRouterV3`

**File:** `src/KSAggregationRouterV3.sol`

The main router contract that inherits from:
- `ManagementPausable` - Emergency pause functionality
- `ManagementRescuable` - Asset recovery mechanisms  
- `Lock` - Reentrancy protection

**Key Features:**
- **Multi-token swaps** with configurable input/output tokens
- **Fee collection** system with flexible fee structures
- **Permit2 integration** for gasless approvals
- **Executor pattern** for modular swap logic
- **Native ETH support** alongside ERC20 tokens

### Interfaces

#### `IKSAggregationRouterV3`
**File:** `src/interfaces/IKSAggregationRouterV3.sol`

Defines the main router interface including:
- `SwapParams` struct for swap configuration
- `InputTokenData` and `OutputTokenData` for token-specific parameters
- Events for swap tracking and fee collection
- Error definitions for failure scenarios

#### `IKSAggregationExecutor`
**File:** `src/interfaces/IKSAggregationExecutor.sol`

Simple interface for executor contracts:
- `callBytes(bytes calldata data)` - Entry point for swap execution

## Architecture Patterns

### 1. Executor Pattern

The router delegates actual swap logic to external executor contracts. This provides:
- **Modularity**: Different executors for different DEX protocols
- **Upgradability**: New executors can be added without changing the router
- **Gas efficiency**: Specialized executors optimized for specific protocols

### 2. Fee Management

Sophisticated fee collection system supporting:
- **Basis point fees**: Percentage-based fees (e.g., 0.3%)
- **Absolute fees**: Fixed token amounts
- **Multiple recipients**: Fees can be split between multiple addresses
- **Input/output fees**: Fees on both input tokens (before swap) and output tokens (after swap)

### 3. Permit Integration

Supports multiple permit standards:
- **ERC20Permit**: Standard permit (5 parameters)
- **DAI-like permit**: DAI-style permit (6 parameters)
- **Permit2**: Uniswap's advanced permit system
- **Direct transfer**: Fallback to standard transferFrom

### 4. Balance Tracking

Careful balance management:
- **Pre-swap recording**: Records balances before swap execution
- **Post-swap calculation**: Calculates actual amounts received
- **Dust protection**: Keeps minimum balances to prevent zero-balance edge cases
- **Refund mechanism**: Returns unused input tokens to sender

## Security Features

### Access Control & Special Roles

The contract implements a comprehensive role-based access control system with three distinct privilege levels:

#### **Admin Role**
- **Full contract control**: Can grant/revoke all roles including other admins
- **Configuration management**: Can modify critical contract parameters
- **Ultimate authority**: Has override capabilities for emergency situations
- **Deployment**: Set during contract construction and managed through `ManagementBase`

#### **Guardian Role** 
- **Emergency pause authority**: Can immediately pause all swap operations via `pause()`
- **Risk mitigation**: Designed for rapid response to security threats or market anomalies
- **Limited scope**: Cannot modify core contract logic or access funds
- **Multi-guardian support**: Multiple addresses can hold guardian privileges for redundancy

#### **Rescuer Role**
- **Asset recovery capabilities**: Can rescue tokens stuck in the contract via rescue functions
- **Emergency fund access**: Authority to recover user funds in extreme scenarios
- **Operational continuity**: Ensures contract can recover from unexpected token accumulation
- **Restricted permissions**: Cannot pause operations or modify contract logic

### Re-entrancy Protection
- **Lock mechanism**: Prevents recursive calls during swaps using the `Lock` contract
- **State validation**: Ensures consistent state throughout execution

### Input Validation
- **Array length checks**: Ensures matching array lengths for related parameters
- **Minimum output validation**: Protects against sandwich attacks
- **Sufficient input validation**: Ensures adequate input amounts

## Data Flow

### Swap Execution Flow

```
1. Record input token balances
2. Record output token balances  
3. Execute permit2 calls (if needed)
4. Collect input tokens with fees
5. Call executor with swap data
6. Process output tokens with fees
7. Refund remaining input tokens
8. Emit events
```

### Token Collection Process

**Input Tokens:**
1. Check permit data format
2. If Permit2: Use batch transfer for fees + targets
3. If native ETH: Direct transfers with validation
4. If ERC20: Standard transferFrom calls

**Output Tokens:**
1. Calculate received amounts
2. Deduct fees for fee recipients
3. Transfer remaining to recipient
4. Validate minimum amounts

## Configuration

### Deployment Configuration

**Files:** `script/config/*.json`
- `admin.json` - Contract administrator address
- `guardians.json` - Emergency pause addresses
- `rescuers.json` - Asset recovery addresses
- `permit2.json` - Permit2 contract address
- `router.json` - Deployed router address

### Build Configuration

**File:** `foundry.toml`
- Optimized compilation with 44M+ optimizer runs
- Via-IR compilation for better optimization
- Custom file system permissions for config access

## Constants

- `FLAG_MASK = 1 << 255` - Distinguishes between percentage and absolute fees
- `AMOUNT_MASK = (1 << 255) - 1` - Extracts amount from flagged values
- `FEE_DENOMINATOR = 1_000_000` - Basis points denominator (100% = 1M)

## Dependencies

### External Libraries
- **OpenZeppelin**: Standard ERC20 interfaces and utilities
- **KS Common SC**: Shared KyberSwap contracts for management and token utilities

### Key Utilities
- `TokenHelper` - Safe token transfer operations
- `PermitHelper` - Multi-standard permit handling  
- `CustomRevert` - Advanced error propagation
- `KSRoles` - Role-based access control constants

## Integration Points

### For Frontend/SDK Integration
- Use `SwapParams` struct to configure swaps
- Monitor `Swap` and `CollectFee` events
- Handle permit data based on token standards
- Implement proper slippage protection via `minAmount`

### For Executor Development
- Implement `IKSAggregationExecutor` interface
- Handle native ETH and ERC20 tokens
- Assume no pre-existing balances (executor should not hold funds)
- Use `msgSender()` to identify original swap initiator