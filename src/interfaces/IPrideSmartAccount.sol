// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


import "account-abstraction/interfaces/IEntryPoint.sol";
interface IPrideSmartAccount {
    function entryPoint() external pure returns (IEntryPoint);
    function getNonce() external view returns (uint256);
    function execute(address dest, uint256 value, bytes calldata data) external;
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata data) external;
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);
}