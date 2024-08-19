//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

pragma abicoder v2;

import "hardhat/console.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface ICurveFi_Exchange {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
}

contract LiquidityManagementArbitrum is IUniswapV3SwapCallback {
    //IUniswapV3Pool public constant poolFirst  = IUniswapV3Pool(0xc0a29BC07DdD7Fb67DbEf0De4F1481f0469be9dD);

    address constant poolAddress_weth_usdc_500 = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
    //token 0 = weth
    //token 1 = usdc

    address constant poolAddress_weth_usdt_500 = 0x641C00A822e8b671738d32a431a4Fb6074E5c79d;
    //token 0 = weth
    //token 1 = usdt

    address constant poolAddress_weth_usdc_3000 = 0x17c14D2c404D167802b16C450d3c99F88F2c4F4d;
    //token 0 = weth
    //token 1 = usdc

    address constant poolAddress_weth_usdt_3000 = 0xc82819F72A9e77E2c0c3A69B3196478f44303cf4;
    //token 0 = weth
    //token 1 = usdt

    address constant poolAddress_sushi = 0x905dfCD5649217c42684f23958568e533C711Aa3;

    address constant curveTriUsdtUsdcDaiAddress = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;

    uint256 constant mult1 = 10 ** 29;
    uint256 constant mult2 = 10 ** 19;
    uint256 constant mult3 = 10 ** 9;
    uint256 constant mult4 = 10 ** 8;
    uint256 constant mult5 = 10 ** 7;
    uint256 constant mult6 = 10 ** 6;
    uint256 constant mult7 = 10 ** 4;
    uint256 constant mult8 = 10 ** 2;

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    bool constant zeroForOne_constant = true;
    int256 constant amountToSend_constant = -100;

    constructor() {}

    struct SwapCallbackData {
        address payer;
        address token0;
        address token1;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        require(amount0Delta > 0 || amount1Delta > 0 || amount0Delta < 0 || amount1Delta < 0, "NoZero"); // swaps entirely within 0-liquidity regions are not supported
        require(
            msg.sender == poolAddress_weth_usdc_500 || msg.sender == poolAddress_weth_usdt_500
                || msg.sender == poolAddress_weth_usdc_3000 || msg.sender == poolAddress_weth_usdt_3000,
            "bdsend"
        );
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        if (amount0Delta > 0) {
            TransferHelper.safeTransferFrom(data.token0, data.payer, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            TransferHelper.safeTransferFrom(data.token1, data.payer, msg.sender, uint256(amount1Delta));
        }
    }

    //Start SushiSwap portion

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ff-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ff-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ffss-math-mul-overflow");
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "ze9w8");
        require(reserveIn > 0 && reserveOut > 0, "z9383");
        uint256 amountInWithFee = mul(amountIn, 997);
        uint256 numerator = mul(amountInWithFee, reserveOut);
        uint256 denominator = add(mul(reserveIn, 1000), amountInWithFee);

        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "z2312");
        require(reserveIn > 0 && reserveOut > 0, "zpoijh");
        uint256 numerator = mul(mul(reserveIn, amountOut), 1000);
        uint256 denominator = mul(sub(reserveOut, amountOut), 997);
        amountIn = add(numerator / denominator, 1);
    }

    function ETH_USDC_Swap_Sushi(uint256 quant, bool side) public {
        IUniswapV2Pair pairV2 = IUniswapV2Pair(poolAddress_sushi);

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pairV2.getReserves();

        uint256 amountIn = side ? getAmountIn(quant, reserve1, reserve0) : quant;
        uint256 amountOut = side ? quant : getAmountOut(quant, reserve0, reserve1);
        address tokenToTransfer = side ? USDC : WETH;

        TransferHelper.safeTransferFrom(tokenToTransfer, msg.sender, poolAddress_sushi, amountIn);

        if (side) {
            pairV2.swap(amountOut, uint256(0), msg.sender, new bytes(0));
        } else {
            pairV2.swap(uint256(0), amountOut, msg.sender, new bytes(0));
        }
    }

    //End sushiSwap portion

    //Start Curve portion swap UDSC for USD
    function tradeCurve(uint256 quant, bool side) public {
        (int128 i, int128 j) = side ? (1, 0) : (0, 1);
        uint256 dx = quant;
        uint256 min_dy = 0;
        uint256 amount_received = ICurveFi_Exchange(curveTriUsdtUsdcDaiAddress).exchange(i, j, dx, min_dy);
    }

    //End Curve Portion

    function ETH_USDC_Swap_500(int128 amount0, bool isbuyToken0) public {
        require(amount0 > 0, "negAmt1");
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress_weth_usdc_500);
        uint160 sqrtPriceLimitX96;

        if (isbuyToken0) {
            amount0 = amount0 * -1;
            sqrtPriceLimitX96 = 1461446703485210103287273052203988822378723970341;
        } else {
            sqrtPriceLimitX96 = 4295128740;
        }

        bool zeroForOne = !isbuyToken0;

        SwapCallbackData memory data;
        data.payer = msg.sender;
        data.token0 = WETH;
        data.token1 = USDC;

        pool.swap(msg.sender, zeroForOne, amount0, sqrtPriceLimitX96, abi.encode(data));
    }

    function ETH_USDT_Swap_500(int128 amount0, bool isbuyToken0) public {
        require(amount0 > 0, "negAmt1");
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress_weth_usdt_500);
        uint160 sqrtPriceLimitX96;

        if (isbuyToken0) {
            amount0 = amount0 * -1;
            sqrtPriceLimitX96 = 1461446703485210103287273052203988822378723970341;
        } else {
            sqrtPriceLimitX96 = 4295128740;
        }

        bool zeroForOne = !isbuyToken0;

        SwapCallbackData memory data;
        data.payer = msg.sender;
        data.token0 = WETH;
        data.token1 = USDT;

        pool.swap(msg.sender, zeroForOne, amount0, sqrtPriceLimitX96, abi.encode(data));
    }

    function ETH_USDC_Swap_3000(int128 amount0, bool isbuyToken0) public {
        require(amount0 > 0, "negAmt1");
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress_weth_usdc_3000);
        uint160 sqrtPriceLimitX96;

        if (isbuyToken0) {
            amount0 = amount0 * -1;
            sqrtPriceLimitX96 = 1461446703485210103287273052203988822378723970341;
        } else {
            sqrtPriceLimitX96 = 4295128740;
        }

        bool zeroForOne = !isbuyToken0;

        SwapCallbackData memory data;
        data.payer = msg.sender;
        data.token0 = WETH;
        data.token1 = USDC;

        pool.swap(msg.sender, zeroForOne, amount0, sqrtPriceLimitX96, abi.encode(data));
    }

    function ETH_USDT_Swap_3000(int128 amount0, bool isbuyToken0) public {
        require(amount0 > 0, "negAmt1");
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress_weth_usdt_3000);
        uint160 sqrtPriceLimitX96;

        if (isbuyToken0) {
            amount0 = amount0 * -1;
            sqrtPriceLimitX96 = 1461446703485210103287273052203988822378723970341;
        } else {
            sqrtPriceLimitX96 = 4295128740;
        }

        bool zeroForOne = !isbuyToken0;

        SwapCallbackData memory data;
        data.payer = msg.sender;
        data.token0 = WETH;
        data.token1 = USDT;

        pool.swap(msg.sender, zeroForOne, amount0, sqrtPriceLimitX96, abi.encode(data));
    }

    // arb numbers
    // 0 = eth_usdc_500  eth_usdc_3000
    // 1 = eth_usdc_3000  eth_usdc_500
    function arb(uint16 arbNum, int128 amount0) public {
        require(amount0 > 0, "negAmt1");

        uint16 pool0 = arbNum / 1000;
        uint16 arbNum2 = arbNum - pool0 * 1000;
        uint16 pool1 = arbNum2 / 10;
        uint16 isbuydec = arbNum2 - pool1 * 10;
        bool isbuy = isbuydec == 1;

        if (pool0 == 0) {
            ETH_USDC_Swap_500(amount0, isbuy);
        } else if (pool0 == 1) {
            ETH_USDC_Swap_3000(amount0, isbuy);
        } else if (pool0 == 2) {
            ETH_USDT_Swap_500(amount0, isbuy);
        } else if (pool0 == 3) {
            ETH_USDT_Swap_3000(amount0, isbuy);
        }

        if (pool1 == 0) {
            ETH_USDC_Swap_500(amount0, !isbuy);
        } else if (pool1 == 1) {
            ETH_USDC_Swap_3000(amount0, !isbuy);
        } else if (pool1 == 2) {
            ETH_USDT_Swap_500(amount0, !isbuy);
        } else if (pool1 == 3) {
            ETH_USDT_Swap_3000(amount0, !isbuy);
        }
    }

    function arb2(uint32 arbNum, int128 amount0, int128 amount1) public {
        require(amount0 > 0, "negAmt1");

        uint32 pool0 = arbNum / 10000;
        uint32 arbNum2 = arbNum - pool0 * 10000;
        uint32 pool1 = arbNum2 / 100;
        uint32 arbNum3 = arbNum2 - pool1 * 100;
        uint32 isBuyDecFirst = arbNum3 / 10;
        uint32 isBuyDecSecond = arbNum3 - isBuyDecFirst * 10;
        bool isbuy0 = isBuyDecFirst == 1;
        bool isbuy1 = isBuyDecSecond == 1;

        if (pool0 == 0) {
            ETH_USDC_Swap_500(amount0, isbuy0);
        } else if (pool0 == 1) {
            ETH_USDC_Swap_3000(amount0, isbuy0);
        } else if (pool0 == 2) {
            ETH_USDT_Swap_500(amount0, isbuy0);
        } else if (pool0 == 3) {
            ETH_USDT_Swap_3000(amount0, isbuy0);
        }

        if (pool1 == 0) {
            ETH_USDC_Swap_500(amount1, isbuy1);
        } else if (pool1 == 1) {
            ETH_USDC_Swap_3000(amount1, isbuy1);
        } else if (pool1 == 2) {
            ETH_USDT_Swap_500(amount1, isbuy1);
        } else if (pool1 == 3) {
            ETH_USDT_Swap_3000(amount1, isbuy1);
        }
    }

    function triPool(uint256 x) public {
        uint256[3] memory poolNums;
        uint256[3] memory isbuys;
        uint256[3] memory poolAmts;

        poolAmts[2] = x / mult1;
        x -= poolAmts[2] * mult1;
        poolAmts[1] = x / mult2;
        x -= poolAmts[1] * mult2;
        poolAmts[0] = x / mult3;
        x -= poolAmts[0] * mult3;

        isbuys[2] = x / mult4;
        x -= isbuys[2] * mult4;
        isbuys[1] = x / mult5;
        x -= isbuys[1] * mult5;
        isbuys[0] = x / mult6;
        x -= isbuys[0] * mult6;

        poolNums[2] = x / mult7;
        x -= poolNums[2] * mult7;
        poolNums[1] = x / mult8;
        x -= poolNums[1] * mult8;
        poolNums[0] = x;

        for (uint256 i = 0; i < 3; i++) {
            poolAmts[i] *= 10 ** 14;
            if (poolNums[i] == 1) {
                ETH_USDC_Swap_500(int128(poolAmts[i]), isbuys[i] == 1);
            } else if (poolNums[i] == 2) {
                ETH_USDC_Swap_3000(int128(poolAmts[i]), isbuys[i] == 1);
            } else if (poolNums[i] == 3) {
                ETH_USDT_Swap_500(int128(poolAmts[i]), isbuys[i] == 1);
            } else if (poolNums[i] == 4) {
                ETH_USDT_Swap_3000(int128(poolAmts[i]), isbuys[i] == 1);
            } else if (poolNums[i] == 5) {
                ETH_USDC_Swap_Sushi(poolAmts[i], isbuys[i] == 1);
            } else if (poolNums[i] == 6) {
                poolAmts[i] /= 10 ** 12;
                tradeCurve(poolAmts[i], isbuys[i] == 1);
            }
        }
    }
}