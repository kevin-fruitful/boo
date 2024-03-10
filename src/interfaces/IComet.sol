// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IComet {
    function supply(address asset, uint256 amount) external;
    function withdrawFrom(address src, address to, address asset, uint256 amount) external;
}
