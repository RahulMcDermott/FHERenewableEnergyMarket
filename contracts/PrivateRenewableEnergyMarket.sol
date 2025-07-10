// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint64, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivateRenewableEnergyMarket is SepoliaConfig {

    address public owner;
    uint256 public currentTradingPeriod;
    uint256 public lastTradingTime;

    // Trading period duration (24 hours in seconds)
    uint256 constant TRADING_PERIOD = 86400;

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
        bool resultsRevealed;
        uint256 totalTrades;
        uint256 totalVolume;
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

    mapping(uint256 => TradingPeriod) public tradingPeriods;
    mapping(uint256 => mapping(uint256 => EnergyOffer)) public offers;
    mapping(uint256 => mapping(uint256 => EnergyDemand)) public demands;
    mapping(uint256 => mapping(address => uint256[])) public producerOffers;
    mapping(uint256 => mapping(address => uint256[])) public consumerDemands;
    mapping(uint256 => Trade[]) public trades;

    uint256 public nextOfferId;
    uint256 public nextDemandId;

    // Carbon credit tracking
    mapping(address => euint32) public encryptedCarbonCredits;
    mapping(uint8 => uint32) public carbonFactors; // gCO2/kWh saved per energy type

    event TradingPeriodStarted(uint256 indexed period, uint256 startTime);
    event EnergyOfferSubmitted(address indexed producer, uint256 indexed offerId, uint8 energyType);
    event EnergyDemandSubmitted(address indexed consumer, uint256 indexed demandId);
    event TradeMatched(address indexed producer, address indexed consumer, uint256 tradeId);
    event TradingPeriodEnded(uint256 indexed period, uint256 totalTrades, uint256 totalVolume);
    event CarbonCreditsAwarded(address indexed producer, uint32 credits);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyDuringTradingTime() {
        require(isTradingTimeActive(), "Not trading time");
        _;
    }

    modifier onlyDuringSettlementTime() {
        require(isSettlementTimeActive(), "Not settlement time");
        _;
    }

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

    function isTradingTimeActive() public view returns (bool) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        if (!period.isActive) return false;
        return block.timestamp >= period.startTime &&
               block.timestamp < period.endTime &&
               !period.resultsRevealed;
    }

    function isSettlementTimeActive() public view returns (bool) {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        return period.isActive &&
               block.timestamp >= period.endTime &&
               !period.resultsRevealed;
    }

    // Start a new trading period
    function startTradingPeriod() external {
        require(
            !tradingPeriods[currentTradingPeriod].isActive ||
            tradingPeriods[currentTradingPeriod].resultsRevealed,
            "Current period still active"
        );

        tradingPeriods[currentTradingPeriod] = TradingPeriod({
            startTime: block.timestamp,
            endTime: block.timestamp + TRADING_PERIOD,
            isActive: true,
            resultsRevealed: false,
            totalTrades: 0,
            totalVolume: 0
        });

        emit TradingPeriodStarted(currentTradingPeriod, block.timestamp);
    }

    // Submit encrypted energy offer
    function submitEnergyOffer(
        uint32 _amount,
        uint32 _pricePerKwh,
        uint8 _energyType
    ) external onlyDuringTradingTime {
        require(_energyType >= 1 && _energyType <= 4, "Invalid energy type");
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerKwh > 0, "Price must be greater than 0");

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

        // Set ACL permissions
        FHE.allowThis(encryptedAmount);
        FHE.allowThis(encryptedPrice);
        FHE.allow(encryptedAmount, msg.sender);
        FHE.allow(encryptedPrice, msg.sender);

        emit EnergyOfferSubmitted(msg.sender, nextOfferId, _energyType);
        nextOfferId++;
    }

    // Submit encrypted energy demand
    function submitEnergyDemand(
        uint32 _amount,
        uint32 _maxPricePerKwh
    ) external onlyDuringTradingTime {
        require(_amount > 0, "Amount must be greater than 0");
        require(_maxPricePerKwh > 0, "Max price must be greater than 0");

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

        // Set ACL permissions
        FHE.allowThis(encryptedAmount);
        FHE.allowThis(encryptedMaxPrice);
        FHE.allow(encryptedAmount, msg.sender);
        FHE.allow(encryptedMaxPrice, msg.sender);

        emit EnergyDemandSubmitted(msg.sender, nextDemandId);
        nextDemandId++;
    }

    // Process trading settlement (simplified version)
    function processTrading() external onlyDuringSettlementTime onlyOwner {
        TradingPeriod storage period = tradingPeriods[currentTradingPeriod];
        require(!period.resultsRevealed, "Trading already processed");

        // In a real implementation, this would use FHE operations to match
        // offers and demands privately. For this example, we'll use a simple approach.

        // Mark period as processed
        period.resultsRevealed = true;

        emit TradingPeriodEnded(
            currentTradingPeriod,
            period.totalTrades,
            period.totalVolume
        );

        // Move to next trading period
        currentTradingPeriod++;
    }

    // Award carbon credits based on clean energy production
    function awardCarbonCredits(address producer, uint32 energyAmount, uint8 energyType)
        external onlyOwner {
        require(energyType >= 1 && energyType <= 4, "Invalid energy type");

        uint32 credits = (energyAmount * carbonFactors[energyType]) / 1000; // Convert to tons CO2
        euint32 encryptedCredits = FHE.asEuint32(credits);

        // Add to existing credits
        euint32 currentCredits = encryptedCarbonCredits[producer];
        // Use FHE operations to safely add credits
        euint32 zero = FHE.asEuint32(0);
        ebool isZero = FHE.eq(currentCredits, zero);

        // Use conditional selection instead of decrypt
        encryptedCarbonCredits[producer] = FHE.select(
            isZero,
            encryptedCredits,
            FHE.add(currentCredits, encryptedCredits)
        );

        FHE.allowThis(encryptedCarbonCredits[producer]);
        FHE.allow(encryptedCarbonCredits[producer], producer);

        emit CarbonCreditsAwarded(producer, credits);
    }

    // Get current trading period info
    function getCurrentTradingPeriodInfo() external view returns (
        uint256 period,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool resultsRevealed
    ) {
        TradingPeriod storage currentPeriod = tradingPeriods[currentTradingPeriod];
        return (
            currentTradingPeriod,
            currentPeriod.startTime,
            currentPeriod.endTime,
            currentPeriod.isActive,
            currentPeriod.resultsRevealed
        );
    }

    // Get producer's offer count for current period
    function getProducerOfferCount(address producer) external view returns (uint256) {
        return producerOffers[currentTradingPeriod][producer].length;
    }

    // Get consumer's demand count for current period
    function getConsumerDemandCount(address consumer) external view returns (uint256) {
        return consumerDemands[currentTradingPeriod][consumer].length;
    }

    // Get total trades count for a period
    function getTotalTrades(uint256 period) external view returns (uint256) {
        return trades[period].length;
    }

    // Get trading period history
    function getTradingPeriodHistory(uint256 period) external view returns (
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool resultsRevealed,
        uint256 totalTrades,
        uint256 totalVolume
    ) {
        TradingPeriod storage tradingPeriod = tradingPeriods[period];
        return (
            tradingPeriod.startTime,
            tradingPeriod.endTime,
            tradingPeriod.isActive,
            tradingPeriod.resultsRevealed,
            tradingPeriod.totalTrades,
            tradingPeriod.totalVolume
        );
    }

    // Emergency functions
    function pauseTrading() external onlyOwner {
        tradingPeriods[currentTradingPeriod].isActive = false;
    }

    function resumeTrading() external onlyOwner {
        tradingPeriods[currentTradingPeriod].isActive = true;
    }
}