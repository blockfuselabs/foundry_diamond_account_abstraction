// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./BasePaymaster.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "../interfaces/ISmartAccountFactory.sol";
import "../libraries/Helpers.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";

/**
 * A paymaster based on eth-infinitism sample veryfingPaymaster contract
 * with extended features of:
 * (1) payment with ERC20 token with external/offchain exchange rate
 * (2) Added support for withdrawing ERC20 tokens
 */

contract PridePaymaster is BasePaymaster {

    using UserOperationLib for UserOperation;
    using SafeTransferLib for address;
    using ECDSA for bytes32;

    // calculated cost of the postOp
    uint256 public constant COST_OF_POST = 35000;
    uint256 private constant VALID_OFFSET = 20;
    uint256 private constant SIGNATURE_OFFSET = 148;
    address public immutable VERIFYING_SIGNER;

    constructor(
        IEntryPoint _entryPoint,
        address _owner,
        address _verifyingSigner
    ) BasePaymaster(_entryPoint, _owner) {
        VERIFYING_SIGNER = _verifyingSigner;
    }

    function getHash(
        UserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter,
        address paymentToken,
        uint256 exchangeRate
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    userOp.getSender(),
                    userOp.nonce,
                    block.chainid,
                    address(this),
                    validUntil,
                    validAfter,
                    paymentToken,
                    exchangeRate
                )
            );
    }

    /**
     * @dev     . Function to decode paymaster data
     * @param   paymasterAndData  . inpuuted paymaster data
     * @return  validUntil  . paymsater sponsorship validity timeout
     * @return  validAfter  . valid only after this time
     * @return  paymentToken  . ERC20 payment token
     * @return  exchangeRate  . current exchange rate inputted by the trusted verifier. exchnage rate is in 8 decimals
     */
    function parsePaymasterAndData(bytes calldata paymasterAndData) public pure returns (
        uint48 validUntil,
        uint48 validAfter,
        address paymentToken,
        uint256 exchangeRate,
        bytes calldata signature
    ) {
        (validUntil, validAfter, paymentToken, exchangeRate) =
        abi.decode(
            paymasterAndData[VALID_OFFSET:SIGNATURE_OFFSET],
            (uint48,uint48,address,uint256)
        );
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

    /**
     * @notice  . Gas fee equivalent will be withdrawn from the base/quote token
     * @dev     . This function ensures all conditions are met
     * @param   userOp  . The user operation to validate
     * @param   maxCost  . Amount of tokens required for prefunding
     * @return  context  . The context containing sender address, token and rate
     * @return  validationData  .
     */
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 maxCost
    ) internal view override returns (bytes memory context, uint256 validationData) {
        (maxCost);

        (
            uint48 validUntil,
            uint48 validAfter,
            address paymentToken,
            uint256 exchangeRate,
            bytes calldata signature
        ) = parsePaymasterAndData(userOp.paymasterAndData);
        //ECDSA library supports both 64 and 65-byte long signatures.
        // we only "require" it here so that the revert reason on invalid signature will be of "VerifyingPaymaster", and not "ECDSA"
        require(signature.length == 64 || signature.length == 65, "VerifyingPaymaster: invalid signature length in paymasterAndData");
        bytes32 hash = getHash(userOp, validUntil, validAfter, paymentToken, exchangeRate).toEthSignedMessageHash();
        uint256 gasPriceUserOp = userOp.gasPrice();

        context = abi.encode(
            userOp.getSender(),
            paymentToken,
            exchangeRate,
            gasPriceUserOp
        );

        //don't revert on signature failure: return SIG_VALIDATION_FAILED
        if(VERIFYING_SIGNER != hash.recover(signature)) {
            return (context, Helpers._packValidationData(true, validUntil, validAfter));
        }

        return (context, Helpers._packValidationData(false, validUntil, validAfter));
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        (address sender, address paymentToken, uint256 exchangeRate, uint256 gasPriceUserOp) = abi.decode(
            context,
            (address, address, uint256, uint256)
        );

        uint256 actualTokenCost = ((actualGasCost + (COST_OF_POST * gasPriceUserOp)) * exchangeRate) / 1e8;

        if (mode != PostOpMode.postOpReverted) {
            // attempt to pay with tokens
            paymentToken.safeTransferFrom(sender, owner(), actualTokenCost);
        }
    }
}