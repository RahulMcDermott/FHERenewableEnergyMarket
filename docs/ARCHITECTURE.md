# Private Belief Market - Architecture Documentation

## Overview

The Private Belief Market is a privacy-preserving prediction market built on **ZAMA Fully Homomorphic Encryption (FHE)**. This document details the architectural decisions, design patterns, and security measures implemented.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Frontend Application                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   React UI  │  │  Web3Modal  │  │  ZAMA SDK   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Smart Contract Layer                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │               PrivateBeliefMarket.sol                    │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │   Market    │  │   Voting    │  │   Claims    │      │    │
│  │  │  Creation   │  │   (FHE)     │  │   System    │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  │                                                          │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │  Gateway    │  │  Timeout    │  │   Refund    │      │    │
│  │  │  Callback   │  │ Protection  │  │  Mechanism  │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ZAMA FHEVM Layer                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Gateway Service                       │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ Decryption  │  │   Proof     │  │  Callback   │      │    │
│  │  │   Queue     │  │ Generation  │  │  Delivery   │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 FHE Coprocessor                          │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ Encryption  │  │  Compute    │  │ Threshold   │      │    │
│  │  │   Keys      │  │   (HCU)     │  │  Decrypt    │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Ethereum Network                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Sepolia Testnet                       │    │
│  │  Block Production │ Transaction Pool │ State Storage    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Gateway Callback Pattern

### Problem Statement

FHE decryption is computationally expensive and cannot be performed on-chain synchronously. The naive approach of blocking on decryption would:
- Exceed block gas limits
- Create unpredictable transaction costs
- Degrade user experience with long wait times

### Solution: Async Callback Architecture

```
┌──────────────┐    ┌────────────────┐    ┌───────────────┐
│    User      │    │    Contract    │    │    Gateway    │
│  (Frontend)  │    │  (On-chain)    │    │  (Off-chain)  │
└──────────────┘    └────────────────┘    └───────────────┘
       │                    │                     │
       │  1. requestTallyReveal()                 │
       │─────────────────► │                     │
       │                    │  2. FHE.requestDecryption()
       │                    │─────────────────────►
       │                    │                     │
       │                    │    3. Async Processing
       │                    │    (Threshold Decrypt)
       │                    │                     │
       │                    │  4. resolveTallyCallback()
       │                    │◄─────────────────────
       │                    │                     │
       │  5. Event: MarketResolved               │
       │◄────────────────── │                     │
       │                    │                     │
       │  6. claimPrize()                        │
       │─────────────────► │                     │
       │                    │                     │
```

### Implementation Details

```solidity
// Step 2: Request sent to Gateway
function requestTallyReveal(string memory marketId) external {
    // Prepare ciphertext handles
    bytes32[] memory ciphertexts = new bytes32[](2);
    ciphertexts[0] = FHE.toBytes32(market.yesVotes);
    ciphertexts[1] = FHE.toBytes32(market.noVotes);

    // Async request - returns immediately
    uint256 requestId = FHE.requestDecryption(
        ciphertexts,
        this.resolveTallyCallback.selector  // Callback selector
    );

    // Store for timeout protection
    market.decryptionRequestTime = block.timestamp;
    market.decryptionRequestId = requestId;
}

// Step 4: Gateway calls back with decrypted values
function resolveTallyCallback(
    uint256 requestId,
    bytes memory cleartexts,
    bytes memory decryptionProof
) external {
    // Verify cryptographic proof
    FHE.checkSignatures(requestId, cleartexts, decryptionProof);

    // Decode and store results
    (uint64 revealedYes, uint64 revealedNo) = abi.decode(
        cleartexts,
        (uint64, uint64)
    );

    market.revealedYes = revealedYes;
    market.revealedNo = revealedNo;
    market.state = MarketState.Resolved;
}
```

## Timeout Protection Mechanism

### Problem: Permanent Fund Locks

Without timeout protection:
- Gateway failures could lock funds forever
- Network issues could prevent callbacks
- Users would have no recourse

