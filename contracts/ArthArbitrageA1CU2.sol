pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT

import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";

interface ICurveSwap {
    function exchange(
        address _pool,
        address _outtoken_addr,
        address _intoken_addr,
        uint256 _amount,
        uint256 _expected
    ) external returns (uint256);
}

interface IUniswapv2Swap {
    function exchange(
        address pair, 
        uint256 swapAmount, 
        uint256 expectedOut
        ) external returns (uint256);
 }

contract ArthArbitrageA1CU2 is FlashLoanReceiverBase {

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
        
        address curve_pool;
        address curve_swap;
    
        address uniswapv2_pair;
        address uniswapv2_swap;
        address swap_asset;
        uint256 swapped_amount;
        (swap_asset, curve_pool, curve_swap, uniswapv2_pair, uniswapv2_swap) = abi.decode(_params, (address, address, address, address, address));

        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance!");
        
        emit borrowMade(_reserve, _amount , address(this).balance);

        //  Call CurveSwap
        {
            uint256 swap2_expected_out = _amount; // TODO set it with price oracle
            swapped_amount = ICurveSwap(curve_swap).exchange(
                curve_pool, 
                swap_asset, 
                _reserve, 
                _amount/*swap2_amount_in*/, 
                swap2_expected_out);
        }

        // Call UniSwap
        {   
            uint256 swap1_amount_in = swapped_amount;
            uint256 swap1_expected_out = _amount; // TODO set with price oracle including fees.        
            swapped_amount = IUniswapv2Swap(uniswapv2_swap).exchange(uniswapv2_pair, swap1_amount_in, swap1_expected_out);
        }
        // Payback
        { 
            uint totalDebt = _amount.add(_fee);
            transferFundsBackToPoolInternal(_reserve, totalDebt);
            // profit = swapped_amount - _amount
        }
    }

    /**
        Flash loan amount (18 decimals) worth of `_asset`
     */
    function arbitrage(
            address loan_asset,
            address swap_asset, 
            uint _amount, 
            address curve_pool, 
            address curve_swap, 
            address uniswap2_pair,
            address uniswap2_swap            
        ) external onlyOwner {
        bytes memory data = abi.encode(swap_asset, curve_pool, curve_swap, uniswap2_pair, uniswap2_swap);

        // Request loan
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), loan_asset, _amount, data);
    }
}
