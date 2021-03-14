import sys
from brownie import *

active_network = network.show_active()
if active_network == "kovan":
    DAI = "0xff795577d9ac8bd7d90ee22b6c1703490b6512fd"
elif active_network == "mainnet":
    DAI = "TODO"
else:
    print("network {} not supported".format(active_network))
    sys.exit()

AMOUNT = "10 ether"

def main():
    accounts.load("account1")    
    AveLoan[0].flashloan(DAI, Wei(AMOUNT),  {'from':accounts[0], "gas_limit": 500000, "allow_revert":True})