// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataWarehouse} from 'contracts/voting/DataWarehouse.sol';
import {AliceGovernor} from 'examples/AliceGovernor.sol';
import {RabbitToken} from 'examples/RabbitToken.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';

import {Script, console} from 'forge-std/Script.sol';

abstract contract Deploy is Script {
  function _deploy(address _deployer) internal {
    vm.startBroadcast(_deployer);

    // Deploy the contracts
    DataWarehouse dataWarehouse = new DataWarehouse();
    console.log('Datawarehouse:', address(dataWarehouse));
    address tokenAddress = vm.computeCreateAddress(_deployer, vm.getNonce(_deployer) + 1);
    AliceGovernor governor = new AliceGovernor(tokenAddress, dataWarehouse);
    console.log('WonderGovernor:', address(governor));
    RabbitToken rabbitToken = new RabbitToken(AliceGovernor(payable(address(governor))));
    console.log('WonderVotes:', address(rabbitToken));

    rabbitToken.mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 200_000e18);
    rabbitToken.mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 200_000e18);
    rabbitToken.mint(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 200_000e18);
    rabbitToken.mint(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 200_000e18);
    rabbitToken.mint(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, 200_000e18);

    vm.stopBroadcast();
  }
}

contract DeployMainnet is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('MAINNET_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}

contract DeployGoerli is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('GOERLI_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}

contract DeployLocal is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('LOCAL_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}

contract DeployOptimism is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('OPTIMISM_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}
