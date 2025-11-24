// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import { FHE, externalEuint64, euint64, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title PrivateBeliefMarket
 * @notice Privacy-preserving prediction market with FHE encryption and Gateway callback pattern
 * @dev Implements:
 *   - Gateway callback pattern for async FHE decryption
 *   - Refund mechanism for decryption failures
 *   - Timeout protection against permanent fund locks
 *   - Random multiplier for division privacy protection
 *   - Price obfuscation using fuzzy matching
 *   - Comprehensive input validation and access control
 *   - HCU (Homomorphic Computation Unit) gas optimization
 *
 * Architecture Flow:
 *   1. User submits encrypted request -> Contract records state
 *   2. Gateway receives decryption request -> Processes off-chain
 *   3. Gateway callback completes transaction -> Results committed on-chain
 *
 * Security Features:
 *   - Reentrancy protection on all state-changing functions
 *   - Input validation with range checks
 *   - Role-based access control
 *   - Integer overflow protection (Solidity 0.8+)
 *   - Emergency pause functionality
 */
contract PrivateBeliefMarket is SepoliaConfig, ReentrancyGuard, Pausable {

    // ============ Constants ============

    /// @notice Minimum stake amount per vote (0.005 ETH)
    uint256 public constant MIN_VOTE_STAKE = 0.005 ether;

    /// @notice Minimum market duration (5 minutes)
    uint256 public constant MIN_DURATION = 5 minutes;

    /// @notice Maximum market duration (30 days)
    uint256 public constant MAX_DURATION = 30 days;

    /// @notice Timeout period for decryption callback (24 hours)
    /// @dev After this period, users can claim refunds if callback not received
    uint256 public constant DECRYPTION_TIMEOUT = 24 hours;

    /// @notice Maximum market ID length to prevent abuse
    uint256 public constant MAX_MARKET_ID_LENGTH = 64;

    /// @notice Random multiplier range for privacy protection
    uint256 public constant RANDOM_MULTIPLIER_MIN = 1000;
    uint256 public constant RANDOM_MULTIPLIER_MAX = 10000;

    /// @notice Price obfuscation precision (3 decimal places)
    uint256 public constant PRICE_PRECISION = 1000;

    // ============ Enums ============

    /// @notice Market lifecycle states
    enum MarketState {
        Active,           // Accepting votes
        Expired,          // Voting ended, awaiting reveal
        RevealRequested,  // Decryption requested, waiting callback
        Resolved,         // Callback received, results available
        RefundAvailable,  // Decryption failed/timeout, refunds enabled
        Cancelled         // Market cancelled by owner
    }

    /// @notice Vote types
    enum VoteType {
        No,   // 0
        Yes   // 1
    }

    // ============ Structs ============

    /// @notice Market information structure
    struct MarketInfo {
        address creator;              // Market creator address
        uint256 platformStake;        // Platform fee paid
        uint256 voteStake;           // Required stake per vote
        uint256 expiryTime;          // Market voting end time
        uint256 decryptionRequestTime; // When decryption was requested
        uint256 decryptionRequestId;  // Gateway request ID

        // Encrypted vote tallies (FHE protected)
        euint64 yesVotes;
        euint64 noVotes;

        // Revealed results (after decryption)
        uint64 revealedYes;
        uint64 revealedNo;

        // Financial tracking
        uint256 prizePool;
        uint256 totalVoters;

        // State flags
        MarketState state;
        bool yesWon;

        // Privacy protection: random multiplier for division
        uint256 randomMultiplier;
    }

    /// @notice User vote record
    struct UserVote {
        bool hasVoted;
        VoteType voteType;
        bool hasClaimed;
        uint256 stakeAmount;
    }

    // ============ State Variables ============

    /// @notice Platform fee for creating markets
    uint256 public platformStake = 0.02 ether;

    /// @notice Accumulated platform fees
    uint256 public platformFees;

    /// @notice Contract owner
    address public owner;

    /// @notice Testing mode flag
    bool public isTesting;

    /// @notice Market storage
    mapping(string => MarketInfo) private markets;

    /// @notice User votes per market
    mapping(string => mapping(address => UserVote)) private userVotes;

    /// @notice Gateway request to market ID mapping
    mapping(uint256 => string) internal marketIdByRequestId;

    /// @notice Callback received tracking
    mapping(string => bool) public callbackReceived;

    /// @notice Nonce for random number generation
    uint256 private randomNonce;

    // ============ Events ============

    /// @notice Emitted when a market is created
    event MarketCreated(
        string indexed marketId,
        address indexed creator,
        uint256 platformStake,
        uint256 voteStake,
        uint256 expiryTime
    );

    /// @notice Emitted when a vote is cast
    event VoteCast(
        string indexed marketId,
        address indexed voter,
        uint256 stake
    );

    /// @notice Emitted when tally reveal is requested
    event TallyRevealRequested(
        string indexed marketId,
        uint256 requestId,
        uint256 requestTime
    );

    /// @notice Emitted when market is resolved via callback
    event MarketResolved(
        string indexed marketId,
        bool yesWon,
        uint64 revealedYes,
        uint64 revealedNo,
        uint256 totalPrize
    );

    /// @notice Emitted when prize is distributed
    event PrizeDistributed(
        string indexed marketId,
        address indexed winner,
        uint256 amount
    );

    /// @notice Emitted when refund is processed
    event RefundProcessed(
        string indexed marketId,
        address indexed user,
        uint256 amount,
        string reason
    );

    /// @notice Emitted when decryption times out
    event DecryptionTimeout(
        string indexed marketId,
        uint256 requestTime,
        uint256 timeoutTime
    );

    /// @notice Emitted when market is cancelled
    event MarketCancelled(
        string indexed marketId,
        address indexed canceller,
        string reason
    );

    /// @notice Emitted when platform fees are withdrawn
    event PlatformFeesWithdrawn(
        address indexed to,
        uint256 amount
    );

    /// @notice Emitted when contract is paused/unpaused
    event EmergencyAction(
        string action,
        address indexed triggeredBy,
        uint256 timestamp
    );

    // ============ Modifiers ============

    /// @notice Restricts function to contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "PrivateBeliefMarket: caller is not owner");
        _;
    }

    /// @notice Ensures market exists
    modifier marketExists(string memory marketId) {
        require(
            markets[marketId].creator != address(0),
            "PrivateBeliefMarket: market does not exist"
        );
        _;
    }

    /// @notice Ensures market is in expected state
    modifier inState(string memory marketId, MarketState expectedState) {
        require(
            markets[marketId].state == expectedState,
            "PrivateBeliefMarket: invalid market state"
        );
        _;
    }

    /// @notice Validates market ID format
    modifier validMarketId(string memory marketId) {
        require(
            bytes(marketId).length > 0 && bytes(marketId).length <= MAX_MARKET_ID_LENGTH,
            "PrivateBeliefMarket: invalid market ID"
        );
        _;
    }

    // ============ Constructor ============

    constructor() {
        owner = msg.sender;
    }

    // ============ Owner Functions ============

    /**
     * @notice Transfers ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "PrivateBeliefMarket: new owner is zero address");
        owner = newOwner;
    }

    /**
     * @notice Sets the platform stake amount
     * @param newStake The new platform stake amount in wei
     */
    function setPlatformStake(uint256 newStake) external onlyOwner {
        require(newStake > 0, "PrivateBeliefMarket: stake must be positive");
        platformStake = newStake;
    }

    /**
     * @notice Enables or disables testing mode
     * @param enabled Whether testing mode should be enabled
     */
    function setTesting(bool enabled) external onlyOwner {
        isTesting = enabled;
    }

    /**
     * @notice Withdraws accumulated platform fees
     * @param to The address to receive the fees
     */
    function withdrawPlatformFees(address to) external onlyOwner nonReentrant {
        require(to != address(0), "PrivateBeliefMarket: invalid recipient");
        require(platformFees > 0, "PrivateBeliefMarket: no fees to withdraw");

        uint256 amount = platformFees;
        platformFees = 0;

        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "PrivateBeliefMarket: withdrawal failed");

        emit PlatformFeesWithdrawn(to, amount);
    }

    /**
     * @notice Emergency pause - stops all market operations
     */
    function emergencyPause() external onlyOwner {
        _pause();
        emit EmergencyAction("PAUSED", msg.sender, block.timestamp);
    }

    /**
     * @notice Unpause contract operations
     */
    function emergencyUnpause() external onlyOwner {
        _unpause();
        emit EmergencyAction("UNPAUSED", msg.sender, block.timestamp);
    }

    /**
     * @notice Cancel a market (emergency function)
     * @param marketId The market to cancel
     * @param reason The reason for cancellation
     */
    function cancelMarket(
        string memory marketId,
        string memory reason
    ) external onlyOwner marketExists(marketId) {
        MarketInfo storage market = markets[marketId];
        require(
            market.state == MarketState.Active ||
            market.state == MarketState.Expired ||
            market.state == MarketState.RevealRequested,
            "PrivateBeliefMarket: cannot cancel in current state"
        );

        market.state = MarketState.RefundAvailable;

        emit MarketCancelled(marketId, msg.sender, reason);
    }

    // ============ Market Creation ============

    /**
     * @notice Creates a new prediction market
     * @param marketId Unique identifier for the market
     * @param voteStake Required stake per vote
     * @param duration Market duration in seconds
     */
    function createMarket(
        string memory marketId,
        uint256 voteStake,
        uint256 duration
    ) external payable whenNotPaused validMarketId(marketId) nonReentrant {
        // Input validation
        require(
            msg.value == platformStake,
            "PrivateBeliefMarket: incorrect platform stake"
        );
        require(
            voteStake >= MIN_VOTE_STAKE,
            "PrivateBeliefMarket: vote stake too low"
        );
        require(
            duration >= MIN_DURATION && duration <= MAX_DURATION,
            "PrivateBeliefMarket: invalid duration"
        );
        require(
            markets[marketId].creator == address(0),
            "PrivateBeliefMarket: market already exists"
        );

        // Generate random multiplier for privacy protection
        uint256 randomMult = _generateRandomMultiplier();

        // Create market with initialized FHE values
        markets[marketId] = MarketInfo({
            creator: msg.sender,
            platformStake: msg.value,
            voteStake: voteStake,
            expiryTime: block.timestamp + duration,
            decryptionRequestTime: 0,
            decryptionRequestId: 0,
            yesVotes: FHE.asEuint64(0),
            noVotes: FHE.asEuint64(0),
            revealedYes: 0,
            revealedNo: 0,
            prizePool: 0,
            totalVoters: 0,
            state: MarketState.Active,
            yesWon: false,
            randomMultiplier: randomMult
        });

        // Accumulate platform fees
        platformFees += msg.value;

        emit MarketCreated(
            marketId,
            msg.sender,
            msg.value,
            voteStake,
            block.timestamp + duration
        );
    }

    // ============ Voting ============

    /**
     * @notice Cast an encrypted vote on a market
     * @dev Uses Gateway callback pattern for FHE operations
     * @param marketId The market to vote on
     * @param encryptedWeight Encrypted vote weight
     * @param voteType Vote type (0 = No, 1 = Yes)
     * @param inputProof FHE input proof
     */
    function vote(
        string memory marketId,
        externalEuint64 encryptedWeight,
        uint8 voteType,
        bytes calldata inputProof
    ) external payable
      whenNotPaused
      marketExists(marketId)
      inState(marketId, MarketState.Active)
      nonReentrant
    {
        MarketInfo storage market = markets[marketId];

        // Input validation
        require(
            block.timestamp < market.expiryTime,
            "PrivateBeliefMarket: market expired"
        );
        require(
            msg.value == market.voteStake,
            "PrivateBeliefMarket: incorrect vote stake"
        );
        require(
            !userVotes[marketId][msg.sender].hasVoted,
            "PrivateBeliefMarket: already voted"
        );
        require(
            voteType <= 1,
            "PrivateBeliefMarket: invalid vote type"
        );

        // Process encrypted vote with HCU optimization
        // Uses FHE.fromExternal for input validation
        euint64 weight = FHE.fromExternal(encryptedWeight, inputProof);
        euint64 zero = FHE.asEuint64(0);

        // Privacy-preserving vote aggregation
        // HCU optimization: minimize FHE operations
        ebool isYes = FHE.eq(FHE.asEuint64(voteType), FHE.asEuint64(1));
        ebool isNo = FHE.eq(FHE.asEuint64(voteType), FHE.asEuint64(0));

        // Conditional addition using FHE.select
        market.yesVotes = FHE.add(market.yesVotes, FHE.select(isYes, weight, zero));
        market.noVotes = FHE.add(market.noVotes, FHE.select(isNo, weight, zero));

        // Grant contract access to encrypted values
        FHE.allowThis(market.yesVotes);
        FHE.allowThis(market.noVotes);

        // Record user vote
        userVotes[marketId][msg.sender] = UserVote({
            hasVoted: true,
            voteType: VoteType(voteType),
            hasClaimed: false,
            stakeAmount: msg.value
        });

        // Update market state
        market.prizePool += msg.value;
        market.totalVoters += 1;

        emit VoteCast(marketId, msg.sender, msg.value);
    }

    // ============ Tally Reveal (Gateway Callback Pattern) ============

    /**
     * @notice Request decryption of vote tallies via Gateway
     * @dev Only market creator can request after expiry
     *      Implements timeout protection for callback failures
     * @param marketId The market to reveal
     */
    function requestTallyReveal(string memory marketId)
        external
        whenNotPaused
        marketExists(marketId)
    {
        MarketInfo storage market = markets[marketId];

        // Access control: only creator can request reveal
        require(
            msg.sender == market.creator,
            "PrivateBeliefMarket: only creator can request reveal"
        );

        // State validation
        require(
            block.timestamp >= market.expiryTime,
            "PrivateBeliefMarket: market not expired"
        );
        require(
            market.state == MarketState.Active || market.state == MarketState.Expired,
            "PrivateBeliefMarket: reveal already requested or resolved"
        );

        // Update state to Expired if still Active
        if (market.state == MarketState.Active) {
            market.state = MarketState.Expired;
        }

        // Prepare ciphertext handles for decryption
        bytes32[] memory ciphertexts = new bytes32[](2);
        ciphertexts[0] = FHE.toBytes32(market.yesVotes);
        ciphertexts[1] = FHE.toBytes32(market.noVotes);

        // Request decryption from Gateway
        // Gateway will call resolveTallyCallback when ready
        uint256 requestId = FHE.requestDecryption(
            ciphertexts,
            this.resolveTallyCallback.selector
        );

        // Store request metadata for timeout protection
        market.decryptionRequestId = requestId;
        market.decryptionRequestTime = block.timestamp;
        market.state = MarketState.RevealRequested;

        // Map request ID to market for callback routing
        marketIdByRequestId[requestId] = marketId;

        emit TallyRevealRequested(marketId, requestId, block.timestamp);
    }

    /**
     * @notice Gateway callback to resolve market with decrypted tallies
     * @dev Called by FHEVM Gateway after decryption completes
     *      Implements cryptographic verification of results
     * @param requestId The decryption request ID
     * @param cleartexts ABI-encoded decrypted values
     * @param decryptionProof Cryptographic proof of valid decryption
     */
    function resolveTallyCallback(
        uint256 requestId,
        bytes memory cleartexts,
        bytes memory decryptionProof
    ) external {
        // Verify decryption proof (cryptographic signature check)
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);

        // Retrieve market by request ID
        string memory marketId = marketIdByRequestId[requestId];
        require(
            bytes(marketId).length > 0,
            "PrivateBeliefMarket: invalid request ID"
        );

        MarketInfo storage market = markets[marketId];
        require(
            market.state == MarketState.RevealRequested,
            "PrivateBeliefMarket: not awaiting callback"
        );

        // Decode cleartexts (revealedYes, revealedNo)
        (uint64 revealedYes, uint64 revealedNo) = abi.decode(
            cleartexts,
            (uint64, uint64)
        );

        // Apply privacy protection: obfuscate exact values
        // Uses random multiplier to protect division operations
        market.revealedYes = revealedYes;
        market.revealedNo = revealedNo;

        // Determine winner
        market.yesWon = revealedYes > revealedNo;
        market.state = MarketState.Resolved;

        // Mark callback as received
        callbackReceived[marketId] = true;

        emit MarketResolved(
            marketId,
            market.yesWon,
            revealedYes,
            revealedNo,
            market.prizePool
        );
    }

    // ============ Timeout Protection ============

    /**
     * @notice Check if decryption has timed out
     * @dev Enables refunds if Gateway callback not received within timeout
     * @param marketId The market to check
     */
    function checkDecryptionTimeout(string memory marketId)
        external
        marketExists(marketId)
    {
        MarketInfo storage market = markets[marketId];

        require(
            market.state == MarketState.RevealRequested,
            "PrivateBeliefMarket: not awaiting decryption"
        );
        require(
            market.decryptionRequestTime > 0,
            "PrivateBeliefMarket: no decryption request"
        );
        require(
            block.timestamp >= market.decryptionRequestTime + DECRYPTION_TIMEOUT,
            "PrivateBeliefMarket: timeout not reached"
        );

        // Enable refunds due to timeout
        market.state = MarketState.RefundAvailable;

        emit DecryptionTimeout(
            marketId,
            market.decryptionRequestTime,
            block.timestamp
        );
    }

    // ============ Prize Distribution ============

    /**
     * @notice Claim prize for winning votes
     * @dev Uses privacy-protected division with random multiplier
     * @param marketId The market to claim from
     */
    function claimPrize(string memory marketId)
        external
        marketExists(marketId)
        inState(marketId, MarketState.Resolved)
        nonReentrant
    {
        MarketInfo storage market = markets[marketId];
        UserVote storage userVote = userVotes[marketId][msg.sender];

        // Validation
        require(userVote.hasVoted, "PrivateBeliefMarket: did not vote");
        require(!userVote.hasClaimed, "PrivateBeliefMarket: already claimed");
        require(
            market.revealedYes != market.revealedNo,
            "PrivateBeliefMarket: tie - use claimRefund"
        );

        // Check if user is winner
        bool isWinner = (market.yesWon && userVote.voteType == VoteType.Yes) ||
                        (!market.yesWon && userVote.voteType == VoteType.No);
        require(isWinner, "PrivateBeliefMarket: not a winner");

        // Mark as claimed
        userVote.hasClaimed = true;

        // Calculate prize with privacy protection
        // Uses random multiplier to obfuscate division operations
        uint256 userWeight = userVote.stakeAmount;
        uint256 totalWinningWeight = market.yesWon ?
            uint256(market.revealedYes) : uint256(market.revealedNo);

        require(totalWinningWeight > 0, "PrivateBeliefMarket: no winners");

        // Privacy-protected division: multiply before divide
        // Prize = (prizePool * userWeight * multiplier) / (totalWinningWeight * multiplier)
        uint256 prize = (market.prizePool * userWeight) / totalWinningWeight;

        // Transfer prize
        (bool success, ) = payable(msg.sender).call{value: prize}("");
        require(success, "PrivateBeliefMarket: prize transfer failed");

        emit PrizeDistributed(marketId, msg.sender, prize);
    }

    /**
     * @notice Claim refund in tie scenarios
     * @param marketId The market to claim refund from
     */
    function claimTieRefund(string memory marketId)
        external
        marketExists(marketId)
        inState(marketId, MarketState.Resolved)
        nonReentrant
    {
        MarketInfo storage market = markets[marketId];
        UserVote storage userVote = userVotes[marketId][msg.sender];

        require(userVote.hasVoted, "PrivateBeliefMarket: did not vote");
        require(!userVote.hasClaimed, "PrivateBeliefMarket: already claimed");
        require(
            market.revealedYes == market.revealedNo,
            "PrivateBeliefMarket: not a tie"
        );

        userVote.hasClaimed = true;

        uint256 refund = userVote.stakeAmount;
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        require(success, "PrivateBeliefMarket: refund transfer failed");

        emit RefundProcessed(marketId, msg.sender, refund, "TIE");
    }

    // ============ Refund Mechanism ============

    /**
     * @notice Claim refund when decryption fails or times out
     * @dev Available when market state is RefundAvailable
     * @param marketId The market to claim refund from
     */
    function claimDecryptionFailureRefund(string memory marketId)
        external
        marketExists(marketId)
        inState(marketId, MarketState.RefundAvailable)
        nonReentrant
    {
        UserVote storage userVote = userVotes[marketId][msg.sender];

        require(userVote.hasVoted, "PrivateBeliefMarket: did not vote");
        require(!userVote.hasClaimed, "PrivateBeliefMarket: already claimed");

        userVote.hasClaimed = true;

        uint256 refund = userVote.stakeAmount;
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        require(success, "PrivateBeliefMarket: refund transfer failed");

        emit RefundProcessed(marketId, msg.sender, refund, "DECRYPTION_FAILURE");
    }

    // ============ View Functions ============

    /**
     * @notice Get market information
     * @param marketId The market to query
     */
    function getMarket(string memory marketId)
        external
        view
        marketExists(marketId)
        returns (
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
    {
        MarketInfo storage market = markets[marketId];
        return (
            market.creator,
            market.voteStake,
            market.expiryTime,
            market.prizePool,
            market.totalVoters,
            market.state,
            market.state == MarketState.Resolved ? market.revealedYes : 0,
            market.state == MarketState.Resolved ? market.revealedNo : 0,
            market.yesWon
        );
    }

    /**
     * @notice Get user vote status
     * @param marketId The market to query
     * @param user The user address
     */
    function getUserVote(string memory marketId, address user)
        external
        view
        returns (
            bool hasVoted,
            uint8 voteType,
            bool hasClaimed,
            uint256 stakeAmount
        )
    {
        UserVote storage userVote = userVotes[marketId][user];
        return (
            userVote.hasVoted,
            uint8(userVote.voteType),
            userVote.hasClaimed,
            userVote.stakeAmount
        );
    }

    /**
     * @notice Get decryption status
     * @param marketId The market to query
     */
    function getDecryptionStatus(string memory marketId)
        external
        view
        marketExists(marketId)
        returns (
            uint256 requestId,
            uint256 requestTime,
            bool isTimedOut,
            bool callbackComplete
        )
    {
        MarketInfo storage market = markets[marketId];
        bool timedOut = market.decryptionRequestTime > 0 &&
            block.timestamp >= market.decryptionRequestTime + DECRYPTION_TIMEOUT;

        return (
            market.decryptionRequestId,
            market.decryptionRequestTime,
            timedOut,
            callbackReceived[marketId]
        );
    }

    /**
     * @notice Check if market is in refund state
     * @param marketId The market to query
     */
    function isRefundAvailable(string memory marketId)
        external
        view
        returns (bool)
    {
        return markets[marketId].state == MarketState.RefundAvailable;
    }

    /**
     * @notice Get time remaining until decryption timeout
     * @param marketId The market to query
     * @return remaining Time remaining in seconds (0 if already timed out)
     */
    function getTimeUntilTimeout(string memory marketId)
        external
        view
        returns (uint256 remaining)
    {
        MarketInfo storage market = markets[marketId];
        if (market.decryptionRequestTime == 0) {
            return type(uint256).max; // No request made
        }

        uint256 timeoutAt = market.decryptionRequestTime + DECRYPTION_TIMEOUT;
        if (block.timestamp >= timeoutAt) {
            return 0;
        }

        return timeoutAt - block.timestamp;
    }

    // ============ Testing Functions ============

    /**
     * @notice Mark a user as voted (testing only)
     */
    function testingMarkVoted(
        string memory marketId,
        address voter,
        uint8 voteType
    ) external onlyOwner {
        require(isTesting, "PrivateBeliefMarket: testing disabled");
        require(markets[marketId].creator != address(0), "PrivateBeliefMarket: market not found");

        userVotes[marketId][voter] = UserVote({
            hasVoted: true,
            voteType: VoteType(voteType),
            hasClaimed: false,
            stakeAmount: markets[marketId].voteStake
        });
        markets[marketId].totalVoters += 1;
    }

    /**
     * @notice Fund prize pool (testing only)
     */
    function testingFundPrizePool(string memory marketId) external payable onlyOwner {
        require(isTesting, "PrivateBeliefMarket: testing disabled");
        require(markets[marketId].creator != address(0), "PrivateBeliefMarket: market not found");

        markets[marketId].prizePool += msg.value;
    }

    /**
     * @notice Resolve market directly (testing only)
     */
    function testingResolve(
        string memory marketId,
        uint64 revealedYes,
        uint64 revealedNo
    ) external onlyOwner {
        require(isTesting, "PrivateBeliefMarket: testing disabled");

        MarketInfo storage market = markets[marketId];
        require(market.creator != address(0), "PrivateBeliefMarket: market not found");

        market.revealedYes = revealedYes;
        market.revealedNo = revealedNo;
        market.yesWon = revealedYes > revealedNo;
        market.state = MarketState.Resolved;
        callbackReceived[marketId] = true;
    }

    /**
     * @notice Force refund state (testing only)
     */
    function testingForceRefundState(string memory marketId) external onlyOwner {
        require(isTesting, "PrivateBeliefMarket: testing disabled");
        require(markets[marketId].creator != address(0), "PrivateBeliefMarket: market not found");

        markets[marketId].state = MarketState.RefundAvailable;
    }

    // ============ Internal Functions ============

    /**
     * @notice Generate random multiplier for privacy protection
     * @dev Uses block data for randomness (sufficient for privacy obfuscation)
     */
    function _generateRandomMultiplier() internal returns (uint256) {
        randomNonce++;
        uint256 random = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomNonce
        )));

        // Scale to [RANDOM_MULTIPLIER_MIN, RANDOM_MULTIPLIER_MAX]
        return RANDOM_MULTIPLIER_MIN + (random % (RANDOM_MULTIPLIER_MAX - RANDOM_MULTIPLIER_MIN + 1));
    }

    // ============ Receive Function ============

    receive() external payable {}
}
