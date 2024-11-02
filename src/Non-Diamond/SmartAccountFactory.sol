// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.20;

import "../interfaces/IDiamondCut.sol";
import { CREATE3 } from "solady/src/utils/CREATE3.sol";
import { Diamond } from "../Diamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";


/**
 * Pride Factory for smart account
 * A UserOperation "initcode" holds the address of the factory, and a method call to create account
 * The Factory's createAccount account returns a targetted account address
 * Te targetted account address is deterministic and can be call even before the account is created
 */

contract PrideSmartAccountFactory {
    event UpgradedAccount(address prideSmartAccount);

    using CREATE3 for bytes32;
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Reemove=2

    /**
     * Create an account and return its address.
     * return address if the account is already deployed with the inputed salt
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     */
    function createAccount(address owner, bytes32 salt, IDiamondCut.FacetCut[] calldata cut, address diamondInit) public returns (address account) {
        address deployedAddress = salt.getDeployed();
        if(deployedAddress.code.length == 0) {
            account = salt.deploy(
                abi.encodePacked(
                    type(Diamond).creationCode,
                    abi.encode(
                        owner,
                        cut,
                        diamondInit
                    )
                ),
                0
            );
        } else {
            account = deployedAddress;
        }
    }

    function getAddress(bytes32 salt) public view returns (address addr) {
        addr = salt.getDeployed();
    }
}