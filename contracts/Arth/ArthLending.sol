pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/SafeERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/math/SafeMath.sol";
import "./IFlashLoanReceiver.sol";
import "./Initializable.sol";

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

contract ArthLending is ReentrancyGuard, Initializable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    /**
    * @dev emitted when a flashloan is executed
    * @param _target the address of the flashLoanReceiver
    * @param _reserve the address of the reserve
    * @param _amount the amount requested
    * @param _totalFee the total fee on the amount
    * @param _protocolFee the part of the fee for the protocol
    * @param _timestamp the timestamp of the action
    **/
    event FlashLoan(
        address indexed _target,
        address indexed _reserve,
        uint256 _amount,
        uint256 _totalFee,
        uint256 _protocolFee,
        uint256 _timestamp
    );

    /**
    * @dev emitted on deposit
    * @param _reserve the address of the reserve
    * @param _user the address of the user
    * @param _amount the amount to be deposited
    * @param _referral the referral number of the action
    * @param _timestamp the timestamp of the action
    **/
    event Deposit(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint16 indexed _referral,
        uint256 _timestamp
    );

    /**
    * @dev emitted during a redeem action.
    * @param _reserve the address of the reserve
    * @param _user the address of the user
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event Withdraw(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    

    address public lendingAddress;
    uint256 totalFeeBips;           // Bip is 1/10000. 35 0.35% is 
    
    // Disable protocol fee
    //uint256 protocolFeeBips;        // portion of totalFeeBips. 3000 is 30%
    uint256 private constant FLASHLOAN_FEE_PROTOCOL = 0; //3000;
    
    /**
    * @dev only lender can use functions affected by this modifier
    **/
    modifier onlyLender {
        require(lendingAddress == msg.sender, "The caller must be a lending pool contract");
        _;
    }

    /**
    * @dev functions affected by this modifier can only be invoked if the provided _amount input parameter
    * is not zero.
    * @param _amount the amount provided
    **/
    modifier onlyAmountGreaterThanZero(uint256 _amount) {
        requireAmountGreaterThanZeroInternal(_amount);
        _;
    }

    /**
    * @dev initializes the Core contract, invoked upon registration on the AddressesProvider
    * @param _lendingAddress the lender's address
    * @param _totalFeeBips in 1/10000 units. 35 is 0.35%
    **/

    function initialize(address _lendingAddress, uint256 _totalFeeBips) public initializer {
        require(lendingAddress == address(0)); // TODO remove
        lendingAddress = _lendingAddress;
        totalFeeBips = _totalFeeBips;
    }

    /**
    * @dev allows smartcontracts to access the liquidity of the pool within one transaction,
    * as long as the amount taken plus a fee is returned. NOTE There are security concerns for developers of flashloan receiver contracts
    * that must be kept into consideration. For further details please visit https://developers.aave.com
    * @param _receiver The address of the contract receiving the funds. The receiver should implement the IFlashLoanReceiver interface.
    * @param _reserve the address of the principal reserve
    * @param _amount the amount requested for this flashloan
    **/        
    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes memory _params)
        public
        payable 
        nonReentrant
        onlyAmountGreaterThanZero(_amount)
    {
        //check that the reserve has enough available liquidity
        //we avoid using the getAvailableLiquidity() function in LendingPoolCore to save gas
        uint256 availableLiquidityBefore = _reserve == EthAddressLib.ethAddress()
            ? address(this).balance
            : IERC20(_reserve).balanceOf(address(this));

        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        //calculate amount fee
        uint256 amountFee = _amount.mul(totalFeeBips).div(10000);

        //get the FlashLoanReceiver instance
        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);

        address payable userPayable = address(uint160(_receiver));

        //transfer funds to the receiver

        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(userPayable, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = userPayable.call.value(_amount).gas(50000)("");
            require(result, "Transfer of ETH failed");
        }
        //execute action of the receiver
        receiver.executeOperation(_reserve, _amount, amountFee, _params);

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = _reserve == EthAddressLib.ethAddress()
            ? address(this).balance
            : IERC20(_reserve).balanceOf(address(this));

        require(
            availableLiquidityAfter == availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );

        //solium-disable-next-line
        emit FlashLoan(_receiver, _reserve, _amount, amountFee, 0, block.timestamp);
    }

    /**
    * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
    **/
    function requireAmountGreaterThanZeroInternal(uint256 _amount) internal pure {
        require(_amount > 0, "Amount must be greater than 0");
    }    

    /**
    * @dev transfers to the user a specific amount from the reserve.
    * @param _reserve the address of the reserve where the transfer is happening
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _reserve, address payable _user, uint256 _amount)
        internal //external
        // onlyLendingPool
    {
        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(_user, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = _user.call{value: _amount, gas: 100000}("");
            require(result, "Transfer of ETH failed");
        }
    }    

    /**
    * @dev gets the available liquidity in the reserve. The available liquidity is the balance of the core contract
    * @param _reserve the reserve address
    * @return the available liquidity
    **/
    function getReserveAvailableLiquidity(address _reserve) public view returns (uint256) {
        uint256 balance = 0;

        if (_reserve == EthAddressLib.ethAddress()) {
            balance = address(this).balance;
        } else {
            balance = IERC20(_reserve).balanceOf(address(this));
        }
        return balance;
    }    

    /**
    * @dev transfers an amount from a user to the destination reserve
    * @param _reserve the address of the reserve where the amount is being transferred
    * @param _user the address of the user from where the transfer is happening
    * @param _amount the amount being transferred
    **/
    /*
    function transferToReserve(address _reserve, address payable _user, uint256 _amount)
        payable
        public
        //external
        //onlyLendingPool
    {
        if (_reserve != EthAddressLib.ethAddress()) {
            require(msg.value == 0, "User is sending ETH along with the ERC20 transfer.");
            ERC20(_reserve).safeTransferFrom(_user, address(this), _amount);

        } else {
            require(msg.value >= _amount, "The amount and the value sent to deposit do not match");

            if (msg.value > _amount) {
                //send back excess ETH
                uint256 excessAmount = msg.value.sub(_amount);
                //solium-disable-next-line
                (bool result, ) = _user.call.value(excessAmount).gas(50000)("");
                require(result, "Transfer of ETH failed");
            }
        }
    }    
    */
    /**
    * @dev deposits The underlying asset into the reserve. A corresponding amount of the overlying asset (aTokens)
    * is minted.
    * @param _reserve the address of the reserve
    * @param _amount the amount to be deposited
    * @param _referralCode integrators are assigned a referral code and can potentially receive rewards.
    **/
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode)
        external
        payable
        onlyLender        
        nonReentrant
        //onlyActiveReserve(_reserve)
        //onlyUnfreezedReserve(_reserve)
        onlyAmountGreaterThanZero(_amount)
    {
        //AToken aToken = AToken(core.getReserveATokenAddress(_reserve));

        //bool isFirstDeposit = aToken.balanceOf(msg.sender) == 0;

        //core.updateStateOnDeposit(_reserve, msg.sender, _amount, isFirstDeposit);

        //minting AToken to user 1:1 with the specific exchange rate
        //aToken.mintOnDeposit(msg.sender, _amount);

        //transfer to the core contract
        //core.transferToReserve.value(msg.value)(_reserve, msg.sender, _amount);
        // transferToReserve.value(msg.value)(_reserve, msg.sender, _amount);

        if (_reserve != EthAddressLib.ethAddress()) {
            require(msg.value == 0, "User is sending ETH along with the ERC20 transfer.");
            ERC20(_reserve).safeTransferFrom(msg.sender, address(this), _amount);

        } else {
            require(msg.value >= _amount, "The amount and the value sent to deposit do not match");

            if (msg.value > _amount) {
                //send back excess ETH
                uint256 excessAmount = msg.value.sub(_amount);
                //solium-disable-next-line
                (bool result, ) = msg.sender.call.value(excessAmount).gas(50000)("");
                require(result, "Transfer of ETH failed");
            }
        }
        //solium-disable-next-line
        emit Deposit(_reserve, msg.sender, _amount, _referralCode, block.timestamp);

    }    

    /**
    * @dev Redeems the underlying amount of assets requested by _user.
    * This function is executed by the overlying aToken contract in response to a redeem action.
    * @param _reserve the address of the reserve
    * @param _amount the underlying amount to be redeemed
    **/
    function withdraw(
        address _reserve,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    )
        external
        onlyLender        
        nonReentrant
        //onlyOverlyingAToken(_reserve)
        //onlyActiveReserve(_reserve)
        onlyAmountGreaterThanZero(_amount)
    {
        //uint256 currentAvailableLiquidity = core.getReserveAvailableLiquidity(_reserve);
        uint256 currentAvailableLiquidity = getReserveAvailableLiquidity(_reserve);
        require(
            currentAvailableLiquidity >= _amount,
            "There is not enough liquidity available to withdraw"
        );

        //core.updateStateOnRedeem(_reserve, _user, _amount, _aTokenBalanceAfterRedeem == 0);

        //core.transferToUser(_reserve, _user, _amount);
        transferToUser(_reserve, msg.sender, _amount);

        //solium-disable-next-line
        emit Withdraw(_reserve, msg.sender, _amount, block.timestamp);
    }    


    fallback() external payable {
        //only contracts can send ETH to the core
        //require(msg.sender.isContract(), "Only contracts can send ether to the Lending pool core");

    }

}