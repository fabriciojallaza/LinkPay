// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {PayrollManager} from "./LinkPay.sol";

contract DeployLinkPay is Script {
    function run() external {
        vm.startBroadcast();

        address usdc = 0x6bdd4C79D274A19f4D3d12E7A1f1b17B64fE01d7;
        address feeWallet = 0x54948737285Dd3a61D4AF4834696E4D58239A251;
        uint256 fee = 1000000;
        
        // Direcciones con mayusculas correctas (Checksum)
        address router = 0x11984dc4465481512EB5b777e44061C158cf6544;
        address link = 0x15f330e61D0c08D971F202327e4976c593C46269;

        new PayrollManager(usdc, feeWallet, fee, router, link);

        vm.stopBroadcast();
    }
}