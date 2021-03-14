pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT

import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";

interface ICurveSwap {
    function exchange(
        address _pool,
        int128 _outtoken,
        int128 _intoken,
        uint256 _amount,
        uint256 _expected
    ) external returns (uint256);
}

interface IUniswapv2Swap {
    function exchange(
        address pair, 
        address token0, 
        address token1, 
        uint256 swapAmount, 
        uint256 expectedOut
        ) external returns (uint256);
 }

contract AveLoan is FlashLoanReceiverBase {

    // Events
    event borrowMade(address _reserve, uint256 _amount , uint256 _value);
    event tradeMade(uint256 _amount);

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}

    /**
        This function is called after your contract has received the flash loaned amount
        _reserve is requested asset token address
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        
        address curve_pool; // TODO ger from _params
        address curve_swap; // TODO ger from _params
    
        address uniswapv2_pair;
        address uniswapv2_swap; // TODO ger from _params

        (curve_pool, curve_swap, uniswapv2_pair, uniswapv2_swap) = abi.decode(_params, (address, address, address, address));

        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        
        emit borrowMade(_reserve, _amount , address(this).balance);
        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //
        //emit tradeMade(token.balanceOf(address(this)));
        // Call UniSwap
        {   
            uint256 swap1_amount_in = _amount.add(1);
            uint256 swap1_expected_out = _amount.add(1);        
            IUniswapv2Swap(uniswapv2_swap).exchange(uniswapv2_pair, swap1_amount_in, swap1_expected_out);
        }
        //  Call CurveSwap
        {
            uint256 swap2_amount_in = _amount.add(1);
            uint256 swap2_expected_out = _amount.add(1);
            address crnt_asset = address(0); // TODO ger from _params
            int128 swap2_token1 = 0; // TODO get from _reserve
            int128 swap2_token2 = 0; // TODO get from _reserve
            ICurveSwap(curve_swap).exchange(curve_pool, swap2_token1, swap2_token2, swap2_amount_in, swap2_expected_out);
        }        
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan amount (18 decimals) worth of `_asset`
     */
    function flashloan(address _asset, uint _amount) public onlyOwner {
        bytes memory data = "";
        uint amount = _amount;

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }

    /**
        Flash loan amount (18 decimals) worth of `_asset`
     */
    function arbitrage(
            address loan_asset, 
            address swapped_asset,  
            uint _amount, 
            address curve_pool, 
            address curve_swap, 
            address uniswap2_pair,
            address uniswap2_swap            
        ) external onlyOwner {
        bytes memory data = abi.encode(curve_pool, curve_swap, uniswap2_pair, uniswap2_swap);

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), loan_asset, _amount, data);
    }
}
