pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT

import "../Arth/IFlashLoanReceiver.sol";
//import "./aave/ILendingPoolAddressesProvider.sol";
//import "./aave/ILendingPool.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/SafeERC20.sol";

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

interface IArthLending {
  function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
}

contract ArthBorrowerMock is IFlashLoanReceiver {

    //using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Events
    event borrowMade(address _reserve, uint256 _amount , uint256 _value);
    event tradeMade(uint256 _amount);
    event Received(address caller, uint amount, string message);
    
    constructor() public {}
    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {        
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance!");   
        emit borrowMade(_reserve, _amount , address(this).balance);
        uint totalDebt = _amount.add(_fee);
        address lender;
        (lender) = abi.decode(_params, (address));

        if(_reserve == ethAddress) {
            (bool success, ) = lender.call{value: _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        } else {
            IERC20(_reserve).safeTransfer(lender, _amount);
        }     
    }    
    /**
        Flash loan amount (18 decimals) worth of `_asset`
     */
    function arbitrage(
            address lender,   
            address loan_asset,         
            uint _amount          
        ) 
        external 
        //onlyOwner 
    {
   
        bytes memory data = abi.encode(lender);
        // Request loan
        IArthLending(lender).flashLoan(address(this), loan_asset, _amount, data);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }
}
