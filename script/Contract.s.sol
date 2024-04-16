// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DAOHandler} from "../src/DAOHandler.sol";
import {DAOToken} from "../src/Token.sol";

import {Script, console} from "lib/forge-std/src/Script.sol";

contract DAOHandlerScript is Script {
    function setUp() public {}

    address public tokenContractAddress; // Store the address of the DAOToken contract
    DAOHandler public nftContract;

    constructor() {
        tokenContractAddress = 0x1F89Fb372f035bCd83e6cAfb2e1b9f8B6aB6EE8b;
    }

    function run() public {
        uint privatekey = vm.envUint("DEV_PRIVATE_KEY");
        address account = vm.addr(privatekey);
        console.log(account);
        vm.startBroadcast(vm.addr(privatekey));

        // No need to deploy contract, just use the provided address
        nftContract = new DAOHandler(DAOToken(tokenContractAddress));

        vm.stopBroadcast();
    }
}
