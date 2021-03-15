import sys
from brownie import *

active_network = network.show_active()
if active_network == "kovan":
    aveLendingPoolAddressesProviderAddress = "0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5"
elif active_network == "mainnet":
    aveLendingPoolAddressesProviderAddress = "0x24a42fD28C976A61Df5D00D0599C34c4f90748c8"
else:
    print("network {} not supported".format(active_network))
    sys.exit()

def main():
    accounts.load("account1")    
    ArthArbitrageA1CU2.deploy(aveLendingPoolAddressesProviderAddress,  {'from':accounts[0]})