# Private Energy Market React

A React application demonstrating FHEVM SDK integration for confidential renewable energy trading.

## Features

- **Wallet Integration**: Connect with MetaMask or other web3 wallets
- **FHEVM SDK Integration**: Demonstrates encryption and decryption of sensitive data
- **Energy Trading**: Submit confidential energy offers and demands
- **Modern UI**: Built with React 18 and Vite for optimal performance
- **TypeScript**: Full type safety throughout the application

## Getting Started

### Prerequisites

- Node.js 18+ installed
- MetaMask or another web3 wallet
- Access to Sepolia testnet

### Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env.local

# Update .env.local with your contract address
```

### Development

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

The application will be available at `http://localhost:3001`

## Project Structure

```
private-energy-market-react/
├── src/
│   ├── components/           # React components
│   │   ├── WalletConnect.tsx       # Wallet connection component
│   │   ├── TradingPeriodInfo.tsx   # Trading period display
│   │   ├── EnergyOfferForm.tsx     # Energy offer submission (with SDK)
│   │   └── EnergyDemandForm.tsx    # Energy demand submission (with SDK)
│   ├── App.tsx               # Main application component
│   ├── main.tsx              # Application entry point
│   └── index.css             # Global styles
├── public/                   # Static assets
├── index.html                # HTML template
├── package.json              # Dependencies and scripts
├── tsconfig.json             # TypeScript configuration
└── vite.config.ts            # Vite configuration
```

## FHEVM SDK Integration

This example demonstrates how to integrate the FHEVM SDK into a React application:

### 1. Initialize the Client

```typescript
import { createFhevmClient } from '@fhevm/sdk'

const client = await createFhevmClient({
  network: 'sepolia',
  contractAddress: '0x...'
})
```

### 2. Encrypt Values

```typescript
import { encrypt } from '@fhevm/sdk'

const encryptedAmount = await encrypt(client, 1000, { bits: 32 })
const encryptedPrice = await encrypt(client, 50, { bits: 32 })
```

### 3. Submit to Contract

```typescript
// Use encrypted values in contract calls
await contract.submitEnergyOffer(encryptedAmount, encryptedPrice, energyType)
```

## Environment Variables

Create a `.env.local` file based on `.env.example`:

- `VITE_CONTRACT_ADDRESS`: The deployed contract address
- `VITE_RPC_URL`: (Optional) Custom RPC endpoint
- `VITE_CHAIN_ID`: (Optional) Chain ID (defaults to Sepolia)

## Features Demonstrated

### Energy Offers (EnergyOfferForm.tsx)
- Encrypt energy amount using FHEVM SDK
- Encrypt price per kWh
- Submit confidential offers to smart contract

### Energy Demands (EnergyDemandForm.tsx)
- Encrypt demand amount
- Encrypt maximum price willing to pay
- Submit confidential demands

### Wallet Integration (WalletConnect.tsx)
- Connect/disconnect wallet
- Display connected address
- Handle account changes

### Trading Period Info (TradingPeriodInfo.tsx)
- Display current trading period
- Show period status
- Show time remaining

## Technology Stack

- **React 18**: Modern React with hooks
- **TypeScript**: Full type safety
- **Vite**: Fast build tool and dev server
- **Ethers.js**: Ethereum interaction
- **FHEVM SDK**: Confidential computation
- **fhevmjs**: Core FHEVM functionality

## Building for Production

```bash
npm run build
```

The build output will be in the `dist/` directory, ready for deployment to any static hosting service.

## Deployment

This application can be deployed to:
- Vercel
- Netlify
- AWS Amplify
- Any static hosting service

Make sure to set the environment variables in your hosting platform's configuration.

## License

MIT
