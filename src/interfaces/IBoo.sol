// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../DataTypes.sol";

interface IBoo {
    function boo(address asset, uint256 amount, bool lockCollateral) external returns (bool);
    function updateRewards(address user) external;
    function updateRewardsContract(address newAddr) external;
    function rewards(address user) external view returns (Rewards memory);
}
