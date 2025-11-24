# Quick Start Guide

Get the Private Belief Market up and running in 5 minutes.

## Prerequisites

- Node.js 18+
- npm or yarn
- MetaMask or another Web3 wallet
- Sepolia testnet ETH (get from [faucets](https://sepoliafaucet.com))

## Step 1: Clone & Install

```bash
git clone <repository-url>
cd dapp

npm install
```

## Step 2: Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env with your values
# - Add your private key (for deployment)
# - Add your RPC URLs
# - Add API keys for verification
```

## Step 3: Compile Contracts

```bash
npm run compile
```

## Step 4: Deploy to Sepolia

```bash
npm run deploy:sepolia
```

This will:
1. Compile the contract
2. Deploy to Sepolia testnet
3. Output the contract address
4. Verify on Etherscan

**Save the contract address!** You'll need it for interactions.

## Step 5: Interact with Contract

### Create a Market

```javascript
const marketId = "election-2024-yes-or-no";
const voteStake = ethers.utils.parseEther("0.01");  // 0.01 ETH per vote
const duration = 7 * 24 * 60 * 60;  // 7 days

const tx = await contract.createMarket(
    marketId,
    voteStake,
    duration,
    { value: ethers.utils.parseEther("0.02") }  // Platform fee
);

await tx.wait();
console.log("Market created:", marketId);
```

### Cast a Vote

```javascript
// Using ZAMA SDK to encrypt vote
import { createEncryptedInput } from "@zama-ai/tfhe";

const input = createEncryptedInput();
input.add64(1n);  // Vote weight
const encryptedInput = input.encrypt();

// Vote Yes (1) with encrypted weight
const tx = await contract.vote(
    marketId,
    encryptedInput.handle,
    1,  // 1 = Yes, 0 = No
    encryptedInput.inputProof,
    { value: ethers.utils.parseEther("0.01") }
);

await tx.wait();
console.log("Vote cast!");
```

### Request Market Results

```javascript
// Only creator can call this after market expires
const tx = await contract.connect(creatorSigner).requestTallyReveal(marketId);
await tx.wait();

console.log("Reveal requested, waiting for Gateway callback...");
```

### Monitor Decryption Status

```javascript
// Check if callback received
const status = await contract.getDecryptionStatus(marketId);

if (status.callbackComplete) {
    console.log("Results are in!");
    const market = await contract.getMarket(marketId);
    console.log(`Yes votes: ${market.revealedYes}`);
    console.log(`No votes: ${market.revealedNo}`);
    console.log(`Yes won: ${market.yesWon}`);
} else if (status.isTimedOut) {
    console.log("Timeout reached, refunds available");
} else {
    const timeRemaining = await contract.getTimeUntilTimeout(marketId);
    console.log(`Time until timeout: ${timeRemaining.toString()} seconds`);
}
```

### Claim Prize or Refund

```javascript
// Check user's vote
const userVote = await contract.getUserVote(marketId, userAddress);

if (userVote.hasVoted && !userVote.hasClaimed) {
    const market = await contract.getMarket(marketId);

    if (market.state === 3) {  // Resolved
        if (market.revealedYes === market.revealedNo) {
            // Tie - claim refund
            const tx = await contract.claimTieRefund(marketId);
            await tx.wait();
            console.log("Refund claimed!");
        } else {
            // Check if winner
            const isWinner = (market.yesWon && userVote.voteType === 1) ||
                           (!market.yesWon && userVote.voteType === 0);

            if (isWinner) {
                const tx = await contract.claimPrize(marketId);
                await tx.wait();
                console.log("Prize claimed!");
            }
        }
    } else if (market.state === 4) {  // RefundAvailable
        const tx = await contract.claimDecryptionFailureRefund(marketId);
        await tx.wait();
        console.log("Refund claimed due to timeout/failure");
    }
}
```

## Common Scenarios

### Scenario 1: Market Resolves Successfully

1. Create market → Users vote → Market expires
2. Creator calls `requestTallyReveal()`
3. Gateway decrypts and calls `resolveTallyCallback()`
4. Event `MarketResolved` emitted
5. Winners call `claimPrize()`
6. Tie participants call `claimTieRefund()`

### Scenario 2: Decryption Timeout

1. Create market → Users vote → Market expires
2. Creator calls `requestTallyReveal()`
3. 24+ hours pass without callback
4. Anyone calls `checkDecryptionTimeout()`
5. All participants call `claimDecryptionFailureRefund()`

### Scenario 3: Market Cancelled

1. Owner calls `cancelMarket(marketId, reason)`
2. Market transitions to `RefundAvailable`
3. All participants call `claimDecryptionFailureRefund()`

## Troubleshooting

### "Market already exists"
- You're using a duplicate market ID
- Solution: Use a unique identifier

### "Incorrect platform stake"
- You're not sending exactly 0.02 ETH
- Solution: Check the current `platformStake` value

### "Market not expired"
- Voting period hasn't ended yet
- Solution: Wait until `expiryTime` passes

### "Bet already resolved"
- Market has already been resolved
- Solution: Check market state first

### "Did not vote"
- You're trying to claim but didn't vote
- Solution: Only voters can claim

### "Timeout not reached"
- Less than 24 hours have passed
- Solution: Wait or check remaining time with `getTimeUntilTimeout()`

## Testing Locally

```bash
# Start local Hardhat node
npx hardhat node

# In another terminal, deploy to localhost
npm run deploy:local

# Run test suite
npm run test
```

## Monitor Gas Usage

```bash
# Enable gas reporting
REPORT_GAS=true npm run test

# Check contract sizes
npm run size
```

## Next Steps

1. **Read the Architecture**: See `docs/ARCHITECTURE.md` for deep dive
2. **API Reference**: Check `docs/API_REFERENCE.md` for all functions
3. **Deploy to Mainnet**: Follow same steps but use Mainnet RPC and fees

## Security Notes

⚠️ **Before Mainnet Deployment:**

1. Get professional security audit
2. Run full test suite
3. Deploy on testnet first
4. Test with real scenarios
5. Have emergency pause plan

## Support

- **Documentation**: Check `/docs` folder
- **Examples**: See `examples/` for integration examples
- **Issues**: Open GitHub issue for bugs
- **Discussion**: Join community Discord

---

**Happy building! 🚀**
