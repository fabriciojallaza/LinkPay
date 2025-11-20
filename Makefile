.PHONY: help install build test clean deploy-contracts frontend-dev frontend-build

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "$(CYAN)═══════════════════════════════════════════$(NC)"
	@echo "$(GREEN)      LinkPay - Wormhole CCTP Payroll$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(CYAN)Quick Start:$(NC)"
	@echo "  1. $(GREEN)make install$(NC)      - Install all dependencies"
	@echo "  2. $(GREEN)make build$(NC)        - Build contracts"
	@echo "  3. Create .env in contracts/ with your PRIVATE_KEY"
	@echo "  4. $(GREEN)make deploy-contracts$(NC) - Deploy to Base Sepolia"
	@echo ""

install: ## Install all dependencies (contracts + frontend)
	@echo "$(CYAN)Installing all dependencies...$(NC)"
	@echo ""
	@echo "$(YELLOW)→ Installing contract dependencies...$(NC)"
	@cd contracts && $(MAKE) install
	@echo ""
	@echo "$(YELLOW)→ Installing frontend dependencies...$(NC)"
	@cd frontend/frontend && npm install
	@echo ""
	@echo "$(GREEN)✓ All dependencies installed!$(NC)"

install-contracts: ## Install only contract dependencies
	@echo "$(CYAN)Installing contract dependencies...$(NC)"
	@cd contracts && $(MAKE) install

install-frontend: ## Install only frontend dependencies
	@echo "$(CYAN)Installing frontend dependencies...$(NC)"
	@cd frontend/frontend && npm install

build: ## Build contracts and frontend
	@echo "$(CYAN)Building all components...$(NC)"
	@echo ""
	@echo "$(YELLOW)→ Building contracts...$(NC)"
	@cd contracts && $(MAKE) build
	@echo ""
	@echo "$(YELLOW)→ Building frontend...$(NC)"
	@cd frontend/frontend && npm run build
	@echo ""
	@echo "$(GREEN)✓ All components built!$(NC)"

build-contracts: ## Build only contracts
	@echo "$(CYAN)Building contracts...$(NC)"
	@cd contracts && $(MAKE) build

build-frontend: ## Build only frontend
	@echo "$(CYAN)Building frontend...$(NC)"
	@cd frontend/frontend && npm run build

test-contracts: ## Run contract tests
	@echo "$(CYAN)Running contract tests...$(NC)"
	@cd contracts && $(MAKE) test

clean: ## Clean all build artifacts
	@echo "$(CYAN)Cleaning build artifacts...$(NC)"
	@cd contracts && $(MAKE) clean
	@cd frontend/frontend && rm -rf .next out
	@echo "$(GREEN)✓ Clean complete!$(NC)"

deploy-contracts: ## Deploy LinkPayWormhole to Base Sepolia
	@echo "$(CYAN)Deploying contracts to Base Sepolia...$(NC)"
	@cd contracts && $(MAKE) deploy-sepolia

frontend-dev: ## Start frontend development server
	@echo "$(CYAN)Starting frontend development server...$(NC)"
	@echo "$(YELLOW)→ http://localhost:3000$(NC)"
	@cd frontend/frontend && npm run dev

frontend-build: ## Build frontend for production
	@echo "$(CYAN)Building frontend for production...$(NC)"
	@cd frontend/frontend && npm run build

frontend-start: ## Start frontend production server
	@echo "$(CYAN)Starting frontend production server...$(NC)"
	@cd frontend/frontend && npm start

anvil: ## Start local Anvil node
	@echo "$(CYAN)Starting Anvil local node...$(NC)"
	@cd contracts && $(MAKE) anvil

format: ## Format all code (Solidity + TypeScript)
	@echo "$(CYAN)Formatting code...$(NC)"
	@cd contracts && forge fmt
	@cd frontend/frontend && npm run lint
	@echo "$(GREEN)✓ Formatting complete!$(NC)"

