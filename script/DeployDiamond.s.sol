// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { Diamond } from "../src/Diamond.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { DiamondInit } from "../src/upgradeInitializers/DiamondInit.sol";
import { SmartAccount } from "../src/facets/SmartAccount.sol";
import "./Helper.sol";

contract DeployDiamondScript is Script, IDiamondCut, Helper {
    function run() external {
        bytes32 privateKey = vm.envBytes32("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        DiamondCutFacet diamondCutDeploy = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupe = new DiamondLoupeFacet();
        OwnershipFacet ownership = new OwnershipFacet();
        SmartAccount prideAccount = new SmartAccount();

        FacetCut[] memory cut = new FacetCut[](4);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;

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

        DiamondInit diamondInit = new DiamondInit();

        // deploy diamond
        Diamond diamond = new Diamond(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            cut,
            address(diamondInit)
        );
        console.log("Diamond address deployed:", address(diamond));

        // call a function
        address[] memory facetAddresses =  DiamondLoupeFacet(address(diamond)).facetAddresses();

        for (uint256 i = 0; i < facetAddresses.length; i++) {
            console.log("facet addresses", facetAddresses[i]);
        }

        vm.stopBroadcast();
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}