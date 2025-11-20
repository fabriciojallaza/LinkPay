// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/LinkPayWormhole.sol";

/**
 * @title Deploy LinkPayWormhole
 * @notice Deployment script for LinkPayWormhole contract
 *
 * @dev Usage:
 * forge script script/DeployLinkPayWormhole.s.sol:DeployLinkPayWormhole \
 *   --rpc-url $BASE_SEPOLIA_RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --verify \
 *   --etherscan-api-key $BASESCAN_API_KEY
 */
contract DeployLinkPayWormhole is Script {
    // Base Sepolia Testnet Addresses
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // Circle USDC on Base Sepolia
    address constant WORMHOLE_CCTP_BASE_SEPOLIA = 0x2703483B1a5a7c577e8680de9Df8Be03c6f30e3c; // Wormhole CircleIntegration

    // Configuration
    uint256 constant REGISTRATION_FEE = 0; // No registration fee for testing (was 10 USDC for Chainlink LINK fees)

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying LinkPayWormhole contract...");
        console.log("Deployer:", deployer);
        console.log("USDC Address:", USDC_BASE_SEPOLIA);
        console.log("Wormhole CCTP Bridge:", WORMHOLE_CCTP_BASE_SEPOLIA);
        console.log("Registration Fee:", REGISTRATION_FEE);

        vm.startBroadcast(deployerPrivateKey);

        LinkPayWormhole linkPay = new LinkPayWormhole(
            USDC_BASE_SEPOLIA,
            deployer, // Fee wallet (same as deployer for now)
            REGISTRATION_FEE,
            WORMHOLE_CCTP_BASE_SEPOLIA
        );

        vm.stopBroadcast();

        console.log("===========================================");
        console.log("LinkPayWormhole deployed to:", address(linkPay));
        console.log("===========================================");
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contract on BaseScan");
        console.log("2. Register Chainlink Automation upkeep");
        console.log("3. Test cross-chain payment");
        console.log("");
        console.log("Supported Wormhole Chains:");
        console.log("- Base Sepolia: 10004 (same chain)");
        console.log("- Arbitrum Sepolia: 10003");
        console.log("- Avalanche Fuji: 6");
        console.log("- Optimism Sepolia: 10005");
        console.log("- Ethereum Sepolia: 10002");
    }
}
