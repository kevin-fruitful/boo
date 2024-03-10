// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";

contract SetupBooEventsScript is BaseScript {
    function run() public broadcast returns (SetupBoo CONTRACT) {
        CONTRACT = new SetupBoo();

        vm.label(address(CONTRACT), "MOCK BOO");
    }
}

contract SetupBoo {
    event Boo(
        address indexed fren, address indexed asset, uint256 unscaledAmount, uint256 scaledAmount, uint256 unlockTime
    );

    constructor() {
        emit Boo(address(this), address(0), 0, 0, 0);
    }
}
