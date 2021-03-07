pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT

import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";

contract Spica is FlashLoanReceiverBase {

    // Events
    event borrowMade(address _reserve, uint256 _amount , uint256 _value);
    event tradeMade(uint256 _amount);

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}

    /**
        This function is called after your contract has received the flash loaned amount
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
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        
        emit borrowMade(_reserve, _amount , address(this).balance);
        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //
        //emit tradeMade(token.balanceOf(address(this)));
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset) public onlyOwner {
        bytes memory data = "";
        uint amount = 1000000000000000000;

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }


    /*
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee) external returns(uint256 returnedAmount) {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        //emit borrowMade(_reserve, _amount , address(this).balance);

        // NEED TO APPROVE Token
        ERC20 token = ERC20(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);

        emit borrowMade(_reserve, _amount , token.balanceOf(address(this)));

        // Approve exchange to take tokens for token -> Eth trade
        token.approve(0xB4ca10f43caF503b7Aa0a77757B99c78212D6b92, _amount);
        // Exchange for token -> eth
        UniswapExchange followerUniSwapExchange = UniswapExchange(0xB4ca10f43caF503b7Aa0a77757B99c78212D6b92);

        uint256 DEADLINE = block.timestamp + 300;
        // Swap token -> Eth
        uint256 eth_bought = followerUniSwapExchange.tokenToEthSwapInput(_amount, 0, DEADLINE);
        // Exchange for Eth -> token
        UniswapExchange leaderUniSwapExchange = UniswapExchange(0x274bBBBd9bf7Cab50fC8F62F5bb61d4FF297b362);
        // Swap Eth -> Token
        uint256 token_bought = leaderUniSwapExchange.ethToTokenSwapInput.value(eth_bought)(_amount, DEADLINE);

        emit tradeMade(token.balanceOf(address(this)));
        // Pays back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
        return _amount.add(_fee);
    }
    */
}
