# Private Belief Market - API Reference

Complete API documentation for the PrivateBeliefMarket smart contract.

## Table of Contents

1. [Market Creation](#market-creation)
2. [Voting & Encryption](#voting--encryption)
3. [Gateway Callback Pattern](#gateway-callback-pattern)
4. [Prize Distribution](#prize-distribution)
5. [Refund Mechanisms](#refund-mechanisms)
6. [View Functions](#view-functions)
7. [Owner Functions](#owner-functions)
8. [Events](#events)
9. [Error Messages](#error-messages)

---

## Market Creation

### createMarket

Creates a new privacy-preserving prediction market.

```solidity
function createMarket(
    string memory marketId,
    uint256 voteStake,
    uint256 duration
) external payable
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Unique market identifier (1-64 chars) |
| `voteStake` | uint256 | Required stake per vote in wei (min 0.005 ETH) |
| `duration` | uint256 | Market duration in seconds (5m-30d) |
| `msg.value` | uint256 | Platform fee (fixed at 0.02 ETH) |

**Returns:** None

**Modifiers:**
- `whenNotPaused`: Rejects if contract is paused
- `validMarketId`: Validates market ID format
- `nonReentrant`: Prevents reentrancy

**Events Emitted:**
```solidity
event MarketCreated(
    string indexed marketId,
    address indexed creator,
    uint256 platformStake,
    uint256 voteStake,
    uint256 expiryTime
)
```

**Example Usage (JavaScript/Ethers.js):**
```javascript
const tx = await contract.createMarket(
    "election-2024-outcome",
    ethers.utils.parseEther("0.01"),  // 0.01 ETH per vote
    7 * 24 * 60 * 60,                  // 7 days
    { value: ethers.utils.parseEther("0.02") }
);
await tx.wait();
```

**Validation Rules:**
- `marketId` must be 1-64 characters
- Must not already exist (`bets[marketId].creator == address(0)`)
- `voteStake` must be ≥ 0.005 ETH (MIN_VOTE_STAKE)
- `duration` must be between 5 minutes and 30 days
- `msg.value` must equal current `platformStake` (0.02 ETH)

**Gas Cost:** ~150,000 gas

**Security Notes:**
- Platform fee prevents market spam
- Random multiplier generated for privacy
- Reentrancy protected

---

## Voting & Encryption

### vote

Cast an encrypted, privacy-preserving vote on a market.

```solidity
function vote(
    string memory marketId,
    externalEuint64 encryptedWeight,
    uint8 voteType,
    bytes calldata inputProof
) external payable
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market identifier |
| `encryptedWeight` | externalEuint64 | FHE-encrypted vote weight |
| `voteType` | uint8 | 0 = No, 1 = Yes |
| `inputProof` | bytes | FHE input validity proof |
| `msg.value` | uint256 | Vote stake (exact match required) |

**Returns:** None

**Modifiers:**
- `whenNotPaused`: Rejects if paused
- `marketExists`: Market must exist
- `inState`: Market must be Active
- `nonReentrant`: Prevents reentrancy

**Events Emitted:**
```solidity
event VoteCast(
    string indexed marketId,
    address indexed voter,
    uint256 stake
)
```

**Example Usage (JavaScript with ZAMA SDK):**
```javascript
import { createEncryptedInput } from "@zama-ai/tfhe";

const input = createEncryptedInput();
input.add64(1n);  // Vote weight
const encryptedInput = input.encrypt();

const tx = await contract.vote(
    "election-2024-outcome",
    encryptedInput.handle,
    1,  // Yes vote
    encryptedInput.inputProof,
    { value: ethers.utils.parseEther("0.01") }
);
await tx.wait();
```

**Validation Rules:**
- Market must exist
- Market must be in Active state
- Current time < market expiryTime
- User must not have voted (`!hasVoted[marketId][msg.sender]`)
- `voteType` must be 0 or 1
- `msg.value` must exactly equal market's `voteStake`
- Input proof must be valid (FHE verification)

**FHE Operations:**
```solidity
// All operations on encrypted data
euint64 weight = FHE.fromExternal(encryptedWeight, inputProof);
ebool isYes = FHE.eq(FHE.asEuint64(voteType), FHE.asEuint64(1));
ebool isNo = FHE.eq(FHE.asEuint64(voteType), FHE.asEuint64(0));

// Conditional vote aggregation
market.yesVotes = FHE.add(market.yesVotes, FHE.select(isYes, weight, zero));
market.noVotes = FHE.add(market.noVotes, FHE.select(isNo, weight, zero));
```

**Gas Cost:** ~180,000 gas

**Security Notes:**
- Vote remains encrypted on-chain
- Choice not revealed until market resolution
- Reentrancy protected
- Input proof validates FHE ciphertext

---

## Gateway Callback Pattern

### requestTallyReveal

Request decryption of vote tallies from Gateway.

```solidity
function requestTallyReveal(string memory marketId) external
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market identifier |

**Returns:** None

**Modifiers:**
- `whenNotPaused`
- `marketExists`

**Events Emitted:**
```solidity
event TallyRevealRequested(
    string indexed marketId,
    uint256 requestId,
    uint256 requestTime
)
```

**Access Control:**
- Only market creator can call

**Conditions:**
- `block.timestamp >= market.expiryTime` (Market must be expired)
- `market.state == Active || market.state == Expired`
- Reveal not already requested

**Example Usage:**
```javascript
// After market expires
const tx = await contract.connect(creatorSigner).requestTallyReveal("election-2024-outcome");
const receipt = await tx.wait();

// Extract requestId from logs
const logs = receipt.logs;
const event = contract.interface.parseLog(logs[0]);
const requestId = event.args.requestId;
```

**Process Flow:**

```
1. Contract prepares ciphertexts: [yesVotes, noVotes]
2. Contract calls FHE.requestDecryption()
3. Request sent to ZAMA Gateway
4. Gateway decrypts off-chain (async)
5. Gateway calls resolveTallyCallback()
6. Results committed on-chain
```

**Gas Cost:** ~80,000 gas

**Timeout Protection:**
- Request timestamp stored in `market.decryptionRequestTime`
- After 24 hours without callback, market enters `RefundAvailable` state
- Users can claim refunds via `claimDecryptionFailureRefund()`

---

### resolveTallyCallback

Gateway callback to finalize market with decrypted results.

```solidity
function resolveTallyCallback(
    uint256 requestId,
    bytes memory cleartexts,
    bytes memory decryptionProof
) external
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `requestId` | uint256 | Original decryption request ID |
| `cleartexts` | bytes | ABI-encoded [revealedYes, revealedNo] |
| `decryptionProof` | bytes | Cryptographic proof of valid decryption |

**Returns:** None

**Modifiers:**
- `nonReentrant`: Atomic state update

**Events Emitted:**
```solidity
event MarketResolved(
    string indexed marketId,
    bool yesWon,
    uint64 revealedYes,
    uint64 revealedNo,
    uint256 totalPrize
)
```

**Security Verification:**
```solidity
// Cryptographic verification of decryption proof
FHE.checkSignatures(requestId, cleartexts, decryptionProof);

// Decode and validate results
(uint64 revealedYes, uint64 revealedNo) = abi.decode(cleartexts, (uint64, uint64));
```

**State Transitions:**
- `RevealRequested` → `Resolved`
- Sets `yesWon = (revealedYes > revealedNo)`
- Marks `callbackReceived[marketId] = true`

**Gas Cost:** ~120,000 gas

**Example (Gateway Integration):**
```javascript
// Gateway off-chain process
const revealedYes = 1850n;
const revealedNo = 1200n;

const cleartexts = ethers.utils.defaultAbiCoder.encode(
    ['uint64', 'uint64'],
    [revealedYes, revealedNo]
);

const tx = await contract.resolveTallyCallback(
    requestId,
    cleartexts,
    decryptionProof  // Signature from ZAMA
);
```

---

## Prize Distribution

### claimPrize

Winners claim their proportional share of the prize pool.

```solidity
function claimPrize(string memory marketId) external
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market to claim from |

**Returns:** None

**Modifiers:**
- `marketExists`
- `inState(marketId, MarketState.Resolved)`
- `nonReentrant`

**Events Emitted:**
```solidity
event PrizeDistributed(
    string indexed marketId,
    address indexed winner,
    uint256 amount
)
```

**Requirements:**
- Market must be resolved
- Caller must have voted
- Caller must not have claimed
- Market must not be a tie (`revealedYes != revealedNo`)
- Caller must have voted for winning side

**Prize Calculation:**
```solidity
uint256 totalWinningWeight = market.yesWon ? market.revealedYes : market.revealedNo;
uint256 prize = (market.prizePool * userStakeAmount) / totalWinningWeight;
```

**Example Usage:**
```javascript
// Winners claim after market resolves
const tx = await contract.claimPrize("election-2024-outcome");
await tx.wait();

console.log("Prize claimed!");
```

**Gas Cost:** ~65,000 gas

**Security Notes:**
- One-time claim via `hasClaimed` tracking
- Reentrancy protected
- Prize calculated on-chain (no external calls)

---

### claimTieRefund

Claim full refund when votes are tied.

```solidity
function claimTieRefund(string memory marketId) external
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market to claim from |

**Returns:** None

**Requirements:**
- Market must be resolved
- `revealedYes == revealedNo` (exact tie)
- Caller must have voted
- Caller must not have claimed

**Refund Amount:**
```solidity
uint256 refund = userVote.stakeAmount;  // Full stake returned
```

**Example Usage:**
```javascript
// In tie scenario
const tx = await contract.claimTieRefund("election-2024-outcome");
await tx.wait();
```

**Events Emitted:**
```solidity
event RefundProcessed(
    string indexed marketId,
    address indexed user,
    uint256 amount,
    string reason  // "TIE"
)
```

---

## Refund Mechanisms

### claimDecryptionFailureRefund

Claim refund when decryption fails or times out.

```solidity
function claimDecryptionFailureRefund(string memory marketId) external
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market to claim from |

**Returns:** None

**Requirements:**
- Market must be in `RefundAvailable` state
- Caller must have voted
- Caller must not have claimed

**Conditions Triggering RefundAvailable State:**
1. Decryption callback fails
2. 24-hour timeout expires without callback
3. Owner calls `cancelMarket()`

**Example Usage:**
```javascript
// After timeout or failure
const tx = await contract.claimDecryptionFailureRefund("election-2024-outcome");
await tx.wait();
```

**Events:**
```solidity
event RefundProcessed(
    string indexed marketId,
    address indexed user,
    uint256 amount,
    string reason  // "DECRYPTION_FAILURE"
)
```

---

### checkDecryptionTimeout

Transition market to `RefundAvailable` if decryption times out.

```solidity
function checkDecryptionTimeout(string memory marketId) external
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market to check |

**Returns:** None

**Conditions:**
- Market must be in `RevealRequested` state
- `block.timestamp >= decryptionRequestTime + 24 hours`

**Effect:**
- Sets `market.state = RefundAvailable`
- Enables `claimDecryptionFailureRefund()` for all participants

**Example Usage:**
```javascript
// After 24+ hours of no callback
const tx = await contract.checkDecryptionTimeout("election-2024-outcome");
await tx.wait();

console.log("Timeout triggered, refunds available");
```

**Events:**
```solidity
event DecryptionTimeout(
    string indexed marketId,
    uint256 requestTime,
    uint256 timeoutTime
)
```

**Gas Cost:** ~30,000 gas

**Safety:**
- Callable by anyone (permissionless recovery mechanism)
- Prevents permanent fund locks
- 24-hour timeout gives Gateway adequate time

---

## View Functions

### getMarket

Get complete market information.

```solidity
function getMarket(string memory marketId) external view returns (
    address creator,
    uint256 voteStake,
    uint256 expiryTime,
    uint256 prizePool,
    uint256 totalVoters,
    MarketState state,
    uint64 revealedYes,
    uint64 revealedNo,
    bool yesWon
)
```

**Returns:**
| Name | Type | Description |
|------|------|-------------|
| `creator` | address | Market creator address |
| `voteStake` | uint256 | Required stake per vote |
| `expiryTime` | uint256 | Market expiry timestamp |
| `prizePool` | uint256 | Total accumulated stakes |
| `totalVoters` | uint256 | Number of participants |
| `state` | MarketState | Current market state |
| `revealedYes` | uint64 | Decrypted Yes votes (if resolved) |
| `revealedNo` | uint64 | Decrypted No votes (if resolved) |
| `yesWon` | bool | Yes won the market |

**Example:**
```javascript
const market = await contract.getMarket("election-2024-outcome");
console.log(`Prize pool: ${ethers.utils.formatEther(market.prizePool)} ETH`);
console.log(`Total voters: ${market.totalVoters}`);
console.log(`Market state: ${market.state}`);  // 0=Active, 1=Expired, etc.
```

---

### getUserVote

Get user's vote information for a market.

```solidity
function getUserVote(string memory marketId, address user) external view returns (
    bool hasVoted,
    uint8 voteType,
    bool hasClaimed,
    uint256 stakeAmount
)
```

**Returns:**
| Name | Type | Description |
|------|------|-------------|
| `hasVoted` | bool | User has voted |
| `voteType` | uint8 | 0=No, 1=Yes |
| `hasClaimed` | bool | Claim/refund already processed |
| `stakeAmount` | uint256 | User's stake in wei |

**Example:**
```javascript
const vote = await contract.getUserVote("election-2024-outcome", userAddress);
if (vote.hasVoted) {
    console.log(`User voted: ${vote.voteType === 1 ? 'Yes' : 'No'}`);
    console.log(`Stake: ${ethers.utils.formatEther(vote.stakeAmount)} ETH`);
}
```

---

### getDecryptionStatus

Get decryption request status and timeout information.

```solidity
function getDecryptionStatus(string memory marketId) external view returns (
    uint256 requestId,
    uint256 requestTime,
    bool isTimedOut,
    bool callbackComplete
)
```

**Returns:**
| Name | Type | Description |
|------|------|-------------|
| `requestId` | uint256 | Gateway request ID (0 if not requested) |
| `requestTime` | uint256 | Timestamp of reveal request |
| `isTimedOut` | bool | Timeout has been reached |
| `callbackComplete` | bool | Callback has been received |

**Example:**
```javascript
const status = await contract.getDecryptionStatus("election-2024-outcome");
if (status.isTimedOut && !status.callbackComplete) {
    console.log("Timeout reached, refunds available");
}
```

---

### getTimeUntilTimeout

Get remaining time until decryption timeout.

```solidity
function getTimeUntilTimeout(string memory marketId) external view returns (uint256 remaining)
```

**Returns:**
| Name | Type | Description |
|------|------|-------------|
| `remaining` | uint256 | Seconds until timeout (0 if expired) |

**Special Values:**
- Returns `type(uint256).max` if no decryption request made
- Returns `0` if timeout has passed

**Example:**
```javascript
const remaining = await contract.getTimeUntilTimeout("election-2024-outcome");
if (remaining === 0n) {
    console.log("Timeout has passed");
} else if (remaining !== ethers.constants.MaxUint256) {
    console.log(`Time until timeout: ${remaining.toString()} seconds`);
}
```

---

## Owner Functions

### setPlatformStake

Update the platform fee amount.

```solidity
function setPlatformStake(uint256 newStake) external onlyOwner
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `newStake` | uint256 | New platform fee in wei |

**Requirements:**
- `msg.sender == owner`
- `newStake > 0`

**Example:**
```javascript
const tx = await contract.setPlatformStake(
    ethers.utils.parseEther("0.03")  // New fee: 0.03 ETH
);
await tx.wait();
```

---

### withdrawPlatformFees

Withdraw accumulated platform fees.

```solidity
function withdrawPlatformFees(address to) external onlyOwner
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `to` | address | Recipient address |

**Requirements:**
- `msg.sender == owner`
- `platformFees > 0`
- `to != address(0)`

**Example:**
```javascript
const tx = await contract.withdrawPlatformFees(treasuryAddress);
await tx.wait();
```

**Events:**
```solidity
event PlatformFeesWithdrawn(address indexed to, uint256 amount)
```

---

### emergencyPause

Pause all market operations.

```solidity
function emergencyPause() external onlyOwner
```

**Effect:**
- Disables `createMarket()`, `vote()`, `requestTallyReveal()`
- Allows only viewing and claiming refunds

**Example:**
```javascript
const tx = await contract.emergencyPause();
await tx.wait();
```

---

### emergencyUnpause

Resume market operations.

```solidity
function emergencyUnpause() external onlyOwner
```

**Example:**
```javascript
const tx = await contract.emergencyUnpause();
await tx.wait();
```

---

### cancelMarket

Cancel a market and enable refunds.

```solidity
function cancelMarket(string memory marketId, string memory reason) external onlyOwner
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| `marketId` | string | Market to cancel |
| `reason` | string | Cancellation reason |

**Requirements:**
- Market must be in Active, Expired, or RevealRequested state

**Effect:**
- Sets market state to `RefundAvailable`
- All participants can claim refunds

**Events:**
```solidity
event MarketCancelled(
    string indexed marketId,
    address indexed canceller,
    string reason
)
```

---

## Events

### MarketCreated

```solidity
event MarketCreated(
    string indexed marketId,
    address indexed creator,
    uint256 platformStake,
    uint256 voteStake,
    uint256 expiryTime
)
```

### VoteCast

```solidity
event VoteCast(
    string indexed marketId,
    address indexed voter,
    uint256 stake
)
```

### TallyRevealRequested

```solidity
event TallyRevealRequested(
    string indexed marketId,
    uint256 requestId,
    uint256 requestTime
)
```

### MarketResolved

```solidity
event MarketResolved(
    string indexed marketId,
    bool yesWon,
    uint64 revealedYes,
    uint64 revealedNo,
    uint256 totalPrize
)
```

### PrizeDistributed

```solidity
event PrizeDistributed(
    string indexed marketId,
    address indexed winner,
    uint256 amount
)
```

### RefundProcessed

```solidity
event RefundProcessed(
    string indexed marketId,
    address indexed user,
    uint256 amount,
    string reason  // "TIE", "DECRYPTION_FAILURE"
)
```

### DecryptionTimeout

```solidity
event DecryptionTimeout(
    string indexed marketId,
    uint256 requestTime,
    uint256 timeoutTime
)
```

---

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `PrivateBeliefMarket: caller is not owner` | Non-owner called owner function | Use owner account |
| `PrivateBeliefMarket: market does not exist` | Market ID invalid | Use correct market ID |
| `PrivateBeliefMarket: invalid market state` | Operation not allowed in current state | Wait for state transition |
| `PrivateBeliefMarket: invalid market ID` | Market ID format incorrect | Use 1-64 character ID |
| `PrivateBeliefMarket: incorrect platform stake` | msg.value doesn't match fee | Send correct amount |
| `PrivateBeliefMarket: vote stake too low` | Stake below minimum | Increase stake ≥ 0.005 ETH |
| `PrivateBeliefMarket: invalid duration` | Duration outside range | Use 5m-30d duration |
| `PrivateBeliefMarket: market already exists` | Market ID duplicated | Use unique ID |
| `PrivateBeliefMarket: market expired` | Voting period ended | Create new market |
| `PrivateBeliefMarket: incorrect vote stake` | msg.value doesn't match market stake | Send exact amount |
| `PrivateBeliefMarket: already voted` | User already voted | Each address votes once |
| `PrivateBeliefMarket: invalid vote type` | voteType not 0 or 1 | Use 0 (No) or 1 (Yes) |
| `PrivateBeliefMarket: not a tie` | Votes not equal | Use claimPrize() |
| `PrivateBeliefMarket: did not vote` | User didn't participate | Can't claim without voting |
| `PrivateBeliefMarket: already claimed` | Claim already processed | Only claim once |
| `PrivateBeliefMarket: not awaiting callback` | No decryption pending | Request reveal first |

---

## Constants

```solidity
uint256 public constant MIN_VOTE_STAKE = 0.005 ether;
uint256 public constant MIN_DURATION = 5 minutes;
uint256 public constant MAX_DURATION = 30 days;
uint256 public constant DECRYPTION_TIMEOUT = 24 hours;
uint256 public constant MAX_MARKET_ID_LENGTH = 64;
uint256 public constant RANDOM_MULTIPLIER_MIN = 1000;
uint256 public constant RANDOM_MULTIPLIER_MAX = 10000;
uint256 public constant PRICE_PRECISION = 1000;
```

---

## Enums

### MarketState
```solidity
enum MarketState {
    Active,           // 0: Accepting votes
    Expired,          // 1: Voting ended
    RevealRequested,  // 2: Decryption requested
    Resolved,         // 3: Results available
    RefundAvailable,  // 4: Refunds enabled
    Cancelled         // 5: Market cancelled
}
```

### VoteType
```solidity
enum VoteType {
    No,   // 0
    Yes   // 1
}
```

---

## Gas Optimization Summary

| Operation | Gas | Optimization |
|-----------|-----|--------------|
| createMarket | 150k | Batch random multiplier |
| vote | 180k | Minimal FHE ops (3 operations) |
| requestTallyReveal | 80k | Async Gateway processing |
| resolveTallyCallback | 120k | Cryptographic verification |
| claimPrize | 65k | Single transfer |
| claimTieRefund | 60k | Single transfer |
| claimDecryptionFailureRefund | 60k | Single transfer |
| checkDecryptionTimeout | 30k | State-only update |

**Total Market Cycle (10 participants)**: ~600-700k gas

---

**Last Updated:** November 2024
