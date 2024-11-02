// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import "../interfaces/UserOperation.sol";
import "./LibDiamond.sol";


library LibImplementor {

    using UserOperationLib for UserOperation;
    using ECDSA for bytes32;
    /**
     * Return value in case of signature failure, with no time-range.
     * Equivalent to _packValidationData(true,0,0).
     */
    uint256 internal constant SIG_VALIDATION_FAILED = 1;
    IEntryPoint internal constant EntryPoint = IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    /**
     * @return  uint256  .return current nonce of smart account
     */
    function getNonce() internal view returns (uint256) {
        return EntryPoint.getNonce(address(this), 0);
    }

    /**
     * Ensure the request comes from the known entrypoint.
     */
    function requireFromEntryPoint() internal view {
        require(
            msg.sender == address(EntryPoint),
            "Account: Not from EntryPoint"
        );
    }

    /**
     * @dev     . Validate user's signature and nonce
     * @param   userOp  . The user operation to validate
     * @param   userOpHash  . The hash of the user operation
     * @param   missingAccountFunds  . Must pay Entrypoint(caller) at least the "missingAccountFunds",
     *                                 zero, if account deposit is high or paymaster present.
     * @return  validationData  . validation data which is a pack of authorizer(20 bytes), validUntil(6 bytes), validAfter(6 bytes)
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) internal returns (uint256 validationData) {
        requireFromEntryPoint();
        validationData = validateSignature(userOp, userOpHash);

        // mimic classic, sequential nonce
        require(userOp.nonce < type(uint64).max, "Account: Nonsequential nonce");
        // NOTE: may pay more than minimum to pay for future transaction
        if(missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds
            }("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    /**
     * @dev     . validate user signature
     * @param   userOp  . User operation to validate
     * @param   userOpHash  . The hash of the user operation
     * @return  uint256  . return 0 for VALID_SIGNATURE or 1 for SIG_VALIDATION_FAILED
     */
    function validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view returns (uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if(LibDiamond.contractOwner() != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;

        return 0;
    }

    /**
     * @dev     . Low level call to target contract
     * @param   target  . Target contract to interact with
     * @param   _value  . If sending value along
     * @param   data  . calldata to implement
     */
    function call(address target, uint256 _value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{
            value: _value
        }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * @dev     . execute a transaction call from EntryPoint
     * @param   dest  . target contract to interact with
     * @param   value  . greater than zero to send value along
     * @param   data  . data to implement
     */
    function execute(address dest, uint256 value, bytes calldata data) internal {
        requireFromEntryPoint();
        call(dest, value, data);
    }

    /**
     * @dev     . responsible for executing sequence of transaction
     * @param   dest  . batch target contracts
     * @param   value  . batch value to calling contract (0 if no value)
     * @param   data  . batch data to implement
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata data) internal {
        requireFromEntryPoint();
        require(dest.length == data.length && (value.length == 0 || value.length == dest.length), "Account: Wrong batch lengths");
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                call(dest[i], 0, data[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                call(dest[i], value[i], data[i]);
            }
        }
    }

}