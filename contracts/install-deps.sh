#!/bin/bash

echo "🔧 Installing Foundry dependencies for LinkPayWormhole..."
echo ""

cd "$(dirname "$0")"

# Install forge-std (required for deployment scripts)
echo "📦 Installing forge-std..."
forge install foundry-rs/forge-std --no-git

# Verify installations
echo ""
echo "✅ Checking installations..."

if [ -d "lib/openzeppelin-contracts/contracts" ]; then
    echo "✓ OpenZeppelin contracts: OK"
else
    echo "✗ OpenZeppelin contracts: MISSING"
fi

if [ -d "lib/forge-std/src" ]; then
    echo "✓ forge-std: OK"
else
    echo "✗ forge-std: MISSING"
fi

echo ""
echo "🏗️  Building contracts..."
forge build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Set up .env file with PRIVATE_KEY and RPC_URL"
    echo "2. Run: forge script script/DeployLinkPayWormhole.s.sol:DeployLinkPayWormhole --rpc-url \$BASE_SEPOLIA_RPC_URL --private-key \$PRIVATE_KEY --broadcast"
else
    echo ""
    echo "❌ Build failed. Check errors above."
fi
