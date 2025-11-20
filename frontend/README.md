# LinkPay Frontend

A decentralized payroll management system built on blockchain technology. LinkPay enables companies to manage employee payments across multiple blockchain networks using USDC tokens and Chainlink price feeds.

## 🚀 Features

- **Company Registration**: Register your company on the blockchain with a one-time USDC registration fee
- **Employee Management**: Add, update, and manage employees with their wallet addresses and salary information
- **Cross-Chain Payments**: Schedule and execute payments across multiple blockchain networks:
  - Base Sepolia
  - Arbitrum
  - Avalanche
  - Ethereum Sepolia
- **Real-Time Price Feeds**: Live ETH/USD price feed integration using Chainlink
- **Payment History**: Track all payment transactions with detailed history
- **Dashboard**: Comprehensive overview of companies, employees, and payment statistics
- **Wallet Integration**: Seamless MetaMask wallet connection with automatic network switching

## 🛠️ Tech Stack

- **Framework**: [Next.js 16](https://nextjs.org/) with React 19
- **Language**: TypeScript
- **Styling**: Tailwind CSS 4
- **UI Components**: Radix UI primitives
- **Blockchain**: Ethers.js v5
- **Icons**: Lucide React
- **Forms**: React Hook Form
- **Notifications**: Sonner
- **Charts**: Recharts

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/) (v18 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/) or [pnpm](https://pnpm.io/)
- [MetaMask](https://metamask.io/) browser extension
- A wallet with testnet ETH and USDC on Base Sepolia testnet

## 🔧 Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd frontend
```

2. Install dependencies:
```bash
npm install
# or
yarn install
# or
pnpm install
```

3. Configure environment variables (if needed):
Create a `.env.local` file in the root directory:
```env
# Add any environment variables here if needed
# Currently, the app uses public RPC endpoints
```

4. Update contract addresses (if deploying new contracts):
Edit `util/interact.ts` and update:
- `PAYROLL_CONTRACT_ADDRESS`: Your deployed PayrollManager contract address
- `USDC_CONTRACT_ADDRESS`: Your deployed USDC token contract address

## 🚀 Getting Started

1. Start the development server:
```bash
npm run dev
# or
yarn dev
# or
pnpm dev
```

2. Open [http://localhost:3000](http://localhost:3000) in your browser

3. Connect your MetaMask wallet:
   - Click "Connect MetaMask" in the header
   - Approve the connection request
   - The app will automatically switch to Base Sepolia testnet

## 📁 Project Structure

```
frontend/
├── app/                    # Next.js app directory
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Main application page
│   └── globals.css        # Global styles
├── components/            # React components
│   ├── Dashboard.tsx      # Dashboard view
│   ├── CompanyRegistration.tsx  # Company registration form
│   ├── EmployeeList.tsx   # Employee management
│   ├── PaymentScheduler.tsx     # Schedule payments
│   ├── PaymentHistory.tsx       # Payment history
│   └── ui/               # Reusable UI components
│       ├── price-feed.tsx      # Chainlink price feed component
│       └── ...          # Other UI components
├── util/
│   └── interact.ts       # Smart contract interaction utilities
├── styles/               # Additional styles
└── public/              # Static assets
```

## 🔗 Smart Contract Integration

The application interacts with two main smart contracts:

1. **PayrollManager Contract**: Manages company registration, employee management, and payment scheduling
2. **USDC Token Contract**: Handles USDC token approvals and transfers

### Key Functions

- `connectWallet()`: Connects MetaMask and initializes contracts
- `registerCompany()`: Registers a new company on the blockchain
- `addEmployee()`: Adds an employee to a company
- `updateEmployee()`: Updates employee information
- `getPaymentHistory()`: Retrieves payment transaction history
- `getUSDCBalance()`: Gets the current USDC balance

## 🌐 Supported Networks

The application is configured for **Base Sepolia** testnet by default. The smart contracts support cross-chain payments to:

- **Base** (Selector: 0)
- **Arbitrum** (Selector: 1)
- **Avalanche** (Selector: 2)
- **Ethereum Sepolia** (Selector: 3)

## 💡 Usage Guide

### Registering a Company

1. Connect your MetaMask wallet
2. Navigate to "Register Company"
3. Enter your company name
4. Ensure you have sufficient USDC balance for the registration fee
5. Approve USDC spending (one-time approval for future payments)
6. Confirm the registration transaction

### Adding Employees

1. Navigate to "Schedule Payment"
2. Select your company
3. Enter employee details:
   - Employee name
   - Wallet address
   - Blockchain network (destination chain)
   - Salary amount in USDC
4. Confirm the transaction

### Viewing Payment History

1. Navigate to "Payment History"
2. View all past and scheduled payments
3. See transaction hashes and network information

## 🧪 Development

### Build for Production

```bash
npm run build
```

### Start Production Server

```bash
npm start
```

### Lint Code

```bash
npm run lint
```

## 🔒 Security Notes

- Always verify contract addresses before making transactions
- Never share your private keys or seed phrases
- Test thoroughly on testnets before using on mainnet
- Review all transaction details in MetaMask before confirming

## 📝 Configuration

### Contract Addresses

Update the contract addresses in `util/interact.ts`:

```typescript
export const PAYROLL_CONTRACT_ADDRESS = "0x..."; // Your contract address
export const USDC_CONTRACT_ADDRESS = "0x...";   // Your USDC address
```

### Network Configuration

The default network is Base Sepolia. To change networks, update the `CHAIN_ID` in `util/interact.ts`:

```typescript
const CHAIN_ID = "0x14a34"; // Base Sepolia (84532)
```

## 🐛 Troubleshooting

### Wallet Connection Issues

- Ensure MetaMask is installed and unlocked
- Check that you're on the correct network (Base Sepolia)
- Try disconnecting and reconnecting your wallet

### Transaction Failures

- Verify you have sufficient ETH for gas fees
- Check your USDC balance and allowance
- Ensure the contract addresses are correct
- Review the browser console for detailed error messages

### Price Feed Not Loading

- Check your internet connection
- Verify the Chainlink price feed contract address
- The price feed uses a public RPC endpoint - ensure it's accessible

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is part of the LinkPay system. Please refer to the main repository for license information.

## 🔗 Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Ethers.js Documentation](https://docs.ethers.io/)
- [Chainlink Documentation](https://docs.chain.link/)
- [MetaMask Documentation](https://docs.metamask.io/)

## 📧 Support

For issues and questions, please open an issue in the repository or contact the development team.

---

Built with ❤️ for decentralized payroll management
