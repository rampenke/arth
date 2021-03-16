import brownie
from brownie import accounts, ArthLending
import pytest
from brownie.test import strategy

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

    value = strategy('uint256', max_value="10 ether")
    #address = strategy('address')

    def __init__(cls, accounts, arthLending):
        # deploy the contract at the start of the test
        cls.accounts = accounts
        cls.arthLending = arthLending

    def setup(self):
        # zero the deposit amounts at the start of each test run
        self.deposits = {i: 0 for i in self.accounts}
    
    def rule_deposit(self, value):
        asset = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

        if value > 0:
            self.arthLending.deposit(asset, value, 1, {'from': self.accounts[0], 'value': value})
            assert self.arthLending.balance() >= 0
        else:
            # attempting to send <= 0 amount
            with brownie.reverts("Amount must be greater than 0"):
                self.arthLending.deposit(asset, value, 1, {'from': self.accounts[0], 'value': value})

    def rule_withdraw(self, value):
        asset = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        if value > 0:
            self.arthLending.withdraw(asset, value, 1, {'from': self.accounts[0]})
        else:
            # attempting to withdraw <= 0 amount
            with brownie.reverts("Amount must be greater than 0"):
                self.arthLending.withdraw(asset, value, 1, {'from': self.accounts[0]})

    def invariant(self):
        pass

def test_stateful(ArthLending, accounts, state_machine):
    arthLending = ArthLending.deploy({'from': accounts[0]})
    arthLending.initialize(accounts[0], 35, {'from': accounts[0]})
    state_machine(StateMachine, accounts, arthLending)
