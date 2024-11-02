// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.8.20;

import "../libraries/LibImplementor.sol";
import { IAccount } from "../interfaces/IAccount.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract SmartAccount is IAccount {

    /**
     * Query Entry point address
     */
    function entryPoint() public pure returns (IEntryPoint) {
        return LibImplementor.EntryPoint;
    }

    /**
     * Smart account nonce, mimics classic, sequential nonce
     */
    function getNonce() public view returns (uint256) {
        return LibImplementor.getNonce();
    }

    /**
     * Execute a transaction call directly from EntryPoint
     */
    function execute(address dest, uint256 value, bytes calldata data) external {
        LibImplementor.execute(dest, value, data);
    }

    /**
     * Execute sequence of transaction call directly from EntryPoint
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata data) external {
        LibImplementor.executeBatch(dest, value, data);
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        validationData = LibImplementor.validateUserOp(userOp, userOpHash, missingAccountFunds);
    }
}