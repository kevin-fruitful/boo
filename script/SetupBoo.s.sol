// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { console as c } from "forge-std/Test.sol";
import { BaseScript } from "./Base.s.sol";

import { Boo } from "src/Boo.sol";
import { LibConstants as LC } from "src/LibConstants.sol";

import { IPoolAddressesProvider } from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import { AaveV3Ethereum, AaveV3EthereumAssets } from "aave-address-book/AaveV3Ethereum.sol";

import { ICometExt } from "src/interfaces/ICometExt.sol";
import { IComet } from "src/interfaces/IComet.sol";

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SetupBooScript is BaseScript {
    Boo public BOO;
    IComet public COMET = IComet(LC.COMET_USDC);
    IERC20 public USDC = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING);

    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2 router address
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Wrapped ETH address
    address private constant USDC_ADDRESS = AaveV3EthereumAssets.USDC_UNDERLYING; // USDC token address on Ethereum mainnet

    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    function swapEthForUsdc(uint256 amountOutMin, uint256 deadline) public payable {
        address[] memory path = new address[](2);
        path[0] = WETH_ADDRESS;
        path[1] = USDC_ADDRESS;

        uniswapRouter.swapExactETHForTokens{ value: 10 ether }(
            amountOutMin,
            path,
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // or another address if you wish to send the USDC to a different address
            deadline
        );
    }

    function run() public broadcast {
        swapEthForUsdc(1e10, block.timestamp + 300);
        USDC.approve(address(COMET), 1000 ether);
        USDC.approve(address(AaveV3Ethereum.POOL), 1000 ether);
        COMET.supply(USDC_ADDRESS, 1e9);
        BOO = (new Boo)(IPoolAddressesProvider(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER));

        string memory poolAddr = vm.toString(address(AaveV3Ethereum.POOL));
        string memory params =
            string.concat("[", '"', poolAddr, '"', ", ", '"', vm.toString(address(BOO).code), '"', "]");

        vm.rpc("anvil_setCode", params);
        BOO = Boo(address(AaveV3Ethereum.POOL));

        ICometExt(LC.COMET_USDC).allow(address(AaveV3Ethereum.POOL), true);
        c.log("Block number before calling BOO.boo() is ~~ %s ~~", block.number);
        // BOO.boo(AaveV3EthereumAssets.USDC_UNDERLYING, 100_000_000, false);
    }
}
