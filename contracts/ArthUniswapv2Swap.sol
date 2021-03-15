pragma solidity ^0.6.6;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/IERC20.sol";
import './uniswap-v2/IUniswapV2Pair.sol';

contract ArthUniswapv2Swap {

    constructor() public {
    }
    

    function exchange(address pair, uint256 swapAmount, uint256 expectedOut) external returns (uint256) {
        bytes memory data = "";
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token0();
        IERC20(token0).transfer(pair, swapAmount);
        IUniswapV2Pair(pair).swap(swapAmount, expectedOut, msg.sender, data);
        IERC20(token1).balanceOf(msg.sender);
    }
}
