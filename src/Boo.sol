// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { LibConstants as LC } from "./LibConstants.sol";
import { Pool as PoolModified, IPoolAddressesProvider } from "./Pool.sol";
import { DataTypes } from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import { ReserveLogic } from "aave-v3-core/contracts/protocol/libraries/logic/ReserveLogic.sol";
import { AaveV3Ethereum, AaveV3EthereumAssets } from "aave-address-book/AaveV3Ethereum.sol";
import { IAToken } from "aave-v3-core/contracts/interfaces/IAToken.sol";
import { WadRayMath } from "aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol";

import { IComet } from "src/interfaces/IComet.sol";
import { ICometExt } from "src/interfaces/ICometExt.sol";

import "./DataTypes.sol";

contract Boo is PoolModified {
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;

    event Boo(
        address indexed fren, address indexed asset, uint256 unscaledAmount, uint256 scaledAmount, uint256 unlockTime
    );
    event ClaimBoo();
    event UpdatedRewards(address user, uint256 lastClaimedBlock, bool discountedBorrowingRates);
    event CollateralUnlocked();

    error BalanceLessThanLocked(address asset, uint256 locked, uint256 balance);
    error NotEnoughUnlockedAsset(address asset, uint256 amount, uint256 unlocked);
    error FundsLocked(address asset, uint256 unlockedAmount, uint256 lockedAmount, uint256 unlockDate);
    error NotRewardContract(address caller, address rewardContract);

    mapping(address user => mapping(address asset => LockedCollateral)) internal _lockedCollateral;

    address public rewardContract;
    mapping(address user => Rewards rewardsInfo) internal _rewards;

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider provider) PoolModified(provider) { }

    // todo only allow pool admin to update
    function updateRewardsContract(address newAddr) external {
        rewardContract = newAddr;
    }

    /// @dev Transfer collateral from a competitor to Aave.
    function boo(address asset, uint256 amount, bool lockCollateral) external virtual returns (bool) {
        // First, we need to allow Comet to transfer the asset from the user to the pool
        // todo do this here so the user doesn't need to call this function separately
        // ICometExt(LC.COMET_USDC).allow(msg.sender, true);

        IComet(LC.COMET_USDC).withdrawFrom({ src: msg.sender, to: msg.sender, asset: asset, amount: amount });

        // For now, get the scaled deposit amount by subtracting the scaled balance before and after the deposit,
        // but we should enshrine this logic into the AToken contract or the Boo contract instead
        uint256 scaledBalanceBefore = IAToken(AaveV3EthereumAssets.USDC_A_TOKEN).scaledBalanceOf(msg.sender);
        supply({ asset: asset, amount: amount, onBehalfOf: msg.sender, referralCode: 0 });
        uint256 scaledBalanceAfter = IAToken(AaveV3EthereumAssets.USDC_A_TOKEN).scaledBalanceOf(msg.sender);

        if (lockCollateral) {
            _lockedCollateral[msg.sender][asset].amount += scaledBalanceAfter - scaledBalanceBefore;
            _lockedCollateral[msg.sender][asset].unlockDate = block.timestamp + 26 weeks;
        }

        emit Boo(msg.sender, asset, amount, scaledBalanceAfter - scaledBalanceBefore, block.timestamp + 26 weeks);

        return true;
    }

    function updateRewards(address user) external {
        if (msg.sender != rewardContract) {
            revert NotRewardContract(msg.sender, rewardContract);
        }
        require(msg.sender == rewardContract, "only reward contract can call this");
        require(rewardContract != address(0), "reward contract not set");

        _rewards[user].lastClaimedBlock = block.number;
        _rewards[user].discountedBorrowingRates = true;

        emit UpdatedRewards({ user: user, lastClaimedBlock: block.number, discountedBorrowingRates: true });
    }

    function claim(address asset) external virtual returns (bool) {
        LockedCollateral memory lc = _lockedCollateral[msg.sender][asset];

        if (lc.amount > 0 && lc.unlockDate < block.timestamp) {
            _lockedCollateral[msg.sender][asset] = LockedCollateral(0, 0);

            _rewards[msg.sender].lastClaimedBlock = block.number;
            _rewards[msg.sender].discountedBorrowingRates = true;

            emit ClaimBoo();
            return true;
        }

        return false;
    }

    function withdraw(address asset, uint256 amount, address to) public virtual override returns (uint256) {
        LockedCollateral memory lc = _lockedCollateral[msg.sender][asset];
        if (lc.unlockDate == 0) {
            return super.withdraw(asset, amount, to);
        }

        uint256 scaledBalanceBefore = IAToken(AaveV3EthereumAssets.USDC_A_TOKEN).scaledBalanceOf(msg.sender);
        DataTypes.ReserveCache memory reserveCache = _reserves[asset].cache();

        uint256 scaledAmountToWithdraw = amount.rayDiv(reserveCache.nextLiquidityIndex);

        uint256 scaledUnlockedBalance = scaledBalanceBefore - lc.amount;
        if (scaledBalanceBefore < lc.amount) {
            revert BalanceLessThanLocked(asset, lc.amount, scaledBalanceBefore);
        }
        if (scaledUnlockedBalance < scaledAmountToWithdraw) {
            revert NotEnoughUnlockedAsset(asset, amount, scaledBalanceBefore - lc.amount);
        }

        if (scaledUnlockedBalance >= scaledAmountToWithdraw && block.timestamp > lc.unlockDate) {
            revert FundsLocked(asset, scaledUnlockedBalance, lc.amount, lc.unlockDate);
        }

        if (lc.unlockDate < block.timestamp) {
            _lockedCollateral[msg.sender][asset] = LockedCollateral(0, 0);
        }

        return super.withdraw(asset, amount, to);
    }

    function rewards(address user) external view returns (Rewards memory) {
        return _rewards[user];
    }
}
