
# @version 0.2.8

from vyper.interfaces import ERC20

interface AddressProvider:
    def get_registry() -> address: view
    def get_address(_id: uint256) -> address: view

interface RegistrySwap:
    def exchange_underlying(i: int128, j: int128, _dx: uint256, _min_dy: uint256) -> uint256: payable

admin: public(address)
#address_provider: public(address)

@external
def __init__():
    self.admin = msg.sender
    #address_provider = _address_provider

@external
def exchange(
    _pool: address,
    _outtoken: int128,
    _intoken: int128,
    _amount: uint256,
    _expected: uint256
) -> uint256:
    """
    @notice Exchange the synth deposited in this contract for another asset
    @dev Called via `SynthSwap.swap_from_synth`
    @param _pool Address of the Curve pool used in the exchange
    @param _outtoken output token index of the exchange
    @param _intoken input token index of the exchange
    @param _amount Amount of the deposited synth to exchange
    @param _expected Minimum amount of `_target` to receive in the exchange
    @return uint256 Amount of the deposited synth remaining in the contract
    """
    assert msg.sender == self.admin

    #registry_swap: address = AddressProvider(address_provider).get_address(2)
    #RegistrySwap(registry_swap).exchange_underlying(_pool, synth, _target, _amount, _expected, _receiver)
    #return ERC20(synth).balanceOf(self)
    outtoken_amount: uint256 = RegistrySwap(_pool).exchange_underlying(_outtoken, _intoken, _amount, _expected)
    return outtoken_amount

