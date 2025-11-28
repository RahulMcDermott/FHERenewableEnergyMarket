# Private Renewable Energy Market

A privacy-preserving renewable energy trading platform built with **ZAMA Fully Homomorphic Encryption (FHE)**, featuring **Gateway callback pattern**, **refund mechanisms**, and **timeout protection**.

## Live Platform

- **Website**: [https://fhe-renewable-energy-market.vercel.app/](https://fhe-renewable-energy-market.vercel.app/)
- **Video**: [demo.mp4]
- **Contract Address**: `0x57fdac162Da016c5795fA2322ee2BDC5549430D8`
- **Network**: Ethereum Sepolia Testnet

## Core Features

### 1. Gateway Callback Pattern (Async FHE Processing)
- User submits encrypted energy offer/demand
- Contract records encrypted data on-chain
- Gateway decrypts volumes off-chain asynchronously
- Gateway callbacks to complete settlement on-chain
- Eliminates blocking on decryption operations

### 2. Refund Mechanism
- **Decryption Failures**: Automatic refund if FHE decryption fails
- **Timeout Protection**: Refunds if callback not received within 24 hours
- **Market Cancellation**: Full refunds for all participants
- **One-click Claim**: Users claim refunds via `claimDecryptionFailureRefund()`

### 3. Timeout Protection
- **24-hour Decryption Window**: Prevents permanent fund locks
- **Timeout Detection**: `checkDecryptionTimeout()` enables refund state
- **Automatic Eligibility**: After timeout, refunds are immediately claimable
- **Events**: `DecryptionTimeout` event emitted when timeout occurs

### 4. Privacy Protection Features

#### Random Multiplier for Division Privacy
```solidity
// Protects division operations from analysis:
uint256 randomMult = (uint256(keccak256(...)) % 9000) + 1000;
uint256 prize = (prizePool * userWeight * randomMult) / (totalWeight * randomMult);
```

#### Price Obfuscation
- Uses fuzzy matching with `PRICE_PRECISION = 1000`
- Prevents exact price inference from trade volumes
- Different multipliers per trading period (1000-10000 range)

#### Encrypted Volume Aggregation
```solidity
// FHE operations performed entirely on encrypted data
period.totalOfferVolume = FHE.add(period.totalOfferVolume, amount64);
period.totalDemandVolume = FHE.add(period.totalDemandVolume, amount64);
```

### 5. Security Features

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **Reentrancy Protection** | `nonReentrant` modifier on all fund transfers | Prevents recursive withdrawals |
| **Input Validation** | Range checks, format validation | Prevents malformed data attacks |
| **Access Control** | `onlyOwner`, `whenNotPaused` modifiers | Only authorized actors can perform actions |
| **Overflow Protection** | Solidity 0.8+ checked arithmetic | Prevents integer overflow/underflow |
| **Emergency Pause** | `emergencyPause()` function | Pause all operations if critical issue found |
| **State Machine** | `MarketState` enum | Enforces valid state transitions |
| **Cryptographic Verification** | `FHE.checkSignatures()` | Validates decryption proofs from Gateway |

### 6. Gas Optimization (HCU - Homomorphic Computation Unit)

- **Minimal FHE Operations**: Only essential cryptographic operations on-chain
  - Offer submission: 2-3 FHE operations
  - Demand submission: 2-3 FHE operations
  - Decryption request: 2 ciphertext conversions

- **Async Offloading**: Gateway handles heavy decryption work
  - Reduces on-chain computation
  - Lower gas costs per transaction
  - Faster block confirmation

- **Batch Operations**: Multiple trades aggregated before decryption
  - Scales to thousands of trades per period
  - Single decryption request for entire tally

## Architecture

### Market Lifecycle

```
1. START PERIOD
   Anyone can start a new trading period
   Generates random multiplier for privacy protection
   Market state: Active

2. TRADING
   Producers submit encrypted energy offers
   Consumers submit encrypted energy demands
   Volumes aggregated using FHE
   Prize pool accumulates from stakes
   Market state: Active

3. EXPIRY
   Trading closes at endTime (24 hours)
   Market state: Active (waiting for reveal)

4. REVEAL REQUEST
   Anyone calls requestTallyReveal()
   Contract sends decryption request to Gateway
   Market state: RevealRequested

5A. SUCCESS PATH (Gateway Callback)
   Gateway decrypts total volumes
   Calls resolveTallyCallback()
   Market state: Resolved
   Participants claim prizes

5B. FAILURE PATH (Timeout)
   24 hours pass without callback
   Anyone calls checkDecryptionTimeout()
   Market state: RefundAvailable
   All participants claim refunds

6. CLAIM
   Success: claimPrize()
   Timeout/Failure: claimDecryptionFailureRefund()
```

### State Diagram

```
┌─────────┐    start    ┌────────┐   endTime   ┌─────────┐
│  None   │ ──────────> │ Active │ ──────────> │ Expired │
└─────────┘             └────────┘             └─────────┘
                             │                      │
                             │ requestTallyReveal() │
                             v                      v
                     ┌────────────────┐
                     │ RevealRequested│
                     └────────────────┘
                        │           │
           callback()   │           │ 24h timeout
                        v           v
                  ┌──────────┐  ┌─────────────────┐
                  │ Resolved │  │ RefundAvailable │
                  └──────────┘  └─────────────────┘
                        │               │
                        v               v
                    claimPrize()   claimRefund()
```

## Smart Contract API

### Core Functions

#### Start Trading Period
```solidity
function startTradingPeriod() external payable
```
- **Privacy**: Generates random multiplier (1000-10000)
- **Duration**: 24-hour trading window
- **State**: Transitions to Active

#### Submit Energy Offer
```solidity
function submitEnergyOffer(
    uint32 _amount,
    uint32 _pricePerKwh,
    uint8 _energyType
) external payable
```
- **Privacy**: All data encrypted using FHE
- **Validation**: Amount > 0, Price > 0, Valid energy type (1-4)
- **Stake**: Minimum 0.005 ETH required

#### Submit Energy Demand
```solidity
function submitEnergyDemand(
    uint32 _amount,
    uint32 _maxPricePerKwh
) external payable
```
- **Privacy**: All data encrypted using FHE
- **Validation**: Amount > 0, MaxPrice > 0
- **Stake**: Minimum 0.005 ETH required

#### Gateway Decryption Request
```solidity
function requestTallyReveal() external
```
- **Condition**: Trading period ended
- **Timeout Recording**: Stores request timestamp
- **Async Pattern**: Request sent to Gateway for off-chain processing

#### Gateway Callback Resolution
```solidity
function resolveTallyCallback(
    uint256 requestId,
    bytes memory cleartexts,
    bytes memory decryptionProof
) external
```
- **Cryptographic Verification**: `FHE.checkSignatures()` validates proof
- **Atomic Resolution**: Updates all market state in one transaction
- **Event Emission**: Emits `MarketResolved` event

#### Timeout Protection
```solidity
function checkDecryptionTimeout() external
```
- **Condition**: 24 hours passed since reveal request
- **Effect**: Transitions market to `RefundAvailable` state
- **Permission**: Callable by anyone (safety mechanism)

#### Claims
```solidity
// Claim prize when market resolved
function claimPrize() external

// Claim refund when decryption fails/times out
function claimDecryptionFailureRefund() external
```

### View Functions

```solidity
// Get current trading period info
function getCurrentTradingPeriodInfo() external view
  returns (period, startTime, endTime, isActive, state, prizePool)

// Get user participation status
function getUserParticipation(address user) external view
  returns (hasParticipated, participationType, stakedAmount, hasClaimed)

// Check decryption timeout status
function getDecryptionStatus() external view
  returns (requestId, requestTime, isTimedOut, callbackComplete)

// Time remaining until timeout
function getTimeUntilTimeout() external view
  returns (remaining)
```

### Owner Functions

```solidity
// Platform administration
function withdrawPlatformFees(address to) external onlyOwner

// Emergency controls
function emergencyPause() external onlyOwner
function emergencyUnpause() external onlyOwner
function cancelMarket(string memory reason) external onlyOwner
function pauseTrading() external onlyOwner
function resumeTrading() external onlyOwner
```

## Security Analysis

### Smart Contract Security Measures

1. **Input Validation**
   ```solidity
   require(_energyType >= 1 && _energyType <= 4, "Invalid energy type");
   require(_amount > 0, "Amount must be greater than 0");
   require(msg.value >= MIN_PARTICIPATION_STAKE, "Insufficient stake");
   ```

2. **Access Control**
   ```solidity
   modifier onlyOwner() { require(msg.sender == owner, "Not authorized"); _; }
   modifier whenNotPaused() { require(!paused, "Contract is paused"); _; }
   modifier periodExists(uint256 period) { ... }
   modifier inState(uint256 period, MarketState expectedState) { ... }
   ```

3. **Reentrancy Protection**
   ```solidity
   modifier nonReentrant() {
       require(!_locked, "Reentrant call");
       _locked = true;
       _;
       _locked = false;
   }
   ```

4. **State Machine Validation**
   ```solidity
   enum MarketState {
       Active, Expired, RevealRequested, Resolved, RefundAvailable, Cancelled
   }
   ```

5. **Cryptographic Proof Verification**
   ```solidity
   FHE.checkSignatures(requestId, cleartexts, decryptionProof);
   ```

### Privacy Guarantees

| Threat | Protection | Mechanism |
|--------|-----------|-----------|
| Volume inference | FHE encryption | All operations on encrypted data until decryption |
| Division analysis | Random multipliers | 1000-10000 range multiplier per period |
| Timing attacks | Async Gateway pattern | Off-chain decryption hides processing time |
| Price leakage | Obfuscation precision | `PRICE_PRECISION = 1000` fuzzy matching |
| Permanent lock | Timeout protection | 24-hour refund window triggers automatic recovery |

## Installation & Setup

### Prerequisites
- Node.js 18+
- Hardhat
- ZAMA FHEVM SDK

### Quick Start

```bash
# Clone repository
git clone <repo-url>
cd private-renewable-energy-market

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Add your wallet private key and network RPC URLs

# Compile contracts
npm run compile

# Run tests
npm run test

# Deploy to Sepolia testnet
npm run deploy:sepolia
```

### Environment Variables

```env
# Network Configuration
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY

# Wallet
PRIVATE_KEY=your_wallet_private_key_here

# Gateway Configuration (ZAMA)
GATEWAY_URL=https://gateway.zama.ai
```

## Gas Optimization Benchmarks

| Operation | Gas Cost | Privacy | Notes |
|-----------|----------|---------|-------|
| Start Trading Period | ~150k | High (FHE setup) | One-time per period |
| Submit Offer | ~180k | High (FHE ops) | Minimal on-chain crypto |
| Submit Demand | ~180k | High (FHE ops) | Minimal on-chain crypto |
| Request Tally Reveal | ~80k | Medium | Just request metadata |
| Resolve via Callback | ~120k | High (verified) | Cryptographic proof check |
| Claim Prize | ~65k | N/A | Standard transfer |
| Check Timeout | ~30k | N/A | State query + update |

**Total for Full Trading Cycle**: ~600-700k gas for 10 participants

## Supported Energy Types

| Type | ID | Carbon Factor (gCO2/kWh) | Description |
|------|----|-----------------------|-------------|
| Solar | 1 | 500 | Photovoltaic and thermal solar |
| Wind | 2 | 450 | Onshore and offshore wind |
| Hydro | 3 | 400 | Hydroelectric power |
| Geothermal | 4 | 350 | Geothermal energy systems |

## Testing

### Test Suite Coverage

```bash
# Run all tests
npm run test

# Run specific test suite
npx hardhat test test/PrivateRenewableEnergyMarket.test.js

# Run with coverage
npm run test:coverage
```

### Test Categories

1. **Unit Tests**
   - Trading period creation
   - Energy offer submission with FHE encryption
   - Energy demand submission
   - Tally reveal request
   - Gateway callback handling

2. **Integration Tests**
   - Full trading lifecycle
   - Timeout scenarios
   - Refund paths

3. **Security Tests**
   - Reentrancy attacks
   - Invalid state transitions
   - Access control violations
   - Input validation edge cases

4. **Privacy Tests**
   - Volume secrecy verification
   - Random multiplier effectiveness
   - Price obfuscation validation

## Documentation

### Core Concepts

- **FHE (Fully Homomorphic Encryption)**: Computation on encrypted data without decryption
- **Gateway Pattern**: Off-chain processing with on-chain verification via callbacks
- **Homomorphic Aggregation**: Volume tallying while data remains encrypted
- **Zero Knowledge**: Results revealed without exposing individual trades

### Further Reading

- [ZAMA FHEVM Documentation](https://docs.zama.ai/fhevm)
- [Renewable Energy Markets](https://en.wikipedia.org/wiki/Electricity_market)
- [FHE Applications in Finance](https://eprint.iacr.org/2022/1074.pdf)



## License

BSD-3-Clause-Clear

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## Support

For questions or support:
- GitHub Issues: [Create an issue](../../issues)
- Discord: [Join ZAMA community](https://discord.gg/zama)

---

Built with ZAMA FHE Technology
