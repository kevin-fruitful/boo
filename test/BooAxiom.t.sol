// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AxiomTest, Axiom, Query, Vm, console as c } from "@axiom-crypto/axiom-std/AxiomTest.sol";

import { Boo } from "src/Boo.sol";
import { AxiomClaimReward } from "src/AxiomClaimReward.sol";
import { LibConstants as LC } from "src/LibConstants.sol";
import "src/DataTypes.sol";

import { IPoolAddressesProvider } from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import { AaveV3Ethereum, AaveV3EthereumAssets } from "aave-address-book/AaveV3Ethereum.sol";

contract BooAxiomTest is AxiomTest {
    using Axiom for Query;
    using ResultsDecoder for bytes32[];

    struct AxiomInput {
        uint64 blockNumber;
        uint64 txIdx;
        uint64 logIdx;
    }

    AxiomClaimReward public claimReward;
    AxiomInput public input;
    bytes32 public querySchema;

    Boo public BOO;

    address constant ALICE = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function startPrank(address target) public {
        vm.startPrank(target);
    }

    function _setupBoo() internal {
        string[] memory cli = new string[](2);
        cli[0] = "just";
        cli[1] = "setup";
        vm.ffi(cli);
    }

    function _callBoo() internal {
        string[] memory cli = new string[](2);
        cli[0] = "just";
        cli[1] = "boo";
        vm.ffi(cli);
    }

    function setUp() public {
        _createSelectForkAndSetupAxiom("anvil", 19_400_000);
        _setupBoo();
        _callBoo();

        input = AxiomInput({ blockNumber: uint64(19_400_004), txIdx: 0, logIdx: 9 });
        querySchema = axiomVm.readCircuit("app/axiom/claim.circuit.ts");
        claimReward = new AxiomClaimReward(axiomV2QueryAddress, uint64(block.chainid), querySchema);

        BOO = (new Boo)(IPoolAddressesProvider(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER));
        vm.etch(address(AaveV3Ethereum.POOL), address(BOO).code);
        BOO = Boo(address(AaveV3Ethereum.POOL));

        BOO.updateRewardsContract(address(claimReward));

        vm.label(LC.COMET_WHALE, "COMET WHALE");
        vm.label(AaveV3EthereumAssets.USDC_UNDERLYING, "USDC PROXY");
        vm.label(AaveV3EthereumAssets.USDC_A_TOKEN, "ATOKEN USDC");
        vm.label(address(AaveV3Ethereum.ORACLE), "AAVE ORACLE");
        vm.label(address(AaveV3Ethereum.POOL), "AAVE POOL");
        vm.label(address(claimReward), "CLAIM REWARD");
        vm.label(ALICE, "ALICE");
    }

    function testQuery() public {
        Query memory q = query(querySchema, abi.encode(input), address(claimReward));
        q.send();
        bytes32[] memory results = q.prankFulfill();

        assertEq(results.length, 6);
        assertEq(results.toUint(0), input.blockNumber);
        assertEq(results.toAddr(1), ALICE);
        assertEq(results.toAddr(2), AaveV3EthereumAssets.USDC_UNDERLYING);

        c.log("unscaledAmount: ", results.toUint(3));
        c.log("scaledAmount: ", results.toUint(4));
        Rewards memory rewards = BOO.rewards(ALICE);
        assertEq(rewards.discountedBorrowingRates, true);
    }
}

library ResultsDecoder {
    function toAddr(bytes32[] memory results, uint256 index) internal pure returns (address) {
        return address(uint160(uint256(results[index])));
    }

    function toUint(bytes32[] memory results, uint256 index) internal pure returns (uint256) {
        return uint256(results[index]);
    }
}
