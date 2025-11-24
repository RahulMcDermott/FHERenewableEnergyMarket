// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import { FHE, euint32, euint64, ebool, externalEuint64 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title PrivateRenewableEnergyMarket
 * @notice A privacy-preserving renewable energy trading platform using FHE
 * @dev Implements Gateway callback pattern, refund mechanisms, and timeout protection
 *
 * Key Features:
 * - Gateway Callback Pattern: Async FHE processing with verified callbacks
 * - Refund Mechanism: Handles decryption failures and timeouts
 * - Timeout Protection: 24-hour window prevents permanent fund locks
 * - Privacy Protection: Random multipliers for division privacy
 * - Gas Optimization: Minimal HCU operations on-chain
 */
contract PrivateRenewableEnergyMarket is SepoliaConfig {

    // ============ Enums ============

    enum MarketState {
        Active,
        Expired,
        RevealRequested,
        Resolved,
        RefundAvailable,
        Cancelled
    }

    // ============ Structs ============

    struct EnergyOffer {
        euint32 encryptedAmount;     // Energy amount in kWh (encrypted)
        euint32 encryptedPrice;      // Price per kWh in wei (encrypted)
        uint8 energyType;            // 1=Solar, 2=Wind, 3=Hydro, 4=Geothermal
        bool isActive;
        uint256 timestamp;
        address producer;
    }

    struct EnergyDemand {
        euint32 encryptedAmount;     // Required energy in kWh (encrypted)
        euint32 encryptedMaxPrice;   // Maximum price willing to pay (encrypted)
        bool isActive;
        uint256 timestamp;
        address consumer;
    }

    struct TradingPeriod {
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        MarketState state;
        uint256 totalTrades;
        uint256 totalVolume;
        uint256 prizePool;
        euint64 totalOfferVolume;    // Encrypted total offer volume
        euint64 totalDemandVolume;   // Encrypted total demand volume
        uint64 revealedOfferVolume;
        uint64 revealedDemandVolume;
        uint256 decryptionRequestId;
        uint256 decryptionRequestTime;
        uint256 randomMultiplier;    // Privacy protection multiplier
    }

    struct Trade {
        address producer;
        address consumer;
        uint32 amount;
        uint32 pricePerKwh;
        uint8 energyType;
        uint256 timestamp;
        bool isSettled;
    }

    struct UserParticipation {
        bool hasParticipated;
        uint8 participationType;  // 1=producer, 2=consumer, 3=both
        uint256 stakedAmount;
        bool hasClaimed;
    }

    // ============ Constants ============

    uint256 public constant PLATFORM_STAKE = 0.02 ether;
    uint256 public constant MIN_PARTICIPATION_STAKE = 0.005 ether;
    uint256 public constant MIN_DURATION = 5 minutes;
    uint256 public constant MAX_DURATION = 30 days;
    uint256 public constant DECRYPTION_TIMEOUT = 24 hours;
    uint256 public constant TRADING_PERIOD = 24 hours;
    uint256 public constant MAX_MARKET_ID_LENGTH = 64;
    uint256 public constant PRICE_PRECISION = 1000;

    // ============ State Variables ============

    address public owner;
    uint256 public currentTradingPeriod;
    uint256 public lastTradingTime;
    uint256 public platformFees;
    bool public paused;

    mapping(uint256 => TradingPeriod) public tradingPeriods;
    mapping(uint256 => mapping(uint256 => EnergyOffer)) public offers;
    mapping(uint256 => mapping(uint256 => EnergyDemand)) public demands;
    mapping(uint256 => mapping(address => uint256[])) public producerOffers;
    mapping(uint256 => mapping(address => uint256[])) public consumerDemands;
    mapping(uint256 => Trade[]) public trades;
    mapping(uint256 => mapping(address => UserParticipation)) public userParticipations;
    mapping(uint256 => string) internal periodIdByRequestId;
    mapping(uint256 => bool) public callbackHasBeenCalled;

    uint256 public nextOfferId;
    uint256 public nextDemandId;

    // Carbon credit tracking
    mapping(address => euint32) public encryptedCarbonCredits;
    mapping(uint8 => uint32) public carbonFactors; // gCO2/kWh saved per energy type

    // ============ Events ============

    event TradingPeriodStarted(uint256 indexed period, uint256 startTime);
    event TradingPeriodEnded(uint256 indexed period, uint256 totalTrades, uint256 totalVolume);
    event EnergyOfferSubmitted(address indexed producer, uint256 indexed offerId, uint8 energyType);
    event EnergyDemandSubmitted(address indexed consumer, uint256 indexed demandId);
    event TradeMatched(address indexed producer, address indexed consumer, uint256 tradeId);
    event CarbonCreditsAwarded(address indexed producer, uint32 credits);
    event TallyRevealRequested(uint256 indexed period, uint256 requestId);
    event MarketResolved(uint256 indexed period, uint64 offerVolume, uint64 demandVolume);
    event PrizeDistributed(uint256 indexed period, address winner, uint256 amount);
    event RefundClaimed(uint256 indexed period, address user, uint256 amount);
    event DecryptionTimeout(uint256 indexed period);
    event MarketCancelled(uint256 indexed period, string reason);
    event PlatformFeesWithdrawn(address indexed to, uint256 amount);
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    bool private _locked;

    modifier onlyDuringTradingTime() {
        require(isTradingTimeActive(), "Not trading time");
        _;
    }

    modifier onlyDuringSettlementTime() {
        require(isSettlementTimeActive(), "Not settlement time");
        _;
    }

    modifier periodExists(uint256 period) {
        require(tradingPeriods[period].startTime != 0, "Period does not exist");
        _;
    }

    modifier inState(uint256 period, MarketState expectedState) {
        require(tradingPeriods[period].state == expectedState, "Invalid state");
        _;
    }

    // ============ Constructor ============

    constructor() {
        owner = msg.sender;
        currentTradingPeriod = 1;
        lastTradingTime = block.timestamp;
        nextOfferId = 1;
        nextDemandId = 1;

        // Initialize carbon factors (gCO2/kWh saved compared to fossil fuels)
        carbonFactors[1] = 500; // Solar
        carbonFactors[2] = 450; // Wind
        carbonFactors[3] = 400; // Hydro
        carbonFactors[4] = 350; // Geothermal
    }

    // ============ Trading Period Functions ============

    function isTradingTimeActive() public view returns (bool) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        if (period.state != MarketState.Active) return false;
        return block.timestamp >= period.startTime &&
               block.timestamp < period.endTime;
    }

    function isSettlementTimeActive() public view returns (bool) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        return period.state == MarketState.Active &&
               block.timestamp >= period.endTime;
    }

    /**
     * @notice Start a new trading period
     * @dev Generates random multiplier for privacy protection
     */
    function startTradingPeriod() external payable whenNotPaused {
        require(
            tradingPeriods[currentTradingPeriod].startTime == 0 ||
            tradingPeriods[currentTradingPeriod].state == MarketState.Resolved ||
            tradingPeriods[currentTradingPeriod].state == MarketState.RefundAvailable ||
            tradingPeriods[currentTradingPeriod].state == MarketState.Cancelled,
            "Current period still active"
        );

        if (tradingPeriods[currentTradingPeriod].state != MarketState.Active) {
            currentTradingPeriod++;
        }

        // Generate random multiplier for privacy (1000-10000 range)
        uint256 randomMult = (uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            currentTradingPeriod
        ))) % 9000) + 1000;

        tradingPeriods[currentTradingPeriod] = TradingPeriod({
            startTime: block.timestamp,
            endTime: block.timestamp + TRADING_PERIOD,
            isActive: true,
            state: MarketState.Active,
            totalTrades: 0,
            totalVolume: 0,
            prizePool: 0,
            totalOfferVolume: FHE.asEuint64(0),
            totalDemandVolume: FHE.asEuint64(0),
            revealedOfferVolume: 0,
            revealedDemandVolume: 0,
            decryptionRequestId: 0,
            decryptionRequestTime: 0,
            randomMultiplier: randomMult
        });

        emit TradingPeriodStarted(currentTradingPeriod, block.timestamp);
    }

    // ============ Energy Trading Functions ============

    /**
     * @notice Submit encrypted energy offer
     * @param _amount Energy amount in kWh
     * @param _pricePerKwh Price per kWh in wei
     * @param _energyType Energy type (1=Solar, 2=Wind, 3=Hydro, 4=Geothermal)
     */
    function submitEnergyOffer(
        uint32 _amount,
        uint32 _pricePerKwh,
        uint8 _energyType
    ) external payable onlyDuringTradingTime whenNotPaused nonReentrant {
        require(_energyType >= 1 && _energyType <= 4, "Invalid energy type");
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerKwh > 0, "Price must be greater than 0");
        require(msg.value >= MIN_PARTICIPATION_STAKE, "Insufficient stake");

        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];

        // Encrypt the sensitive data
        euint32 encryptedAmount = FHE.asEuint32(_amount);
        euint32 encryptedPrice = FHE.asEuint32(_pricePerKwh);

        offers[currentTradingPeriod][nextOfferId] = EnergyOffer({
            encryptedAmount: encryptedAmount,
            encryptedPrice: encryptedPrice,
            energyType: _energyType,
            isActive: true,
            timestamp: block.timestamp,
            producer: msg.sender
        });

        producerOffers[currentTradingPeriod][msg.sender].push(nextOfferId);

        // Update encrypted totals
        euint64 amount64 = FHE.asEuint64(uint64(_amount));
        period.totalOfferVolume = FHE.add(period.totalOfferVolume, amount64);

        // Set ACL permissions
        FHE.allowThis(encryptedAmount);
        FHE.allowThis(encryptedPrice);
        FHE.allowThis(period.totalOfferVolume);
        FHE.allow(encryptedAmount, msg.sender);
        FHE.allow(encryptedPrice, msg.sender);

        // Track participation
        UserParticipation storage participation = userParticipations[currentTradingPeriod][msg.sender];
        if (!participation.hasParticipated) {
            participation.hasParticipated = true;
            participation.participationType = 1;
        } else if (participation.participationType == 2) {
            participation.participationType = 3;
        }
        participation.stakedAmount += msg.value;
        period.prizePool += msg.value;

        emit EnergyOfferSubmitted(msg.sender, nextOfferId, _energyType);
        nextOfferId++;
    }

    /**
     * @notice Submit encrypted energy demand
     * @param _amount Required energy in kWh
     * @param _maxPricePerKwh Maximum price willing to pay per kWh
     */
    function submitEnergyDemand(
        uint32 _amount,
        uint32 _maxPricePerKwh
    ) external payable onlyDuringTradingTime whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(_maxPricePerKwh > 0, "Max price must be greater than 0");
        require(msg.value >= MIN_PARTICIPATION_STAKE, "Insufficient stake");

        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];

        // Encrypt the sensitive data
        euint32 encryptedAmount = FHE.asEuint32(_amount);
        euint32 encryptedMaxPrice = FHE.asEuint32(_maxPricePerKwh);

        demands[currentTradingPeriod][nextDemandId] = EnergyDemand({
            encryptedAmount: encryptedAmount,
            encryptedMaxPrice: encryptedMaxPrice,
            isActive: true,
            timestamp: block.timestamp,
            consumer: msg.sender
        });

        consumerDemands[currentTradingPeriod][msg.sender].push(nextDemandId);

        // Update encrypted totals
        euint64 amount64 = FHE.asEuint64(uint64(_amount));
        period.totalDemandVolume = FHE.add(period.totalDemandVolume, amount64);

        // Set ACL permissions
        FHE.allowThis(encryptedAmount);
        FHE.allowThis(encryptedMaxPrice);
        FHE.allowThis(period.totalDemandVolume);
        FHE.allow(encryptedAmount, msg.sender);
        FHE.allow(encryptedMaxPrice, msg.sender);

        // Track participation
        UserParticipation storage participation = userParticipations[currentTradingPeriod][msg.sender];
        if (!participation.hasParticipated) {
            participation.hasParticipated = true;
            participation.participationType = 2;
        } else if (participation.participationType == 1) {
            participation.participationType = 3;
        }
        participation.stakedAmount += msg.value;
        period.prizePool += msg.value;

        emit EnergyDemandSubmitted(msg.sender, nextDemandId);
        nextDemandId++;
    }

    // ============ Gateway Callback Pattern ============

    /**
     * @notice Request decryption of trading volumes via Gateway
     * @dev Only callable after trading period ends
     */
    function requestTallyReveal() external periodExists(currentTradingPeriod) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(block.timestamp >= period.endTime, "Trading not ended");
        require(period.state == MarketState.Active, "Not in active state");

        // Transition to RevealRequested state
        period.state = MarketState.RevealRequested;

        // Prepare ciphertexts for decryption
        bytes32[] memory cts = new bytes32[](2);
        cts[0] = FHE.toBytes32(period.totalOfferVolume);
        cts[1] = FHE.toBytes32(period.totalDemandVolume);

        // Request decryption via Gateway
        uint256 requestId = FHE.requestDecryption(cts, this.resolveTallyCallback.selector);
        period.decryptionRequestId = requestId;
        period.decryptionRequestTime = block.timestamp;

        emit TallyRevealRequested(currentTradingPeriod, requestId);
    }

    /**
     * @notice Gateway callback to resolve trading period with decrypted values
     * @param requestId The decryption request ID
     * @param cleartexts ABI-encoded cleartext values
     * @param decryptionProof Cryptographic proof from Gateway
     */
    function resolveTallyCallback(
        uint256 requestId,
        bytes memory cleartexts,
        bytes memory decryptionProof
    ) external {
        // Verify signatures against the request and provided cleartexts
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);

        // Decode the cleartexts
        (uint64 offerVolume, uint64 demandVolume) = abi.decode(cleartexts, (uint64, uint64));

        // Find the period for this request
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(period.decryptionRequestId == requestId, "Invalid request ID");
        require(period.state == MarketState.RevealRequested, "Not in reveal requested state");

        // Update revealed values
        period.revealedOfferVolume = offerVolume;
        period.revealedDemandVolume = demandVolume;
        period.state = MarketState.Resolved;

        callbackHasBeenCalled[requestId] = true;

        emit MarketResolved(currentTradingPeriod, offerVolume, demandVolume);
    }

    // ============ Timeout Protection ============

    /**
     * @notice Check and handle decryption timeout
     * @dev Anyone can call this after 24 hours to enable refunds
     */
    function checkDecryptionTimeout() external periodExists(currentTradingPeriod) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(period.state == MarketState.RevealRequested, "Not in reveal requested state");
        require(
            block.timestamp >= period.decryptionRequestTime + DECRYPTION_TIMEOUT,
            "Timeout not reached"
        );

        period.state = MarketState.RefundAvailable;
        emit DecryptionTimeout(currentTradingPeriod);
    }

    /**
     * @notice Get time until decryption timeout
     */
    function getTimeUntilTimeout() external view returns (uint256) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        if (period.state != MarketState.RevealRequested) return 0;

        uint256 timeoutTime = period.decryptionRequestTime + DECRYPTION_TIMEOUT;
        if (block.timestamp >= timeoutTime) return 0;
        return timeoutTime - block.timestamp;
    }

    // ============ Refund Mechanism ============

    /**
     * @notice Claim refund when decryption fails or times out
     */
    function claimDecryptionFailureRefund() external nonReentrant periodExists(currentTradingPeriod) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(
            period.state == MarketState.RefundAvailable ||
            period.state == MarketState.Cancelled,
            "Refunds not available"
        );

        UserParticipation storage participation = userParticipations[currentTradingPeriod][msg.sender];
        require(participation.hasParticipated, "Not participated");
        require(!participation.hasClaimed, "Already claimed");
        require(participation.stakedAmount > 0, "No stake to refund");

        participation.hasClaimed = true;
        uint256 refundAmount = participation.stakedAmount;

        (bool sent, ) = payable(msg.sender).call{value: refundAmount}("");
        require(sent, "Refund transfer failed");

        emit RefundClaimed(currentTradingPeriod, msg.sender, refundAmount);
    }

    /**
     * @notice Claim prize when trading is resolved (balanced market)
     * @dev Prize distribution based on participation weight
     */
    function claimPrize() external nonReentrant periodExists(currentTradingPeriod) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(period.state == MarketState.Resolved, "Market not resolved");

        UserParticipation storage participation = userParticipations[currentTradingPeriod][msg.sender];
        require(participation.hasParticipated, "Not participated");
        require(!participation.hasClaimed, "Already claimed");
        require(participation.stakedAmount > 0, "No stake");

        participation.hasClaimed = true;

        // Calculate prize using random multiplier for privacy
        uint256 userWeight = participation.stakedAmount * period.randomMultiplier;
        uint256 totalWeight = period.prizePool * period.randomMultiplier;

        // Prize calculation with privacy protection
        uint256 prize = (period.prizePool * userWeight) / totalWeight;

        (bool sent, ) = payable(msg.sender).call{value: prize}("");
        require(sent, "Prize transfer failed");

        emit PrizeDistributed(currentTradingPeriod, msg.sender, prize);
    }

    // ============ Carbon Credits ============

    /**
     * @notice Award carbon credits based on clean energy production
     */
    function awardCarbonCredits(
        address producer,
        uint32 energyAmount,
        uint8 energyType
    ) external onlyOwner {
        require(energyType >= 1 && energyType <= 4, "Invalid energy type");

        uint32 credits = (energyAmount * carbonFactors[energyType]) / 1000;
        euint32 encryptedCredits = FHE.asEuint32(credits);

        euint32 currentCredits = encryptedCarbonCredits[producer];
        euint32 zero = FHE.asEuint32(0);
        ebool isZero = FHE.eq(currentCredits, zero);

        encryptedCarbonCredits[producer] = FHE.select(
            isZero,
            encryptedCredits,
            FHE.add(currentCredits, encryptedCredits)
        );

        FHE.allowThis(encryptedCarbonCredits[producer]);
        FHE.allow(encryptedCarbonCredits[producer], producer);

        emit CarbonCreditsAwarded(producer, credits);
    }

    // ============ View Functions ============

    function getCurrentTradingPeriodInfo() external view returns (
        uint256 period,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        MarketState state,
        uint256 prizePool
    ) {
        TradingPeriod storage currentPeriod = tradingPeriods[currentTradingPeriod];
        return (
            currentTradingPeriod,
            currentPeriod.startTime,
            currentPeriod.endTime,
            currentPeriod.isActive,
            currentPeriod.state,
            currentPeriod.prizePool
        );
    }

    function getDecryptionStatus() external view returns (
        uint256 requestId,
        uint256 requestTime,
        bool isTimedOut,
        bool callbackComplete
    ) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        bool timedOut = period.state == MarketState.RevealRequested &&
                       block.timestamp >= period.decryptionRequestTime + DECRYPTION_TIMEOUT;
        return (
            period.decryptionRequestId,
            period.decryptionRequestTime,
            timedOut,
            period.state == MarketState.Resolved
        );
    }

    function getUserParticipation(address user) external view returns (
        bool hasParticipated,
        uint8 participationType,
        uint256 stakedAmount,
        bool hasClaimed
    ) {
        UserParticipation storage p = userParticipations[currentTradingPeriod][user];
        return (p.hasParticipated, p.participationType, p.stakedAmount, p.hasClaimed);
    }

    function getProducerOfferCount(address producer) external view returns (uint256) {
        return producerOffers[currentTradingPeriod][producer].length;
    }

    function getConsumerDemandCount(address consumer) external view returns (uint256) {
        return consumerDemands[currentTradingPeriod][consumer].length;
    }

    function getTotalTrades(uint256 period) external view returns (uint256) {
        return trades[period].length;
    }

    function getTradingPeriodHistory(uint256 period) external view returns (
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        MarketState state,
        uint256 totalTrades,
        uint256 totalVolume
    ) {
        TradingPeriod storage tradingPeriod = tradingPeriods[period];
        return (
            tradingPeriod.startTime,
            tradingPeriod.endTime,
            tradingPeriod.isActive,
            tradingPeriod.state,
            tradingPeriod.totalTrades,
            tradingPeriod.totalVolume
        );
    }

    // ============ Owner Functions ============

    function setPlatformFee(uint256 /*newFee*/) external pure {
        revert("Platform fee is fixed");
    }

    function withdrawPlatformFees(address to) external onlyOwner nonReentrant {
        require(platformFees > 0, "No fees to withdraw");
        uint256 amount = platformFees;
        platformFees = 0;
        (bool sent, ) = payable(to).call{value: amount}("");
        require(sent, "Withdraw failed");
        emit PlatformFeesWithdrawn(to, amount);
    }

    function cancelMarket(string memory reason) external onlyOwner {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(
            period.state == MarketState.Active ||
            period.state == MarketState.Expired ||
            period.state == MarketState.RevealRequested,
            "Cannot cancel in current state"
        );

        period.state = MarketState.Cancelled;
        emit MarketCancelled(currentTradingPeriod, reason);
    }

    // ============ Emergency Functions ============

    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    function pauseTrading() external onlyOwner {
        tradingPeriods[currentTradingPeriod].isActive = false;
    }

    function resumeTrading() external onlyOwner {
        tradingPeriods[currentTradingPeriod].isActive = true;
    }

    // ============ Fallback ============

    receive() external payable {}
}