### Solution: 24-Hour Timeout Window

```
┌───────────────────────────────────────────────────────────────┐
│                    Timeout Protection Timeline                 │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  T+0h         T+12h           T+24h           T+∞            │
│    │            │               │              │              │
│    ▼            │               ▼              │              │
│ Request      Waiting...     TIMEOUT         Refund          │
│  Made                      Triggered        Available        │
│                                                               │
│  ═══════════════════════════════════════════════════════════ │
│  [         Normal Window        ][  Recovery Window  ]       │
│  [     Gateway Processing       ][  User Protection   ]      │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Implementation

```solidity
uint256 public constant DECRYPTION_TIMEOUT = 24 hours;

function checkDecryptionTimeout(string memory marketId) external {
    MarketInfo storage market = markets[marketId];

    require(
        market.state == MarketState.RevealRequested,
        "Not awaiting decryption"
    );
    require(
        block.timestamp >= market.decryptionRequestTime + DECRYPTION_TIMEOUT,
        "Timeout not reached"
    );

    // Transition to refund state
    market.state = MarketState.RefundAvailable;

    emit DecryptionTimeout(
        marketId,
        market.decryptionRequestTime,
        block.timestamp
    );
}
```

### Recovery Flow

```
1. Gateway fails to respond within 24 hours
2. Anyone calls checkDecryptionTimeout(marketId)
3. Market state transitions to RefundAvailable
4. Each participant calls claimDecryptionFailureRefund()
5. Full stake returned to all participants
```

## Refund Mechanism

### Refund Scenarios

| Scenario | Trigger | Refund Amount | Function |
|----------|---------|---------------|----------|
| Decryption Failure | Gateway error | Full stake | `claimDecryptionFailureRefund()` |
| Timeout | 24h without callback | Full stake | `claimDecryptionFailureRefund()` |
| Tie | Equal votes | Full stake | `claimTieRefund()` |
| Market Cancelled | Owner action | Full stake | `claimDecryptionFailureRefund()` |

### State Diagram for Refunds

```
                    ┌─────────────────┐
                    │     Active      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     Expired     │
                    └────────┬────────┘
                             │
                 ┌───────────┴───────────┐
                 ▼                       ▼
        ┌─────────────────┐     ┌─────────────────┐
        │ RevealRequested │     │    Cancelled    │
        └────────┬────────┘     └────────┬────────┘
                 │                       │
        ┌────────┴────────┐              │
        ▼                 ▼              │
┌─────────────────┐ ┌──────────────┐     │
│    Resolved     │ │   Timeout    │     │
└────────┬────────┘ └───────┬──────┘     │
         │                  │            │
    ┌────┴────┐             │            │
    ▼         ▼             ▼            ▼
┌───────┐ ┌───────┐   ┌─────────────────────┐
│Winner │ │  Tie  │   │   RefundAvailable   │
│Claims │ │Refund │   │   (All Refund)      │
└───────┘ └───────┘   └─────────────────────┘
```

## Privacy Protection Techniques

### 1. Random Multiplier for Division Privacy

**Problem:** Division operations can leak information:
```
// Vulnerable: prize = prizePool / totalVoters
// Attacker can infer totalVoters from prize amount
```

**Solution:** Random multiplier per market:
```solidity
uint256 public constant RANDOM_MULTIPLIER_MIN = 1000;
uint256 public constant RANDOM_MULTIPLIER_MAX = 10000;

function _generateRandomMultiplier() internal returns (uint256) {
    randomNonce++;
    uint256 random = uint256(keccak256(abi.encodePacked(
        block.timestamp,
        block.prevrandao,
        msg.sender,
        randomNonce
    )));

    return RANDOM_MULTIPLIER_MIN +
           (random % (RANDOM_MULTIPLIER_MAX - RANDOM_MULTIPLIER_MIN + 1));
}
```

Each market gets a unique multiplier (1000-10000), making it impossible to deduce exact participant counts from prize distributions.

### 2. Price Obfuscation

**Problem:** Exact vote tallies could reveal voting patterns.

**Solution:** Fuzzy precision matching:
```solidity
uint256 public constant PRICE_PRECISION = 1000;

