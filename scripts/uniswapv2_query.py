import sys
from brownie import *
import time

# Address is common across all networks
factory = interface.IUniswapV2Factory('0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f')

def showPair(i):
    pair_addr = factory.allPairs(i)
    pair = interface.IUniswapV2Pair(pair_addr)
    #token0 = interface.IERC20(pair.token0())
    #token1 = interface.IERC20(pair.token1())
    (reserve0, reserve1, blockTimestampLast) = pair.getReserves()
    print(f"pair {pair.name()}, {pair.symbol()}, {pair.token0()}, {pair.token1()} {reserve0/1E18} {reserve1/1E18} {blockTimestampLast}")

def showPairs(i):
    for j in range (i):
        showPair(j)
    time.sleep(1)
    
def main():
    pass