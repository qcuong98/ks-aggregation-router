// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title Lock
/// @notice A contract that provides a reentrancy lock for every calls
contract Lock {
  /// @notice Thrown when attempting to reenter a locked function
  error ContractLocked();

  // The slot holding the locker state, transiently. bytes32(uint256(keccak256("KSLocker")) - 1)
  bytes32 constant KS_LOCKER_SLOT =
    0x0d4361b83f2b162dbcc7500741105e695a1e5d46caa81010b58c5c4881da8172;

  /// @notice Modifier enforcing a reentrancy lock
  /// @dev If the contract is not locked, use msg.sender as the locker
  modifier isNotLocked() {
    if (_getLocker() != address(0)) revert ContractLocked();
    _setLocker(msg.sender);
    _;
    _setLocker(address(0));
  }

  /// @notice set the locker of the contract
  function _setLocker(address locker) internal {
    // The locker is always msg.sender or address(0) so does not need to be cleaned
    assembly ("memory-safe") {
      tstore(KS_LOCKER_SLOT, locker)
    }
  }

  /// @notice return the current locker of the contract
  function _getLocker() internal view returns (address locker) {
    assembly ("memory-safe") {
      locker := tload(KS_LOCKER_SLOT)
    }
  }
}