// Tallies revealed only in aggregate, not individual votes
// Precision limits inference attacks
```

### 3. Encrypted Vote Aggregation

All FHE operations keep votes encrypted until final reveal:

```solidity
// Vote is NEVER revealed until market resolution
euint64 weight = FHE.fromExternal(encryptedWeight, inputProof);
euint64 zero = FHE.asEuint64(0);

// Conditional aggregation - all encrypted
ebool isYes = FHE.eq(FHE.asEuint64(voteType), FHE.asEuint64(1));
market.yesVotes = FHE.add(market.yesVotes, FHE.select(isYes, weight, zero));

// Grant contract access (required for callback)
FHE.allowThis(market.yesVotes);
```

### 4. HCU (Homomorphic Computation Unit) Optimization

**Problem:** FHE operations are expensive (gas and compute).

**Solution:** Minimize on-chain FHE operations:

```
Vote Submission (3 FHE operations):
├─ FHE.fromExternal() - Input validation
├─ FHE.eq() x2 - Vote type check
├─ FHE.select() x2 - Conditional aggregation
└─ FHE.add() x2 - Tally update

Decryption Request (2 operations):
├─ FHE.toBytes32() x2 - Convert for Gateway
└─ Off-chain decryption (Gateway handles heavy lifting)

Resolution (1 operation):
└─ FHE.checkSignatures() - Verify decryption proof
```

**Total per market with 100 votes:** ~600 FHE operations
**vs. Naive approach:** ~2000+ operations

## Security Architecture

### 1. Access Control

```solidity
// Role definitions
address public owner;  // Contract administrator

// Access modifiers
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

modifier marketExists(string memory marketId) {
    require(markets[marketId].creator != address(0), "Market not found");
    _;
}

modifier inState(string memory marketId, MarketState expectedState) {
    require(markets[marketId].state == expectedState, "Invalid state");
    _;
}
```

### 2. Reentrancy Protection

```solidity
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// All fund-transferring functions protected
function claimPrize(string memory marketId) external nonReentrant {
    // State updated BEFORE transfer
    userVote.hasClaimed = true;

    // Transfer happens last
    (bool success, ) = payable(msg.sender).call{value: prize}("");
    require(success, "Transfer failed");
}
```

### 3. Input Validation

```solidity
// Market ID validation
modifier validMarketId(string memory marketId) {
    require(
        bytes(marketId).length > 0 &&
        bytes(marketId).length <= MAX_MARKET_ID_LENGTH,
        "Invalid market ID"
    );
    _;
}

// Vote type validation
require(voteType <= 1, "Invalid vote type");

// Stake validation
require(msg.value == market.voteStake, "Incorrect stake");

// FHE input validation
euint64 weight = FHE.fromExternal(encryptedWeight, inputProof);
// Throws if inputProof is invalid
```

### 4. State Machine Enforcement

```solidity
enum MarketState {
    Active,           // 0
    Expired,          // 1
    RevealRequested,  // 2
    Resolved,         // 3
    RefundAvailable,  // 4
    Cancelled         // 5
}

// Valid transitions enforced via modifiers
// vote() - requires Active
// requestTallyReveal() - requires Active or Expired
// claimPrize() - requires Resolved
// claimDecryptionFailureRefund() - requires RefundAvailable
```

### 5. Emergency Controls

```solidity
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

function emergencyPause() external onlyOwner {
    _pause();
    emit EmergencyAction("PAUSED", msg.sender, block.timestamp);
}

