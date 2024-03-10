// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test, console as c } from "forge-std/Test.sol";

import { Boo } from "src/Boo.sol";
import { LibConstants as LC } from "src/LibConstants.sol";

import { IAToken } from "aave-v3-core/contracts/interfaces/IAToken.sol";
import { IPoolAddressesProvider } from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import { AaveV3Ethereum, AaveV3EthereumAssets } from "aave-address-book/AaveV3Ethereum.sol";
import { WalletBalanceProvider } from "aave-v3-periphery/misc/WalletBalanceProvider.sol";

import { ICometExt } from "src/interfaces/ICometExt.sol";

contract BooTest is Test {
    Boo public BOO;
    IAToken public AUSDC;
    IAToken public USDC;

    WalletBalanceProvider public WBP;

    function startPrank(address target) public {
        vm.startPrank(target);
    }

    function setUp() public {
        vm.createSelectFork("mainnet", 19_400_000);
        // vm.createSelectFork("anvil");

        WBP = (new WalletBalanceProvider)();

        BOO = (new Boo)(IPoolAddressesProvider(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER));
        AUSDC = IAToken(AaveV3EthereumAssets.USDC_A_TOKEN);
        USDC = IAToken(AaveV3EthereumAssets.USDC_UNDERLYING);

        vm.etch(address(AaveV3Ethereum.POOL), address(BOO).code);
        BOO = Boo(address(AaveV3Ethereum.POOL));

        vm.label(LC.COMET_WHALE, "COMET WHALE");
        vm.label(AaveV3EthereumAssets.USDC_UNDERLYING, "USDC PROXY");
        vm.label(AaveV3EthereumAssets.USDC_A_TOKEN, "ATOKEN USDC");
        vm.label(address(AaveV3Ethereum.ORACLE), "AAVE ORACLE");
        vm.label(address(AaveV3Ethereum.POOL), "AAVE POOL");
    }

    function testBoo() public {
        startPrank(LC.COMET_WHALE);
        ICometExt(LC.COMET_USDC).allow(address(BOO), true);

        uint256 scaledBalanceBefore = AUSDC.scaledBalanceOf(LC.COMET_WHALE);
        BOO.boo({ asset: AaveV3EthereumAssets.USDC_UNDERLYING, amount: 100_000_000, lockCollateral: false });
        uint256 scaledBalanceAfter = AUSDC.scaledBalanceOf(LC.COMET_WHALE);

        assertLt(scaledBalanceBefore, scaledBalanceAfter);
    }

    function testClaimWithLock() public {
        startPrank(LC.COMET_WHALE);
        ICometExt(LC.COMET_USDC).allow(address(BOO), true);
        BOO.boo({ asset: AaveV3EthereumAssets.USDC_UNDERLYING, amount: 100_000_000, lockCollateral: true });

        (bool canClaim) = BOO.claim({ asset: AaveV3EthereumAssets.USDC_UNDERLYING });
        assertEq(canClaim, false);
        vm.warp(block.timestamp + 26 weeks + 1 days);
        (canClaim) = BOO.claim({ asset: AaveV3EthereumAssets.USDC_UNDERLYING });
        assertEq(canClaim, true);

        assertEq(BOO.rewards(LC.COMET_WHALE).discountedBorrowingRates, true);
    }

    function testClaimWithoutLock() public {
        startPrank(LC.COMET_WHALE);
        ICometExt(LC.COMET_USDC).allow(address(BOO), true);
        BOO.boo({ asset: AaveV3EthereumAssets.USDC_UNDERLYING, amount: 100_000_000, lockCollateral: false });

        vm.warp(block.timestamp + 26 weeks + 1 days);
        (bool canClaim) = BOO.claim({ asset: AaveV3EthereumAssets.USDC_UNDERLYING });
        assertEq(canClaim, false);
    }

    function testNormalWithdraw() public {
        startPrank(LC.COMET_WHALE);
        BOO.withdraw({ asset: AaveV3EthereumAssets.USDC_UNDERLYING, amount: 100_000_000, to: LC.COMET_WHALE });
    }

    function testWithdrawLockedFunds() public {
        testClaimWithLock();

        // Try withdrawing locked funds
        BOO.withdraw({ asset: AaveV3EthereumAssets.USDC_UNDERLYING, amount: 100_000_000, to: LC.COMET_WHALE });
    }
}
