import sys
from brownie import *


active_network = network.show_active()
if active_network == "kovan":
    curveRegistryAddressesProvider = "TODO"
elif active_network == "mainnet":
    curveRegistryAddressesProvider = " 0x7D86446dDb609eD0F5f8684AcF30380a356b2B4c"
else:
    print("network {} not supported".format(active_network))
    sys.exit()

def main():
    accounts.load("account1")    
    rthUniswapv2Swap.deploy({'from':accounts[0]})