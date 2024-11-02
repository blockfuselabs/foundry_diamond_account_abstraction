// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import "solady/src/tokens/ERC20.sol";

contract DummyAccount is ERC20{

    function name() public pure override returns (string memory) {
        return "Mocked";
    }

    function symbol() public pure override returns (string memory) {
        return "M";
    }
    function mint(address _to) public {
        _mint(_to, 1000*10e18);
    }
}