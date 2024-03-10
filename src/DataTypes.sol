// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct LockedCollateral {
    uint256 amount;
    uint256 unlockDate;
}

struct Rewards {
    uint256 lastClaimedBlock; // The last time the user claimed rewards.
    uint256 rewards;
    bool discountedBorrowingRates;
}
