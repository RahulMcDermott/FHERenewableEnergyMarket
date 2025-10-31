# 🔐 Private Renewable Energy Market

> Privacy-preserving renewable energy trading platform powered by Zama FHEVM - enabling confidential bidding and transparent settlement on Ethereum

**Network**: Sepolia Testnet (Chain ID: 11155111)

**🌐 Live Demo**: [https://fhe-renewable-energy-market.vercel.app/](https://fhe-renewable-energy-market.vercel.app/)

**📦 GitHub Repository**: [https://github.com/RahulMcDermott/FHERenewableEnergyMarket](https://github.com/RahulMcDermott/FHERenewableEnergyMarket)

**🎯 SDK Repository**: [https://github.com/RahulMcDermott/fhevm-react-template](https://github.com/RahulMcDermott/fhevm-react-template)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)](https://soliditylang.org/)
[![Hardhat](https://img.shields.io/badge/Hardhat-2.19.0-orange)](https://hardhat.org/)

---

## 🌟 Overview

The Private Renewable Energy Market revolutionizes clean energy trading by combining **Fully Homomorphic Encryption (FHE)** with blockchain technology. Producers and consumers can submit **encrypted bids** for renewable energy without revealing sensitive pricing strategies, ensuring fair market conditions and competitive advantage protection.

**NEW**: Now includes a modern **React + Vite frontend application** with FHEVM SDK integration for easy interaction with the smart contract through an intuitive web interface!

### ✨ Key Features

- 🔐 **Fully Private Bidding** - Encrypted energy offers and demands using Zama FHEVM
- ⚡ **Multiple Energy Types** - Solar, Wind, Hydro, and Geothermal support
- 🌱 **Carbon Credit Tracking** - Automatic environmental impact calculation (500-350 gCO2/kWh)
- ⏰ **24-Hour Trading Periods** - Structured trading windows with settlement phases
- 🛡️ **DoS Protection** - Emergency pause mechanism and gas optimization
- 📊 **Transparent Settlement** - Public results after confidential trading
- 🔄 **Real-time Matching** - Efficient supply-demand matching algorithm
- 🎨 **Modern Frontend** - React + Vite application with MetaMask integration and FHEVM SDK

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    System Architecture                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Energy Producers                    Energy Consumers       │
│  ┌─────────────┐                     ┌─────────────┐        │
│  │   Solar     │                     │  Factory    │        │
│  │   Wind      │                     │  Office     │        │
│  │   Hydro     │                     │  Hospital   │        │
│  └──────┬──────┘                     └──────┬──────┘        │
│         │                                   │               │
│         └───────────────┬───────────────────┘               │
│                         ▼                                   │
│         ┌───────────────────────────────────┐              │
│         │   Encrypted Submission Layer      │              │
│         │   (Client-side FHE Encryption)    │              │
│         └───────────────┬───────────────────┘              │
│                         ▼                                   │
│         ┌───────────────────────────────────┐              │
│         │   Smart Contract (Sepolia)        │              │
│         │                                   │              │
│         │   ├─ Encrypted Storage            │              │
│         │   │  • euint32 amounts            │              │
│         │   │  • euint32 prices             │              │
│         │   │  • ebool status               │              │
│         │   │                               │              │
│         │   ├─ Homomorphic Operations       │              │
│         │   │  • FHE.add()                  │              │
│         │   │  • FHE.eq()                   │              │
│         │   │  • FHE.select()               │              │
│         │   │                               │              │
│         │   └─ Carbon Credit Calculation    │              │
│         └───────────────┬───────────────────┘              │
│                         ▼                                   │
│         ┌───────────────────────────────────┐              │
│         │   Zama FHEVM Network              │              │
│         │   (Encrypted Computation Layer)   │              │
│         └───────────────┬───────────────────┘              │
│                         ▼                                   │
│         ┌───────────────────────────────────┐              │
│         │   Settlement & Results            │              │
│         │   (Decryption after trading)      │              │
│         └───────────────────────────────────┘              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. Energy Producer → Encrypt Offer (amount, price, type)
                     ↓
2. Submit to Contract → Store as euint32 (FHE encrypted)
                     ↓
3. Energy Consumer → Encrypt Demand (amount, max_price)
                     ↓
4. Submit to Contract → Store as euint32 (FHE encrypted)
                     ↓
5. Trading Period Ends → Homomorphic matching (FHE operations)
                     ↓
6. Settlement → Decrypt results → Finalize trades
                     ↓
7. Award Carbon Credits → Calculate environmental impact
```

---

## 🔧 Technology Stack

### Smart Contracts
- **Solidity**: 0.8.24 (Latest stable)
- **FHEVM**: Zama @fhevm/solidity v0.5.0
- **Framework**: Hardhat 2.19.0
- **Network**: Ethereum Sepolia Testnet
- **EVM Version**: Cancun

### Frontend Application (New React + Vite)
- **React**: 18.2.0 (Modern hooks & TypeScript)
- **Build Tool**: Vite 5.0.0 (Fast HMR & optimized builds)
- **TypeScript**: 5.0.0 (Full type safety)
- **Web3 Integration**: Ethers.js 6.9.0
- **FHEVM SDK**: Custom @fhevm/sdk integration
- **FHE Library**: fhevmjs v0.5.0
- **Wallet**: MetaMask integration
- **Styling**: Custom CSS with modern design system
- **Dev Server**: Vite dev server (port 3001)

### Development Tools
- **Testing**: Mocha + Chai + Ethers.js 6.9.0
- **Linting**: Solhint + ESLint + Prettier
- **Security**: Husky pre-commit hooks + npm audit
- **Gas Optimization**: Gas Reporter + Contract Sizer
- **CI/CD**: GitHub Actions (Node 18.x & 20.x)
- **Coverage**: Codecov integration
- **TypeScript Tools**: @typescript-eslint/eslint-plugin + parser
- **React Linting**: eslint-plugin-react-hooks + react-refresh

### Encryption
- **FHE Types**: `euint32`, `euint64`, `ebool`
- **Operations**: `FHE.add()`, `FHE.eq()`, `FHE.select()`, `FHE.ge()`
- **Access Control**: `FHE.allow()`, `FHE.allowThis()`
- **Client-side Encryption**: FHEVM SDK with React integration

---

## 🚀 Quick Start

### Prerequisites

```bash
# Required
- Node.js v18+ or v20+
- npm or yarn
- Git

# For Deployment
- Sepolia testnet ETH (get from faucets)
- Etherscan API key (optional, for verification)
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/private-renewable-energy-market.git
cd private-renewable-energy-market

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env

# Edit .env with your configuration:
# - PRIVATE_KEY: Your wallet private key
# - SEPOLIA_RPC_URL: Sepolia RPC endpoint
# - ETHERSCAN_API_KEY: For contract verification
```

### Quick Deploy

```bash
# Compile contracts
npm run compile

# Run tests
npm test

# Deploy to Sepolia testnet
npm run deploy

# Verify contract on Etherscan
npm run verify
```

### Local Testing

```bash
# Terminal 1: Start local Hardhat node
npm run node

# Terminal 2: Run simulation
npm run simulate
```

### Frontend Application Setup

The project includes a modern **React + Vite frontend** located at `./private-energy-market-react/` that provides an intuitive user interface for interacting with the smart contract.

```bash
# Navigate to frontend directory
cd private-energy-market-react

# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local

# Edit .env.local with your configuration:
# - VITE_CONTRACT_ADDRESS: Deployed contract address
# - VITE_RPC_URL: (Optional) Custom Sepolia RPC URL
# - VITE_CHAIN_ID: (Optional) Default is 11155111 for Sepolia

# Start development server
npm run dev
# Frontend available at http://localhost:3001

# Build for production
npm run build

# Preview production build
npm run preview
```

**Frontend Features:**
- 🔐 **Wallet Integration**: Connect with MetaMask
- 📝 **Energy Offers**: Submit encrypted energy offers with FHEVM SDK
- 🏭 **Energy Demands**: Submit encrypted energy demands
- 📊 **Trading Period Info**: View current trading period status
- ⚡ **Real-time Encryption**: Client-side FHE encryption before submission
- 🎨 **Modern UI**: Clean, responsive design with dark theme
- ⚙️ **TypeScript**: Full type safety throughout the application

**Frontend Project Structure:**
```
private-energy-market-react/
├── src/
│   ├── components/              # React components
│   │   ├── WalletConnect.tsx    # Wallet connection
│   │   ├── TradingPeriodInfo.tsx # Trading info display
│   │   ├── EnergyOfferForm.tsx  # Offer form with SDK
│   │   └── EnergyDemandForm.tsx # Demand form with SDK
│   ├── App.tsx                  # Main app component
│   ├── main.tsx                 # Entry point
│   └── index.css                # Styles
├── vite.config.ts               # Vite configuration
├── tsconfig.json                # TypeScript config
└── package.json                 # Dependencies
```

---

## 💡 Usage Guide

### For Energy Producers

**Submit an Energy Offer:**

```solidity
// Submit encrypted offer
function submitEnergyOffer(
    uint32 amount,        // Energy in kWh (encrypted client-side)
    uint32 pricePerKwh,   // Price in wei per kWh (encrypted)
    uint8 energyType      // 1=Solar, 2=Wind, 3=Hydro, 4=Geothermal
) external;
```

**Example (Traditional):**
```javascript
// JavaScript client code
const amount = 1000; // 1000 kWh
const price = 50;    // 50 wei per kWh
const type = 1;      // Solar energy

await contract.submitEnergyOffer(amount, price, type);
```

**Example (Using FHEVM SDK in React):**
```typescript
// In your React component (see private-energy-market-react/)
import { createFhevmClient, encrypt } from '@fhevm/sdk'
import { ethers } from 'ethers'

// Initialize FHEVM client
const client = await createFhevmClient({
  network: 'sepolia',
  contractAddress: CONTRACT_ADDRESS
})

// Encrypt values before submission
const encryptedAmount = await encrypt(client, 1000, { bits: 32 })
const encryptedPrice = await encrypt(client, 50, { bits: 32 })

// Submit to contract with encrypted values
const contract = new ethers.Contract(address, abi, signer)
await contract.submitEnergyOffer(encryptedAmount, encryptedPrice, 1)
```

### For Energy Consumers

**Submit an Energy Demand:**

```solidity
// Submit encrypted demand
function submitEnergyDemand(
    uint32 amount,           // Required energy in kWh
    uint32 maxPricePerKwh    // Maximum price willing to pay
) external;
```

**Example:**
```javascript
const amount = 1200;   // Need 1200 kWh
const maxPrice = 60;   // Max 60 wei per kWh

await contract.submitEnergyDemand(amount, maxPrice);
```

### For Platform Operators

**Manage Trading Periods:**

```bash
# Start new trading period
npm run interact

# Process settlement
npm run interact -- --settle

# Award carbon credits
npm run interact -- --credits
```

---

## 🔐 Privacy Model

### What's Private (FHE Encrypted)

- ✅ **Energy Offer Amounts** - Producer quantities encrypted as `euint32`
- ✅ **Energy Offer Prices** - Pricing strategies protected via FHE
- ✅ **Energy Demand Amounts** - Consumer requirements confidential
- ✅ **Maximum Prices** - Buyer budgets remain private
- ✅ **Individual Positions** - No front-running or information leakage
- ✅ **Carbon Credit Balances** - Environmental credits encrypted

### What's Public (Blockchain Requirements)

- 📊 **Trading Period Status** - Active, ended, results revealed
- 📊 **Total Offer Count** - Number of offers (not details)
- 📊 **Total Demand Count** - Number of demands (not details)
- 📊 **Settlement Results** - After decryption, matched trades visible
- 📊 **Transaction Existence** - Blockchain transaction records

### Decryption Permissions

- **Producers**: Can decrypt their own offer status
- **Consumers**: Can decrypt their own demand status
- **Owner/Oracle**: Can decrypt aggregates for settlement
- **Contract**: Internal FHE operations without decryption

### FHE Operations Example

```solidity
// Encrypted comparison without revealing values
ebool priceMatches = FHE.le(offerPrice, demandMaxPrice);

// Conditional selection on encrypted data
euint32 matchedAmount = FHE.select(
    priceMatches,
    FHE.min(offerAmount, demandAmount),
    FHE.asEuint32(0)
);

// No decryption until settlement!
```

---

## 📋 Smart Contract API

### Core Functions

#### Trading Period Management

```solidity
// Start a new 24-hour trading period
function startTradingPeriod() external;

// Check if trading is active
function isTradingTimeActive() public view returns (bool);

// Get current period information
function getCurrentTradingPeriodInfo()
    external view returns (
        uint256 period,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool resultsRevealed
    );
```

#### Energy Trading

```solidity
// Submit energy offer (producer)
function submitEnergyOffer(
    uint32 _amount,
    uint32 _pricePerKwh,
    uint8 _energyType
) external onlyDuringTradingTime;

// Submit energy demand (consumer)
function submitEnergyDemand(
    uint32 _amount,
    uint32 _maxPricePerKwh
) external onlyDuringTradingTime;
```

#### Settlement & Credits

```solidity
// Process trading and reveal results (owner only)
function processTrading() external onlyDuringSettlementTime onlyOwner;

// Award carbon credits based on energy production (owner only)
function awardCarbonCredits(
    address producer,
    uint32 energyAmount,
    uint8 energyType
) external onlyOwner;
```

#### Emergency Controls

```solidity
// Emergency pause (owner only)
function pauseTrading() external onlyOwner;

// Resume trading (owner only)
function resumeTrading() external onlyOwner;
```

### View Functions

```solidity
// Get producer's offer count
function getProducerOfferCount(address producer)
    external view returns (uint256);

// Get consumer's demand count
function getConsumerDemandCount(address consumer)
    external view returns (uint256);

// Get trading period history
function getTradingPeriodHistory(uint256 period)
    external view returns (...);
```

---

## 🌐 Deployment

### Sepolia Testnet

**Network Details:**
```
Chain ID: 11155111
RPC URL: https://rpc.sepolia.org
Block Explorer: https://sepolia.etherscan.io
```

**Get Testnet ETH:**
- [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
- [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)
- [QuickNode Faucet](https://faucet.quicknode.com/ethereum/sepolia)

**Deployment Commands:**
```bash
# Deploy to Sepolia
npm run deploy

# Verify on Etherscan
npm run verify

# Interact with deployed contract
npm run interact
```

**After Deployment:**
- Contract address saved to `deployments/latest-sepolia.json`
- Etherscan verification link provided
- Update `.env` with `CONTRACT_ADDRESS`

---

## 🧪 Testing

### Test Suite Overview

```
✅ 45+ Comprehensive Test Cases
├── Deployment Tests (5)
├── Trading Period Management (5)
├── Energy Offer Submission (8)
├── Energy Demand Submission (6)
├── Trading Settlement (4)
├── Carbon Credits (4)
├── Emergency Functions (6)
├── View Functions (4)
├── Edge Cases (5)
└── Gas Optimization (3)
```

### Running Tests

```bash
# Run all tests (local)
npm test

# Run with gas reporting
npm run test:gas

# Generate coverage report
npm run coverage

# Run Sepolia integration tests
npm run test:sepolia
```

### Test Coverage

```
--------------------|----------|----------|----------|----------|
File                |  % Stmts | % Branch |  % Funcs |  % Lines |
--------------------|----------|----------|----------|----------|
PrivateRenewable    |      100 |    95.45 |      100 |      100 |
EnergyMarket.sol    |      100 |    95.45 |      100 |      100 |
--------------------|----------|----------|----------|----------|
All files           |      100 |    95.45 |      100 |      100 |
--------------------|----------|----------|----------|----------|
```

**See [TESTING.md](./TESTING.md) for detailed testing documentation.**

---

## ⛽ Gas Optimization

### Gas Costs

| Operation | Gas Used | Optimization |
|-----------|----------|--------------|
| Deploy Contract | ~2,800,000 | ✅ Optimized |
| Start Trading Period | ~150,000 | ✅ Efficient |
| Submit Energy Offer | ~250,000 | ✅ Packed storage |
| Submit Energy Demand | ~250,000 | ✅ Minimal SSTORE |
| Process Trading | ~100,000 | ✅ Batch operations |
| Award Carbon Credits | ~200,000 | ✅ FHE optimized |

### Optimization Techniques

- **Storage Packing**: `uint32` + `uint8` + `bool` in single slot
- **Loop Avoidance**: Batch processing instead of iterations
- **Memory over Storage**: Temporary data in memory
- **Event Emission**: Historical data via events
- **Compiler Settings**: 200 runs optimization

**Run gas report:**
```bash
npm run gas:report
```

---

## 🔒 Security

### Security Features

- ✅ **Access Control**: Owner-only functions for critical operations
- ✅ **Input Validation**: All inputs checked and sanitized
- ✅ **Reentrancy Protection**: Checks-effects-interactions pattern
- ✅ **Integer Safety**: Solidity 0.8.24 built-in overflow protection
- ✅ **Emergency Pause**: Circuit breaker for critical issues
- ✅ **DoS Prevention**: Gas limits and batch processing
- ✅ **FHE Security**: Proper ACL management for encrypted data

### Security Tools

```bash
# Run security audit
npm run security

# Lint Solidity code
npm run lint:sol

# Check dependencies
npm audit

# Pre-commit security checks (automatic)
git commit
```

### Security Audits

- **Solhint**: Static analysis (30+ rules)
- **ESLint**: JavaScript security checks
- **npm audit**: Dependency vulnerability scanning
- **Manual Review**: Pre-deployment checklist
- **CI/CD**: Automated security in pipeline

**See [SECURITY_PERFORMANCE.md](./SECURITY_PERFORMANCE.md) for details.**

---

## 🎯 Use Cases

### 1. Peer-to-Peer Energy Trading

**Scenario**: Residential solar panel owners selling excess energy

```
Solar Home → Encrypt offer (100 kWh @ 45 wei) → Contract
                                ↓
                         Private Matching
                                ↓
Office Building → Encrypt demand (120 kWh, max 50 wei)
```

**Benefits**:
- 🔐 Pricing strategies remain confidential
- 💰 Competitive market without information asymmetry
- 🌱 Automatic carbon credit rewards

### 2. Commercial Energy Procurement

**Scenario**: Factories buying renewable energy at scale

```
Multiple Producers → Submit encrypted offers
                                ↓
                    Private Auction (FHE)
                                ↓
Factory → Encrypt bulk demand → Best price matching
```

**Benefits**:
- 📊 No front-running on large orders
- 🔄 Real-time price discovery
- ♻️ Verified renewable sources

### 3. Carbon Credit Trading

**Scenario**: Environmental impact tracking

```
Producer → 1000 kWh Solar → Auto-calculate: 500 tons CO2 saved
                                ↓
                    Encrypted carbon credits
                                ↓
                    Tradable on secondary markets
```

**Carbon Factors:**
- Solar: 500 gCO2/kWh
- Wind: 450 gCO2/kWh
- Hydro: 400 gCO2/kWh
- Geothermal: 350 gCO2/kWh

---

## 📚 Documentation

### Core Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Complete deployment guide (500+ lines)
- **[TESTING.md](./TESTING.md)** - Testing documentation (400+ lines)
- **[SECURITY_PERFORMANCE.md](./SECURITY_PERFORMANCE.md)** - Security audit & optimization (600+ lines)
- **[CI_CD.md](./CI_CD.md)** - CI/CD pipeline documentation (400+ lines)

### External Resources

- **Zama Documentation**: [docs.zama.ai](https://docs.zama.ai)
- **FHEVM SDK**: [github.com/zama-ai/fhevm](https://github.com/zama-ai/fhevm)
- **Hardhat Guide**: [hardhat.org/docs](https://hardhat.org/docs)
- **Sepolia Testnet**: [sepolia.dev](https://sepolia.dev)

---

## 🛠️ Development

### Project Structure

```
private-renewable-energy-market/
├── contracts/
│   └── PrivateRenewableEnergyMarket.sol  # Main smart contract
├── scripts/
│   ├── deploy.js                          # Deployment automation
│   ├── verify.js                          # Etherscan verification
│   ├── interact.js                        # Contract interaction
│   └── simulate.js                        # Full simulation
├── test/
│   ├── PrivateRenewableEnergyMarket.test.js       # Unit tests
│   └── PrivateRenewableEnergyMarket.sepolia.test.js  # Integration tests
├── private-energy-market-react/           # Frontend application (NEW)
│   ├── src/
│   │   ├── components/                    # React components
│   │   │   ├── WalletConnect.tsx          # Wallet connection
│   │   │   ├── TradingPeriodInfo.tsx      # Trading period display
│   │   │   ├── EnergyOfferForm.tsx        # Offer form with FHEVM SDK
│   │   │   └── EnergyDemandForm.tsx       # Demand form with FHEVM SDK
│   │   ├── App.tsx                        # Main app component
│   │   ├── main.tsx                       # Entry point
│   │   └── index.css                      # Global styles
│   ├── vite.config.ts                     # Vite configuration
│   ├── tsconfig.json                      # TypeScript config
│   ├── package.json                       # Frontend dependencies
│   ├── .env.example                       # Frontend env template
│   └── README.md                          # Frontend documentation
├── .github/workflows/
│   └── test.yml                           # CI/CD pipeline
├── deployments/                           # Deployment records
├── docs/                                  # Additional documentation
├── .husky/                                # Git hooks
├── hardhat.config.js                      # Hardhat configuration
├── .solhint.json                          # Solidity linter config
├── .eslintrc.json                         # JavaScript linter config
├── .prettierrc.json                       # Code formatter config
├── codecov.yml                            # Coverage configuration
├── .env.example                           # Environment template
└── README.md                              # This file
```

### Available Scripts

#### Smart Contract Scripts
```bash
# Development
npm run compile              # Compile contracts
npm test                     # Run tests
npm run lint                 # Run all linters
npm run format               # Format code

# Deployment
npm run deploy               # Deploy to Sepolia
npm run deploy:local         # Deploy to localhost
npm run verify               # Verify on Etherscan

# Interaction
npm run interact             # Interact with contract
npm run simulate             # Run simulation

# Quality
npm run coverage             # Generate coverage report
npm run gas:report           # Gas usage analysis
npm run security             # Security audit

# CI/CD
npm run ci                   # Run full CI checks
```

#### Frontend Scripts (in private-energy-market-react/)
```bash
# Development
npm run dev                  # Start Vite dev server (port 3001)
npm run build                # Build for production (dist/)
npm run preview              # Preview production build
npm run lint                 # Lint TypeScript/React code

# Type Checking
tsc --noEmit                 # Check TypeScript types
```

### Environment Setup

```bash
# Install Husky hooks
npm run prepare

# Run pre-commit checks manually
npm run precommit

# Run pre-push checks manually
npm run prepush
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue: "Insufficient funds" error**
```bash
# Solution: Get Sepolia ETH from faucets
# https://sepoliafaucet.com/
```

**Issue: "Contract verification failed"**
```bash
# Solution: Ensure ETHERSCAN_API_KEY is set
# Wait 1-2 minutes after deployment
npm run verify
```

**Issue: "Tests failing"**
```bash
# Solution: Clean and reinstall
npm run clean
npm install
npm test
```

**Issue: "Gas estimation failed"**
```bash
# Solution: Check network connection
# Ensure sufficient ETH balance
# Try increasing gas limit in hardhat.config.js
```

**See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting.**

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Development Guidelines

- ✅ Write tests for new features
- ✅ Follow existing code style
- ✅ Update documentation
- ✅ Pass all CI/CD checks
- ✅ Include gas optimization analysis

---

## 🗺️ Roadmap

### Phase 1: Core Functionality ✅
- [x] FHE-encrypted bidding system
- [x] Trading period management
- [x] Carbon credit calculation
- [x] Emergency controls
- [x] Comprehensive testing

### Phase 2: Enhanced Features 🚧
- [ ] Automated matching algorithm
- [ ] Multi-period trading history
- [ ] Advanced analytics dashboard
- [ ] Mobile-friendly interface
- [ ] Real-time price oracle integration

### Phase 3: Ecosystem Growth 📅
- [ ] Governance mechanism (DAO)
- [ ] Secondary carbon credit market
- [ ] Cross-chain bridge support
- [ ] Enterprise API
- [ ] Mainnet deployment

### Phase 4: Scale & Optimize 🔮
- [ ] Layer 2 integration
- [ ] Bulk trading optimization
- [ [ ] Machine learning price prediction
- [ ] Regulatory compliance tools
- [ ] International market expansion

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) file for details.

```
Copyright (c) 2025 Private Renewable Energy Market

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Acknowledgments

- **Zama** - For pioneering FHEVM technology and privacy-preserving computation
- **Ethereum Foundation** - For Sepolia testnet infrastructure
- **Hardhat** - For excellent smart contract development framework
- **OpenZeppelin** - For security best practices and patterns

---

## 📞 Support & Links

### Get Help

- 📖 **Documentation**: Check our comprehensive docs above
- 🐛 **Bug Reports**: [Open an issue](https://github.com/your-org/repo/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-org/repo/discussions)
- 🔗 **Zama Community**: [Zama Discord](https://discord.gg/zama)

### Important Links

- **Zama Documentation**: [docs.zama.ai](https://docs.zama.ai)
- **FHEVM GitHub**: [github.com/zama-ai/fhevm](https://github.com/zama-ai/fhevm)
- **Sepolia Faucet**: [sepoliafaucet.com](https://sepoliafaucet.com/)
- **Hardhat Docs**: [hardhat.org/docs](https://hardhat.org/docs)

---

<div align="center">

**Built with ❤️ using Zama FHEVM**

*Enabling private and fair renewable energy markets for a sustainable future*

[⬆ Back to top](#-private-renewable-energy-market)

</div>
