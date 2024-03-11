// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AxiomV2Client } from "@axiom-crypto/v2-periphery/client/AxiomV2Client.sol";
import { IAToken } from "aave-v3-core/contracts/interfaces/IAToken.sol";
import { AaveV3Ethereum, AaveV3EthereumAssets } from "aave-address-book/AaveV3Ethereum.sol";

import "./interfaces/IBoo.sol";

import "./DataTypes.sol";

contract AxiomClaimReward is AxiomV2Client {
    error NotEligibleForRewards(uint256 blocks, uint256 blocksInInterval);
    error BalanceHasNotIncreased(uint256 originalScaledBalance, uint256 currentScaledBalance);
    error NotEnoughBlocksHavePassed(uint256 targetBlock, uint256 currentBlock);
    error IneligibleBlock();
    error InvalidAsset(address expectedAsset, address actualAsset);

    event AxiomCallback(uint256 currentScaledBalance, uint256 scaledAmount);

    IBoo internal BOO = IBoo(address(AaveV3Ethereum.POOL));
    IAToken internal AUSDC = IAToken(AaveV3EthereumAssets.USDC_A_TOKEN);

    /// @dev When rewards can start to be claimed.
    uint256 public immutable MIN_BLOCK_NUMBER;

    /// @dev The interval at which rewards can be claimed.
    uint256 internal constant REWARD_INTERVAL_BLOCKS = 216_000; // 30 days with 12 second blocks

    /// @dev The unique identifier of the circuit accepted by this contract.
    bytes32 public immutable QUERY_SCHEMA;

    /// @dev The chain ID of the chain whose data the callback is expected to be called from.
    uint64 public immutable SOURCE_CHAIN_ID;

    /// @param  _axiomV2QueryAddress The address of the AxiomV2Query contract.
    /// @param  _callbackSourceChainId The ID of the chain the query reads from.
    constructor(address _axiomV2QueryAddress, uint64 _callbackSourceChainId, bytes32 _querySchema)
        AxiomV2Client(_axiomV2QueryAddress)
    {
        MIN_BLOCK_NUMBER = block.number;
        QUERY_SCHEMA = _querySchema;
        SOURCE_CHAIN_ID = _callbackSourceChainId;
    }

    /// @inheritdoc AxiomV2Client
    function _axiomV2Callback(
        uint64, // sourceChainId,
        address, // caller,
        bytes32, // querySchema,
        uint256, // queryId,
        bytes32[] calldata axiomResults,
        bytes calldata // extraData
    ) internal override {
        // The callback from the Axiom ZK circuit proof comes out here and we can handle the results from the
        // `axiomResults` array. Values should be converted into their original types to be used properly.
        uint256 blockNumber = uint256(axiomResults[0]);
        address user = address(uint160(uint256(axiomResults[1])));
        address asset = address(uint160(uint256(axiomResults[2])));
        uint256 unscaledAmount = uint256(axiomResults[3]);
        uint256 scaledAmount = uint256(axiomResults[4]);

        if (blockNumber < MIN_BLOCK_NUMBER) {
            revert IneligibleBlock();
        }

        if (asset != AaveV3EthereumAssets.USDC_UNDERLYING) {
            revert InvalidAsset(AaveV3EthereumAssets.USDC_UNDERLYING, asset);
        }

        // Eligible for rewards if:
        // Current scaled balance is greater than the amount the user transferred from the competing protocol.
        uint256 currentScaledBalance = AUSDC.scaledBalanceOf(user);

        // The user's balance in Aave has increased by at least the amount they transferred from the competing protocol.
        if (currentScaledBalance < scaledAmount) {
            revert BalanceHasNotIncreased(scaledAmount, currentScaledBalance);
        }

        // 30 days have passed
        if (blockNumber + REWARD_INTERVAL_BLOCKS < block.number) {
            revert NotEnoughBlocksHavePassed(blockNumber + REWARD_INTERVAL_BLOCKS, block.number);
        }

        // 30 days have passed since the last claim. todo fix
        if (blockNumber - BOO.rewards(user).lastClaimedBlock < REWARD_INTERVAL_BLOCKS) {
            revert NotEligibleForRewards(blockNumber - BOO.rewards(user).lastClaimedBlock, REWARD_INTERVAL_BLOCKS);
        }

        BOO.updateRewards({ user: user });
    }

    /// @inheritdoc AxiomV2Client
    function _validateAxiomV2Call(
        AxiomCallbackType, // callbackType,
        uint64 sourceChainId,
        address, // caller,
        bytes32 querySchema,
        uint256, // queryId,
        bytes calldata // extraData
    ) internal view override {
        // Add your validation logic here for checking the callback responses
        require(sourceChainId == SOURCE_CHAIN_ID, "Source chain ID does not match");
        require(querySchema == QUERY_SCHEMA, "Invalid query schema");
    }
}
