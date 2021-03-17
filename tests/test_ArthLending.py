import brownie
from brownie import Wei
from brownie import accounts, ArthLending, ArthBorrowerMock
import pytest
from brownie.test import strategy
import hypothesis

@pytest.fixture
def arthLending():
    return accounts[0].deploy(ArthLending)

def test_initialize(arthLending, accounts):
    arthLending.initialize(accounts[0], 35, {'from': accounts[0]})
    assert arthLending.lendingAddress() == accounts[0]

    asset = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    amount = 100
    arthLending.deposit(asset, amount, 1, {'from': accounts[0], 'value': amount})

    assert arthLending.balance() == amount

    arthLending.withdraw(asset, amount, 1, {'from': accounts[0]})

    assert arthLending.balance() == 0

class StateMachine:

    value = strategy('uint256', max_value = Wei("10 ether"))
    #address = strategy('address')
    asset = hypothesis.strategies.sampled_from(["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"])

    def __init__(cls, accounts, arthLending, arthBorrowerMock):
        # deploy the contract at the start of the test
        cls.accounts = accounts
        cls.arthLending = arthLending
        cls.arthBorrowerMock = arthBorrowerMock

    def setup(self):
        # zero the deposit amounts at the start of each test run
        self.deposits = {i: 0 for i in self.accounts}
    """
    def rule_deposit(self, value, asset):
        #asset = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

        if value > 0:
            self.arthLending.deposit(asset, value, 1, {'from': self.accounts[0], 'value': value})
            self.deposits[self.accounts[0]] += value
            assert self.arthLending.balance() >= 0
        else:
            # attempting to send <= 0 amount
            with brownie.reverts("Amount must be greater than 0"):
                self.arthLending.deposit(asset, value, 1, {'from': self.accounts[0], 'value': value})

    def rule_withdraw(self, value):
        asset = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        if value > 0:
            if(self.arthLending.balance() >= value):
                self.arthLending.withdraw(asset, value, 1, {'from': self.accounts[0]})
            else:
                with brownie.reverts("There is not enough liquidity available to withdraw"):
                    self.arthLending.withdraw(asset, value, 1, {'from': self.accounts[0]})
        else:
            # attempting to withdraw <= 0 amount
            with brownie.reverts("Amount must be greater than 0"):
                self.arthLending.withdraw(asset, value, 1, {'from': self.accounts[0]})
    """
    def rule_flashLoan(self, value, asset):
        if value > 0:
            if(self.arthLending.balance() >= value): 
                self.arthBorrowerMock.arbitrage(self.arthLending, asset, value, {'from': self.accounts[1]})
            else:
                with brownie.reverts("There is not enough liquidity available to borrow"):
                    self.arthBorrowerMock.arbitrage(self.arthLending, asset, value, {'from': self.accounts[1]})
        else:
            with brownie.reverts("Amount must be greater than 0"):
                self.arthBorrowerMock.arbitrage(self.arthLending, asset, value, {'from': self.accounts[1]})

    def invariant(self):
        pass

def test_stateful(ArthLending, accounts, state_machine):
    arthLending = ArthLending.deploy({'from': accounts[0]})
    arthBorrowerMock = ArthBorrowerMock.deploy({'from': accounts[1]})
    arthLending.initialize(accounts[0], 0, {'from': accounts[0]})
    arthLending.deposit("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", Wei("12 ether"), 1, {'from': accounts[0], "value": Wei("12 ether")})
    state_machine(StateMachine, accounts, arthLending, arthBorrowerMock)