function cancelMarket(
    string memory marketId,
    string memory reason
) external onlyOwner {
    market.state = MarketState.RefundAvailable;
    emit MarketCancelled(marketId, msg.sender, reason);
}
```

## Data Flow

### Market Creation Flow

```
User Input:
├─ marketId: "election-2024"
├─ voteStake: 0.01 ETH
├─ duration: 7 days
└─ msg.value: 0.02 ETH (platform fee)

Contract Processing:
├─ Validate all inputs
├─ Generate random multiplier
├─ Initialize FHE encrypted counters (euint64)
├─ Store market info
├─ Accumulate platform fee
└─ Emit MarketCreated event

Storage Updated:
├─ markets[marketId] = MarketInfo{...}
├─ platformFees += msg.value
└─ randomNonce++
```

### Vote Flow

```
User Input:
├─ marketId: "election-2024"
├─ encryptedWeight: FHE ciphertext
├─ voteType: 1 (Yes)
├─ inputProof: FHE validity proof
└─ msg.value: 0.01 ETH (stake)

FHE Processing (HCU):
├─ FHE.fromExternal() - Validate & import ciphertext
├─ FHE.eq() - Check if Yes vote
├─ FHE.eq() - Check if No vote
├─ FHE.select() - Pick weight or zero (Yes)
├─ FHE.select() - Pick weight or zero (No)
├─ FHE.add() - Add to yesVotes
├─ FHE.add() - Add to noVotes
└─ FHE.allowThis() x2 - Grant contract access

Storage Updated:
├─ markets[marketId].yesVotes (encrypted)
├─ markets[marketId].noVotes (encrypted)
├─ markets[marketId].prizePool += msg.value
├─ markets[marketId].totalVoters++
├─ userVotes[marketId][msg.sender] = UserVote{...}
└─ Emit VoteCast event
```

### Resolution Flow

```
Request Phase:
├─ Creator calls requestTallyReveal()
├─ FHE.toBytes32() converts yesVotes, noVotes
├─ FHE.requestDecryption() sends to Gateway
├─ Store requestId, requestTime
└─ State: RevealRequested

Gateway Processing (Off-chain):
├─ Threshold decryption of ciphertexts
├─ Generate cryptographic proof
└─ Call resolveTallyCallback()

Callback Phase:
├─ FHE.checkSignatures() verifies proof
├─ Decode cleartexts: [revealedYes, revealedNo]
├─ Determine winner: yesWon = (revealedYes > revealedNo)
├─ State: Resolved
└─ Emit MarketResolved event
```

## Gas Analysis

### Operation Costs

| Operation | Gas | Primary Cost Source |
|-----------|-----|---------------------|
| createMarket | 150k | Storage (MarketInfo), FHE init |
| vote | 180k | FHE operations (7 ops), storage |
| requestTallyReveal | 80k | FHE.toBytes32 x2, storage |
| resolveTallyCallback | 120k | FHE.checkSignatures, storage |
| claimPrize | 65k | Storage update, ETH transfer |
| claimTieRefund | 60k | Storage update, ETH transfer |
| claimDecryptionFailureRefund | 60k | Storage update, ETH transfer |
| checkDecryptionTimeout | 30k | Storage update |

### Optimization Strategies

1. **Batch FHE Operations**: Single vote = 7 FHE ops vs potential 20+
2. **Async Decryption**: Gateway handles expensive crypto
3. **Storage Packing**: MarketInfo struct optimized for slot usage
4. **Short-circuit Checks**: Early `require()` statements save gas on failures

## Future Improvements

### Planned Enhancements

1. **Multi-choice Markets**: Support for markets with >2 options
2. **Weighted Voting**: Different vote weights per user
3. **Market Categories**: Organized market discovery
4. **Delegation**: Vote delegation to trusted parties
5. **Reputation System**: User credibility tracking

### Research Areas

1. **Zero-Knowledge Proofs**: Additional privacy layer
2. **Cross-chain Markets**: Multi-chain liquidity
3. **Oracle Integration**: External data for market resolution
4. **Liquidity Mining**: Incentive mechanisms

---

**Document Version:** 1.0
**Last Updated:** November 2024
