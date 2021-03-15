# @version 0.2.8

from vyper.interfaces import ERC20

interface AddressProvider:
    def get_registry() -> address: view
    def get_address(_id: uint256) -> address: view

interface CurvePool:
    def exchange_underlying(i: int128, j: int128, _dx: uint256, _min_dy: uint256) -> uint256: payable

interface Registry:
    def get_coin_indices(_pool: address, _from: address, _to: address) -> (int128, int128, bool): view

admin: public(address)
address_provider: public(address)

@external
def __init__(_address_provider: address):
    self.admin = msg.sender
    self.address_provider = _address_provider

@external
def exchange(
    _pool: address,
    _outtoken_addr: address,
    _intoken_addr: address,
    _amount: uint256,
    _expected: uint256
) -> uint256:
    assert msg.sender == self.admin
    _intoken: int128 = 0
    _outtoken: int128 = 0
    res: bool = False
    _intoken, _outtoken, res = Registry(self.address_provider).get_coin_indices(_pool, _intoken_addr, _outtoken_addr)

    outtoken_amount: uint256 = CurvePool(_pool).exchange_underlying(_outtoken, _intoken, _amount, _expected)
    return outtoken_amount

