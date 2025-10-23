// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'ks-common-sc/script/Base.s.sol';

import 'src/KSAggregationRouterV3.sol';

contract DeployScript is BaseScript {
  string salt = '';

  address admin;
  address[] guardians;
  address[] rescuers;
  address[] executors;
  address permit2;

  function setUp() public override {
    super.setUp();

    admin = _readAddress('admin');
    guardians = _readAddressArray('guardians');
    rescuers = _readAddressArray('rescuers');
    executors = _readAddressArray('executors');
    permit2 = _readAddress('permit2');
  }

  function run() public {
    if (bytes(salt).length == 0) {
      revert('salt is required');
    }
    salt = string.concat('KSAggregationRouterV3_', salt);

    bytes memory creationCode = abi.encodePacked(
      type(KSAggregationRouterV3).creationCode,
      abi.encode(admin, guardians, rescuers, executors, permit2)
    );

    // Deploy the router
    vm.startBroadcast();
    address newRouter = _create3Deploy(keccak256(abi.encodePacked(salt)), creationCode);
    vm.stopBroadcast();

    // Write the router address to the config file
    _writeAddress('router', newRouter);
  }
}
