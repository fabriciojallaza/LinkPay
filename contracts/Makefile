.PHONY: install build test clean deploy help

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)LinkPay Wormhole Contracts - Available Commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Install all dependencies (OpenZeppelin, forge-std)
	@echo "$(CYAN)Installing Foundry dependencies...$(NC)"
	@if [ ! -d "lib/openzeppelin-contracts" ]; then \
		echo "$(YELLOW)Installing OpenZeppelin contracts...$(NC)"; \
		forge install OpenZeppelin/openzeppelin-contracts --no-git; \
	else \
		echo "$(GREEN)✓ OpenZeppelin already installed$(NC)"; \
	fi
	@if [ ! -d "lib/forge-std/src" ]; then \
		echo "$(YELLOW)Installing forge-std...$(NC)"; \
		forge install foundry-rs/forge-std --no-git; \
	else \
		echo "$(GREEN)✓ forge-std already installed$(NC)"; \
	fi
	@echo "$(GREEN)✓ All dependencies installed!$(NC)"

update: ## Update dependencies to latest versions
	@echo "$(CYAN)Updating dependencies...$(NC)"
	@forge update

build: ## Build contracts
	@echo "$(CYAN)Building contracts...$(NC)"
	@forge build
	@echo "$(GREEN)✓ Build successful!$(NC)"

clean: ## Clean build artifacts
	@echo "$(CYAN)Cleaning build artifacts...$(NC)"
	@forge clean
	@echo "$(GREEN)✓ Clean complete!$(NC)"

test: ## Run tests
	@echo "$(CYAN)Running tests...$(NC)"
	@forge test -vvv

snapshot: ## Generate gas snapshot
	@echo "$(CYAN)Generating gas snapshot...$(NC)"
	@forge snapshot

format: ## Format Solidity files
	@echo "$(CYAN)Formatting Solidity files...$(NC)"
	@forge fmt

lint: ## Lint contracts
	@echo "$(CYAN)Linting contracts...$(NC)"
	@forge fmt --check

deploy-local: ## Deploy to local Anvil
	@echo "$(CYAN)Deploying to local network...$(NC)"
	@forge script script/DeployLinkPayWormhole.s.sol:DeployLinkPayWormhole \
		--rpc-url http://localhost:8545 \
		--broadcast

deploy-sepolia: ## Deploy to Base Sepolia (requires .env)
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ Error: .env file not found$(NC)"; \
		echo "$(YELLOW)Create .env with PRIVATE_KEY and BASE_SEPOLIA_RPC_URL$(NC)"; \
		exit 1; \
	fi
	@echo "$(CYAN)Deploying to Base Sepolia...$(NC)"
	@source .env && forge script script/DeployLinkPayWormhole.s.sol:DeployLinkPayWormhole \
		--rpc-url $$BASE_SEPOLIA_RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--verify \
		--etherscan-api-key $$BASESCAN_API_KEY \
		-vvvv

verify: ## Verify contract on BaseScan (requires CONTRACT_ADDRESS in .env)
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ Error: .env file not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(CYAN)Verifying contract on BaseScan...$(NC)"
	@source .env && \
	if [ -z "$$CONTRACT_ADDRESS" ]; then \
		echo "$(RED)✗ Error: CONTRACT_ADDRESS not set in .env$(NC)"; \
		exit 1; \
	fi && \
	forge verify-contract $$CONTRACT_ADDRESS \
		src/LinkPayWormhole.sol:LinkPayWormhole \
		--chain-id 84532 \
		--etherscan-api-key $$BASESCAN_API_KEY

anvil: ## Start local Anvil node
	@echo "$(CYAN)Starting Anvil...$(NC)"
	@anvil

setup: install build ## Full setup (install + build)
	@echo "$(GREEN)✓ Setup complete! Ready to deploy.$(NC)"
	@echo ""
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  1. Create .env file with your PRIVATE_KEY"
	@echo "  2. Run: $(GREEN)make deploy-sepolia$(NC)"

check-env: ## Check if .env is configured
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ .env file not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(CYAN)Checking .env configuration...$(NC)"
	@if grep -q "PRIVATE_KEY=" .env && ! grep -q "PRIVATE_KEY=your_private_key" .env; then \
		echo "$(GREEN)✓ PRIVATE_KEY configured$(NC)"; \
	else \
		echo "$(RED)✗ PRIVATE_KEY not configured$(NC)"; \
	fi
	@if grep -q "BASE_SEPOLIA_RPC_URL=" .env; then \
		echo "$(GREEN)✓ BASE_SEPOLIA_RPC_URL configured$(NC)"; \
	else \
		echo "$(YELLOW)⚠ BASE_SEPOLIA_RPC_URL not configured$(NC)"; \
	fi

info: ## Show project info
	@echo "$(CYAN)═══════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  LinkPay Wormhole CCTP Integration$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(CYAN)Contracts:$(NC)"
	@echo "  • LinkPayWormhole.sol  (Main contract)"
	@echo "  • MockUSDC.sol         (Test token)"
	@echo ""
	@echo "$(CYAN)Networks:$(NC)"
	@echo "  • Base Sepolia (10004)"
	@echo "  • Arbitrum Sepolia (10003)"
	@echo "  • Avalanche Fuji (6)"
	@echo "  • Optimism Sepolia (10005)"
	@echo "  • Ethereum Sepolia (10002)"
	@echo ""
	@echo "$(CYAN)Wormhole Integration:$(NC)"
	@echo "  • CircleIntegration: 0x2703483B1a5a7c577e8680de9Df8Be03c6f30e3c"
	@echo "  • USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e"
	@echo ""
	@echo "$(CYAN)Documentation:$(NC)"
	@echo "  • WORMHOLE_INTEGRATION.md - Complete guide"
	@echo "  • DEPLOYMENT_GUIDE.md     - Deployment steps"
	@echo "  • BUILD_SUCCESS.md        - Build summary"
	@echo ""
