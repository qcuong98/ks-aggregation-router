// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title Lock
/// @notice A contract that provides a reentrancy lock for every calls
contract Lock {
  /// @notice Thrown when attempting to reenter a locked function
  error ContractLocked();

  // The slot holding the locker state, transiently. bytes32(uint256(keccak256("Locker")) - 1)
  bytes32 constant LOCKER_SLOT = 0x0e87e1788ebd9ed6a7e63c70a374cd3283e41cad601d21fbe27863899ed4a708;

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
      tstore(LOCKER_SLOT, locker)
    }
  }

  /// @notice return the current locker of the contract
  function _getLocker() internal view returns (address locker) {
    assembly ("memory-safe") {
      locker := tload(LOCKER_SLOT)
    }
  }
}
