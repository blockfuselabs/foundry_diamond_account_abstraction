// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;
import "./IDiamondCut.sol";

interface ISmartAccountFactory {
    function createAccount(address owner, bytes32 salt, IDiamondCut.FacetCut[] calldata cut, address diamondInit) external returns (address account);
    function getAddress(bytes32 salt) external returns (address addr);
}