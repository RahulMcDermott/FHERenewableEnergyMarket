# Deployment Guide

## Private Renewable Energy Market - Smart Contract Deployment

This guide provides complete instructions for deploying and interacting with the Private Renewable Energy Market smart contract.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Compilation](#compilation)
5. [Deployment](#deployment)
6. [Verification](#verification)
7. [Interaction](#interaction)
8. [Simulation](#simulation)
9. [Network Information](#network-information)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v18 or higher): [Download](https://nodejs.org/)
- **npm** or **yarn**: Package manager
- **Git**: Version control
- **MetaMask** or similar wallet: For Sepolia testnet

### Required Accounts & Keys

- **Sepolia ETH**: Get free testnet ETH from [Sepolia Faucet](https://sepoliafaucet.com/)
- **Etherscan API Key**: Register at [Etherscan](https://etherscan.io/apis)
- **RPC URL**: Use public Sepolia RPC or [Alchemy](https://www.alchemy.com/)/[Infura](https://infura.io/)

---

## Installation

### Step 1: Install Dependencies

```bash
npm install
```

This will install:
- Hardhat (v2.19.0)
- Ethers.js (v6.9.0)
- Hardhat Toolbox
- FHEVM Solidity
- dotenv

### Step 2: Verify Installation

```bash
npx hardhat --version
```

Expected output: `2.19.0` or higher

---

## Configuration

### Step 1: Create Environment File

Copy the example environment file:

```bash
cp .env.example .env
```

### Step 2: Configure Environment Variables

Edit `.env` and add your credentials:

```env
# Private Key (WITHOUT 0x prefix)
PRIVATE_KEY=your_wallet_private_key_here

# Sepolia RPC URL
SEPOLIA_RPC_URL=https://rpc.sepolia.org

# Etherscan API Key
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Optional: Enable gas reporting
REPORT_GAS=false
```

⚠️ **Security Warning**: Never commit your `.env` file to version control!

### Step 3: Fund Your Wallet

Get Sepolia testnet ETH:
1. Visit [Sepolia Faucet](https://sepoliafaucet.com/)
2. Enter your wallet address
3. Wait for ETH to arrive (usually < 1 minute)

---

## Compilation

### Compile Smart Contracts

```bash
npm run compile
```

This will:
- Compile all Solidity contracts in `contracts/`
- Generate TypeScript types in `typechain-types/`
- Create artifacts in `artifacts/`

### Clean Build

If you encounter compilation issues:

```bash
npm run clean
npm run compile
```

---

## Deployment

### Deploy to Sepolia Testnet

```bash
npm run deploy
```

**Expected Output:**

```
============================================================
Private Renewable Energy Market - Deployment Script
============================================================

Deploying to network: sepolia (Chain ID: 11155111)
Deployer address: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0
Deployer balance: 0.5 ETH

------------------------------------------------------------
Starting contract deployment...
------------------------------------------------------------

Deploying PrivateRenewableEnergyMarket contract...
Waiting for deployment confirmation...

============================================================
✅ DEPLOYMENT SUCCESSFUL
============================================================
Contract Address: 0x1234567890abcdef1234567890abcdef12345678
Deployer Address: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0
Network: sepolia
Chain ID: 11155111
============================================================

📊 Etherscan Links:
------------------------------------------------------------
Contract: https://sepolia.etherscan.io/address/0x1234...
Deployer: https://sepolia.etherscan.io/address/0x742d...
------------------------------------------------------------

⚠️  Remember to verify your contract:
   npm run verify
```

### Deploy to Local Network

For testing purposes, you can deploy to a local Hardhat network:

**Terminal 1 - Start local node:**
```bash
npm run node
```

**Terminal 2 - Deploy:**
```bash
npm run deploy:local
```

### Deployment Information

After deployment, the following files are created:

- `deployments/deployment-sepolia-[timestamp].json` - Full deployment record
- `deployments/latest-sepolia.json` - Latest deployment info

**Example deployment file:**
```json
{
  "network": "sepolia",
  "chainId": 11155111,
  "contractAddress": "0x1234567890abcdef1234567890abcdef12345678",
  "deployerAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
  "deploymentTime": "2024-01-15T10:30:00.000Z",
  "blockNumber": 5123456,
  "contractName": "PrivateRenewableEnergyMarket"
}
```

---

## Verification

### Verify Contract on Etherscan

After deployment, verify your contract for transparency:

```bash
npm run verify
```

**Expected Output:**

```
============================================================
Contract Verification Script
============================================================

Network: sepolia (Chain ID: 11155111)

Contract Address: 0x1234567890abcdef1234567890abcdef12345678

------------------------------------------------------------
Starting verification process...
------------------------------------------------------------

Verifying PrivateRenewableEnergyMarket...
This may take a few moments...

Successfully submitted source code for contract
contracts/PrivateRenewableEnergyMarket.sol:PrivateRenewableEnergyMarket
at 0x1234567890abcdef1234567890abcdef12345678
for verification on the block explorer. Waiting for verification result...

Successfully verified contract PrivateRenewableEnergyMarket
on Etherscan.

============================================================
✅ VERIFICATION SUCCESSFUL
============================================================

Contract verified on Etherscan!
View at: https://sepolia.etherscan.io/address/0x1234...#code
============================================================
```

### Manual Verification

If automatic verification fails, verify manually:

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS>
```

---

## Interaction

### Interactive Script

Run the interaction script to view contract status and test functions:

```bash
npm run interact
```

**Features:**
- View contract information
- Check trading period status
- View your offers and demands
- Submit energy offers
- Submit energy demands
- Award carbon credits (owner only)
- Process trading (owner only)

**Example Output:**

```
============================================================
Private Renewable Energy Market - Interactive Tool
============================================================

Network: sepolia (Chain ID: 11155111)
Account: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0

------------------------------------------------------------
Contract Information
------------------------------------------------------------

Contract Address: 0x1234567890abcdef1234567890abcdef12345678
Owner Address: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0
Your Address: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0
Are you owner? true

Current Trading Period: 1
Next Offer ID: 1
Next Demand ID: 1

Period Start Time: 1/15/2024, 10:30:00 AM
Period End Time: 1/16/2024, 10:30:00 AM
Is Active: true
Results Revealed: false

Trading Active: true
Settlement Active: false
```

### Custom Interactions

Modify `scripts/interact.js` to call specific functions:

```javascript
// Example: Submit an energy offer
await contract.submitEnergyOffer(1000, 50, 1); // 1000 kWh, 50 wei/kWh, Solar

// Example: Submit energy demand
await contract.submitEnergyDemand(800, 60); // 800 kWh, max 60 wei/kWh
```

---

## Simulation

### Run Full Simulation

Test the complete workflow on a local network:

**Terminal 1 - Start local node:**
```bash
npm run node
```

**Terminal 2 - Run simulation:**
```bash
npm run simulate
```

**Simulation Scenarios:**

1. **Start Trading Period** - Initialize a new trading period
2. **Submit Energy Offers** - Multiple producers submit offers
3. **Submit Energy Demands** - Consumers submit demands
4. **Trading Summary** - View all offers and demands
5. **Award Carbon Credits** - Calculate and award environmental credits
6. **Emergency Controls** - Test pause/resume functionality

**Example Output:**

```
============================================================
Private Renewable Energy Market - Simulation Script
============================================================

Network: localhost (Chain ID: 31337)

------------------------------------------------------------
Simulation Accounts:
------------------------------------------------------------
Owner:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Producer1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Producer2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
Consumer1: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Consumer2: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
------------------------------------------------------------

📦 Deploying PrivateRenewableEnergyMarket contract...
✅ Contract deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3

============================================================
Scenario 1: Starting Trading Period
============================================================

⏳ Starting new trading period...
✅ Trading period started

Period Number: 1
Start Time: 1/15/2024, 10:35:00 AM
End Time: 1/16/2024, 10:35:00 AM
Is Active: true

============================================================
Scenario 2: Producers Submit Energy Offers
============================================================

⚡ Producer 1 submitting Solar energy offer...
   Amount: 1000 kWh, Price: 50 wei/kWh
✅ Offer submitted - ID: 1, Type: Solar

💨 Producer 2 submitting Wind energy offer...
   Amount: 1500 kWh, Price: 45 wei/kWh
✅ Offer submitted - ID: 2, Type: Wind

...
```

---

## Network Information

### Sepolia Testnet

| Property | Value |
|----------|-------|
| Network Name | Sepolia |
| Chain ID | 11155111 |
| Currency | SepoliaETH (test ETH) |
| RPC URL | https://rpc.sepolia.org |
| Block Explorer | https://sepolia.etherscan.io |

### Getting Test ETH

**Sepolia Faucets:**
- [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
- [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)
- [QuickNode Faucet](https://faucet.quicknode.com/ethereum/sepolia)

---

## Contract Information

### Main Functions

#### Trading Period Management

```solidity
// Start a new trading period
function startTradingPeriod() external

// Get current period information
function getCurrentTradingPeriodInfo()
    returns (uint256, uint256, uint256, bool, bool)
```

#### Energy Trading

```solidity
// Submit energy offer (producer)
function submitEnergyOffer(
    uint32 _amount,
    uint32 _pricePerKwh,
    uint8 _energyType
) external

// Submit energy demand (consumer)
function submitEnergyDemand(
    uint32 _amount,
    uint32 _maxPricePerKwh
) external
```

#### Settlement & Credits

```solidity
// Process trading settlement (owner only)
function processTrading() external onlyOwner

// Award carbon credits (owner only)
function awardCarbonCredits(
    address producer,
    uint32 energyAmount,
    uint8 energyType
) external onlyOwner
```

### Energy Types

| ID | Type | Carbon Factor (gCO2/kWh) |
|----|------|--------------------------|
| 1 | Solar | 500 |
| 2 | Wind | 450 |
| 3 | Hydro | 400 |
| 4 | Geothermal | 350 |

---

## Troubleshooting

### Common Issues

#### Issue: "insufficient funds for intrinsic transaction cost"

**Solution:**
- Get more Sepolia ETH from faucets
- Check your wallet balance: `npm run interact`

#### Issue: "nonce too low"

**Solution:**
- Reset your MetaMask account
- Or wait a few minutes and retry

#### Issue: "Contract verification failed"

**Solution:**
- Ensure ETHERSCAN_API_KEY is set in .env
- Wait 1-2 minutes after deployment before verifying
- Try manual verification

#### Issue: "Error: network does not support ENS"

**Solution:**
- Make sure you're using the correct network in hardhat.config.js
- Check SEPOLIA_RPC_URL in .env

#### Issue: Compilation errors

**Solution:**
```bash
npm run clean
rm -rf cache artifacts
npm run compile
```

### Getting Help

- **Hardhat Documentation**: https://hardhat.org/docs
- **Ethers.js Documentation**: https://docs.ethers.org/v6/
- **FHEVM Documentation**: https://docs.zama.ai/fhevm

---

## Additional Scripts

### Available npm Scripts

```bash
npm run compile      # Compile contracts
npm run test         # Run tests
npm run deploy       # Deploy to Sepolia
npm run deploy:local # Deploy to localhost
npm run verify       # Verify on Etherscan
npm run interact     # Interact with contract
npm run simulate     # Run simulation
npm run node         # Start local node
npm run clean        # Clean artifacts
npm run coverage     # Test coverage report
```

---

## Security Considerations

⚠️ **Important Security Notes:**

1. **Never commit private keys** to version control
2. **Use .gitignore** to exclude .env file
3. **Test thoroughly** on testnet before mainnet
4. **Verify contracts** on Etherscan for transparency
5. **Use hardware wallets** for mainnet deployments
6. **Audit smart contracts** before production use

---

## License

MIT License - See LICENSE file for details

---

## Contact & Support

For issues, questions, or contributions:
- Create an issue in the repository
- Review existing documentation
- Check Hardhat and FHEVM documentation

---

**Last Updated:** January 2025
**Version:** 1.0.0
