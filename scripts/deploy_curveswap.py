import sys
from brownie import *

def main():
    accounts.load("account1")    
    CurveSwap.deploy({'from':accounts[0]})