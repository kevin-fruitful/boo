// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { console as c } from "forge-std/Test.sol";
import { BaseScript } from "./Base.s.sol";

import "src/interfaces/IBoo.sol";

import { AaveV3Ethereum, AaveV3EthereumAssets } from "aave-address-book/AaveV3Ethereum.sol";

contract CallBooScript is BaseScript {
    function run() public broadcast {
        IBoo(address(AaveV3Ethereum.POOL)).boo(AaveV3EthereumAssets.USDC_UNDERLYING, 100_000_000, false);
    }
}