setup: install build ## Complete setup (install + build everything)
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║   Setup Complete! 🎉                  ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  1. Create $(YELLOW)contracts/.env$(NC) file:"
	@echo "     $(GREEN)cd contracts && cp .env.example .env$(NC)"
	@echo "     Add your PRIVATE_KEY and BASE_SEPOLIA_RPC_URL"
	@echo ""
	@echo "  2. Deploy contracts:"
	@echo "     $(GREEN)make deploy-contracts$(NC)"
	@echo ""
	@echo "  3. Start frontend:"
	@echo "     $(GREEN)make frontend-dev$(NC)"
	@echo ""

check-setup: ## Verify installation status
	@echo "$(CYAN)Checking installation status...$(NC)"
	@echo ""
	@echo "$(CYAN)Foundry:$(NC)"
	@which forge > /dev/null && echo "  $(GREEN)✓ forge installed$(NC)" || echo "  $(RED)✗ forge not installed$(NC)"
	@which anvil > /dev/null && echo "  $(GREEN)✓ anvil installed$(NC)" || echo "  $(RED)✗ anvil not installed$(NC)"
	@echo ""
	@echo "$(CYAN)Node.js:$(NC)"
	@which node > /dev/null && echo "  $(GREEN)✓ node installed ($(shell node -v))$(NC)" || echo "  $(RED)✗ node not installed$(NC)"
	@which npm > /dev/null && echo "  $(GREEN)✓ npm installed ($(shell npm -v))$(NC)" || echo "  $(RED)✗ npm not installed$(NC)"
	@echo ""
	@echo "$(CYAN)Contract Dependencies:$(NC)"
	@if [ -d "contracts/lib/openzeppelin-contracts" ]; then \
		echo "  $(GREEN)✓ OpenZeppelin installed$(NC)"; \
	else \
		echo "  $(RED)✗ OpenZeppelin not installed$(NC)"; \
	fi
	@if [ -d "contracts/lib/forge-std/src" ]; then \
		echo "  $(GREEN)✓ forge-std installed$(NC)"; \
	else \
		echo "  $(RED)✗ forge-std not installed$(NC)"; \
	fi
	@echo ""
	@echo "$(CYAN)Frontend Dependencies:$(NC)"
	@if [ -d "frontend/frontend/node_modules" ]; then \
		echo "  $(GREEN)✓ npm packages installed$(NC)"; \
	else \
		echo "  $(RED)✗ npm packages not installed$(NC)"; \
	fi
	@echo ""

info: ## Show project information
	@echo "$(CYAN)═══════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  LinkPay - Automated Cross-Chain Payroll$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(CYAN)Project Structure:$(NC)"
	@echo "  • $(YELLOW)contracts/$(NC)         Smart contracts (Foundry)"
	@echo "    - LinkPayWormhole.sol (Wormhole CCTP)"
	@echo "    - MockUSDC.sol"
	@echo ""
	@echo "  • $(YELLOW)frontend/frontend/$(NC)  Next.js application"
	@echo "    - App Router (Next.js 16)"
	@echo "    - React 19, TypeScript 5"
	@echo "    - Tailwind CSS 4"
	@echo ""
	@echo "$(CYAN)Technologies:$(NC)"
	@echo "  • Wormhole CCTP   - Native USDC transfers"
	@echo "  • Chainlink       - Automation"
	@echo "  • OpenZeppelin    - Security utilities"
	@echo "  • Foundry         - Smart contract framework"
	@echo ""
	@echo "$(CYAN)Networks Supported:$(NC)"
	@echo "  • Base Sepolia      (Chain ID: 10004)"
	@echo "  • Arbitrum Sepolia  (Chain ID: 10003)"
	@echo "  • Avalanche Fuji    (Chain ID: 6)"
	@echo "  • Optimism Sepolia  (Chain ID: 10005)"
	@echo "  • Ethereum Sepolia  (Chain ID: 10002)"
	@echo ""
	@echo "$(CYAN)Documentation:$(NC)"
	@echo "  • WORMHOLE_INTEGRATION.md - Complete integration guide"
	@echo "  • DEPLOYMENT_GUIDE.md     - Deployment instructions"
	@echo "  • CLAUDE.md               - Developer reference"
	@echo ""

.PHONY: install-contracts install-frontend build-contracts build-frontend
.PHONY: test-contracts deploy-contracts frontend-dev frontend-build frontend-start
.PHONY: anvil format setup check-setup info
