// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../script/Helper.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { IDiamondLoupe } from "../src/interfaces/IDiamondLoupe.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { DiamondInit } from "../src/upgradeInitializers/DiamondInit.sol";
import { PrideSmartAccountFactory } from "../src/Non-Diamond/SmartAccountFactory.sol";
import { ISmartAccountFactory } from "../src/interfaces/ISmartAccountFactory.sol";
import { SmartAccount } from "../src/facets/SmartAccount.sol";
import { IPrideSmartAccount } from "../src/interfaces/IPrideSmartAccount.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import "../src/Non-Diamond/DummyAccount.sol";
import "../src/interfaces/IERC20.sol";


/**
 * Unit test for smart account before proceeding to integration testing
 */

contract SmartAccountTest is Test, Helper, IDiamondCut {
    DiamondCutFacet diamondCutDeploy;
    DiamondLoupeFacet diamondLoupe;
    DiamondInit diamondInit;
    OwnershipFacet ownership;
    PrideSmartAccountFactory SAFactory;
    SmartAccount prideAccount;
    address sender1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address sender2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address smartAccount;
    uint256 incremental = 1;
    address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;


    function setUp() public {
        diamondCutDeploy = new DiamondCutFacet();
        diamondInit = new DiamondInit();
        diamondLoupe = new DiamondLoupeFacet();
        ownership = new OwnershipFacet();
        SAFactory = new PrideSmartAccountFactory();
        prideAccount = new SmartAccount();


        // Create account
        bytes32 _salt = keccak256(abi.encodePacked(sender1,bytes32(incremental)));

        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = FacetCut({
            facetAddress: address(diamondCutDeploy),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });

        cut[1] = FacetCut({
            facetAddress: address(diamondLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cut[2] = FacetCut({
            facetAddress: address(ownership),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        cut[3] = FacetCut({
            facetAddress: address(prideAccount),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("SmartAccount")
        });

        // create a smart account
        address getAddress = ISmartAccountFactory(address(SAFactory)).getAddress(
            _salt
        );

        smartAccount = ISmartAccountFactory(address(SAFactory)).createAccount(
            sender1,
            _salt,
            cut,
            address(diamondInit)
        );
        console.logAddress(getAddress);
        console.logAddress(smartAccount);

        assertEq(getAddress, smartAccount);

        // check number of facet
        address[] memory facetAddresses = IDiamondLoupe(smartAccount).facetAddresses();
        assertEq(facetAddresses.length, 4);
    }

    function testEntryPoint() public {
        IEntryPoint _entryPoint = IPrideSmartAccount(smartAccount).entryPoint();
        assertEq(address(_entryPoint), entryPoint);
    }

    function testExecute() public {
        vm.startPrank(entryPoint);
        DummyAccount dummyAccount = new DummyAccount();
        bytes memory _calldata = abi.encodeWithSignature(
            "mint(address)",
            smartAccount
        );
        IPrideSmartAccount(smartAccount).execute(
            address(dummyAccount),
            0,
            _calldata
        );

        uint256 smartAccountBal = IERC20(address(dummyAccount)).balanceOf(smartAccount);
        assertEq(smartAccountBal, 1000*10e18);
        vm.stopPrank();
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}