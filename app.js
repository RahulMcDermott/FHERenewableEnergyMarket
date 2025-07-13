// Contract Configuration
const CONTRACT_CONFIG = {
    address: "0x57fdac162Da016c5795fA2322ee2BDC5549430D8", // Replace with deployed contract address
    abi: [
        {
            "inputs": [],
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "internalType": "uint32",
                    "name": "credits",
                    "type": "uint32"
                }
            ],
            "name": "CarbonCreditsAwarded",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "consumer",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "uint256",
                    "name": "demandId",
                    "type": "uint256"
                }
            ],
            "name": "EnergyDemandSubmitted",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "uint256",
                    "name": "offerId",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "internalType": "uint8",
                    "name": "energyType",
                    "type": "uint8"
                }
            ],
            "name": "EnergyOfferSubmitted",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "consumer",
                    "type": "address"
                },
                {
                    "indexed": false,
                    "internalType": "uint256",
                    "name": "tradeId",
                    "type": "uint256"
                }
            ],
            "name": "TradeMatched",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "uint256",
                    "name": "period",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "internalType": "uint256",
                    "name": "totalTrades",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "internalType": "uint256",
                    "name": "totalVolume",
                    "type": "uint256"
                }
            ],
            "name": "TradingPeriodEnded",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "uint256",
                    "name": "period",
                    "type": "uint256"
                },
                {
                    "indexed": false,
                    "internalType": "uint256",
                    "name": "startTime",
                    "type": "uint256"
                }
            ],
            "name": "TradingPeriodStarted",
            "type": "event"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                },
                {
                    "internalType": "uint32",
                    "name": "energyAmount",
                    "type": "uint32"
                },
                {
                    "internalType": "uint8",
                    "name": "energyType",
                    "type": "uint8"
                }
            ],
            "name": "awardCarbonCredits",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint8",
                    "name": "",
                    "type": "uint8"
                }
            ],
            "name": "carbonFactors",
            "outputs": [
                {
                    "internalType": "uint32",
                    "name": "",
                    "type": "uint32"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                },
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "consumerDemands",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "currentTradingPeriod",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "demands",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "isActive",
                    "type": "bool"
                },
                {
                    "internalType": "uint256",
                    "name": "timestamp",
                    "type": "uint256"
                },
                {
                    "internalType": "address",
                    "name": "consumer",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "name": "encryptedCarbonCredits",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "consumer",
                    "type": "address"
                }
            ],
            "name": "getConsumerDemandCount",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "getCurrentTradingPeriodInfo",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "period",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "startTime",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "endTime",
                    "type": "uint256"
                },
                {
                    "internalType": "bool",
                    "name": "isActive",
                    "type": "bool"
                },
                {
                    "internalType": "bool",
                    "name": "resultsRevealed",
                    "type": "bool"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                }
            ],
            "name": "getProducerOfferCount",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "period",
                    "type": "uint256"
                }
            ],
            "name": "getTotalTrades",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "period",
                    "type": "uint256"
                }
            ],
            "name": "getTradingPeriodHistory",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "startTime",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "endTime",
                    "type": "uint256"
                },
                {
                    "internalType": "bool",
                    "name": "isActive",
                    "type": "bool"
                },
                {
                    "internalType": "bool",
                    "name": "resultsRevealed",
                    "type": "bool"
                },
                {
                    "internalType": "uint256",
                    "name": "totalTrades",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "totalVolume",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "isSettlementTimeActive",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "isTradingTimeActive",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "lastTradingTime",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "nextDemandId",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "nextOfferId",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "offers",
            "outputs": [
                {
                    "internalType": "uint8",
                    "name": "energyType",
                    "type": "uint8"
                },
                {
                    "internalType": "bool",
                    "name": "isActive",
                    "type": "bool"
                },
                {
                    "internalType": "uint256",
                    "name": "timestamp",
                    "type": "uint256"
                },
                {
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "owner",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "pauseTrading",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                },
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                },
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "producerOffers",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "processTrading",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "resumeTrading",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "startTradingPeriod",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint32",
                    "name": "_amount",
                    "type": "uint32"
                },
                {
                    "internalType": "uint32",
                    "name": "_maxPricePerKwh",
                    "type": "uint32"
                }
            ],
            "name": "submitEnergyDemand",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint32",
                    "name": "_amount",
                    "type": "uint32"
                },
                {
                    "internalType": "uint32",
                    "name": "_pricePerKwh",
                    "type": "uint32"
                },
                {
                    "internalType": "uint8",
                    "name": "_energyType",
                    "type": "uint8"
                }
            ],
            "name": "submitEnergyOffer",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "trades",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "producer",
                    "type": "address"
                },
                {
                    "internalType": "address",
                    "name": "consumer",
                    "type": "address"
                },
                {
                    "internalType": "uint32",
                    "name": "amount",
                    "type": "uint32"
                },
                {
                    "internalType": "uint32",
                    "name": "pricePerKwh",
                    "type": "uint32"
                },
                {
                    "internalType": "uint8",
                    "name": "energyType",
                    "type": "uint8"
                },
                {
                    "internalType": "uint256",
                    "name": "timestamp",
                    "type": "uint256"
                },
                {
                    "internalType": "bool",
                    "name": "isSettled",
                    "type": "bool"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "name": "tradingPeriods",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "startTime",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "endTime",
                    "type": "uint256"
                },
                {
                    "internalType": "bool",
                    "name": "isActive",
                    "type": "bool"
                },
                {
                    "internalType": "bool",
                    "name": "resultsRevealed",
                    "type": "bool"
                },
                {
                    "internalType": "uint256",
                    "name": "totalTrades",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "totalVolume",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        }
    ]
};

// Global variables
let provider = null;
let signer = null;
let contract = null;
let userAccount = null;
let isOwner = false;

// Energy type mapping
const ENERGY_TYPES = {
    1: 'Solar',
    2: 'Wind',
    3: 'Hydro',
    4: 'Geothermal'
};

// Initialize the application
async function init() {
    console.log('Initializing application...');

    // Setup event listeners
    setupEventListeners();

    // Check if contract address is configured
    if (CONTRACT_CONFIG.address === "0x0000000000000000000000000000000000000000") {
        showError("Please configure the contract address in app.js");
        return;
    }

    // Check if MetaMask is installed
    if (typeof window.ethereum === 'undefined') {
        showError("Please install MetaMask to use this application");
        return;
    }

    // Try to connect if previously connected
    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
    if (accounts.length > 0) {
        await connectWallet();
    }
}

// Setup event listeners
function setupEventListeners() {
    document.getElementById('connectWallet').addEventListener('click', connectWallet);
    document.getElementById('startTradingBtn').addEventListener('click', startTradingPeriod);
    document.getElementById('submitOfferBtn').addEventListener('click', submitEnergyOffer);
    document.getElementById('submitDemandBtn').addEventListener('click', submitEnergyDemand);
    document.getElementById('processTrading').addEventListener('click', processTrading);
    document.getElementById('pauseTrading').addEventListener('click', pauseTrading);
    document.getElementById('resumeTrading').addEventListener('click', resumeTrading);

    // Listen for account changes
    if (window.ethereum) {
        window.ethereum.on('accountsChanged', handleAccountsChanged);
        window.ethereum.on('chainChanged', handleChainChanged);
    }
}

// Connect wallet
async function connectWallet() {
    try {
        showTransactionStatus('Connecting to wallet...');

        // Request account access
        const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });

        // Create provider and signer
        provider = new ethers.providers.Web3Provider(window.ethereum);
        signer = provider.getSigner();
        userAccount = accounts[0];

        // Create contract instance
        contract = new ethers.Contract(CONTRACT_CONFIG.address, CONTRACT_CONFIG.abi, signer);

        // Check network
        const network = await provider.getNetwork();
        console.log('Connected to network:', network);

        // Check if user is owner
        try {
            const owner = await contract.owner();
            isOwner = owner.toLowerCase() === userAccount.toLowerCase();
        } catch (error) {
            console.log('Error checking owner:', error);
            isOwner = false;
        }

        // Update UI
        updateWalletUI();
        await updateDashboard();

        hideTransactionStatus();

    } catch (error) {
        console.error('Error connecting wallet:', error);
        showError('Failed to connect wallet: ' + error.message);
        hideTransactionStatus();
    }
}

// Handle account changes
async function handleAccountsChanged(accounts) {
    if (accounts.length === 0) {
        // User disconnected
        resetWalletUI();
    } else {
        // User switched accounts
        await connectWallet();
    }
}

// Handle chain changes
function handleChainChanged() {
    // Reload the page on chain change
    window.location.reload();
}

// Update wallet UI
function updateWalletUI() {
    const connectButton = document.getElementById('connectWallet');
    const walletInfo = document.getElementById('walletInfo');
    const walletAddress = document.getElementById('walletAddress');
    const networkStatus = document.getElementById('networkStatus');
    const ownerControls = document.getElementById('ownerControls');

    connectButton.style.display = 'none';
    walletInfo.classList.remove('hidden');

    // Format address
    const formattedAddress = `${userAccount.substring(0, 6)}...${userAccount.substring(38)}`;
    walletAddress.textContent = formattedAddress;
    networkStatus.textContent = 'Connected';

    // Show owner controls if user is owner
    if (isOwner) {
        ownerControls.style.display = 'block';
    }
}

// Reset wallet UI
function resetWalletUI() {
    const connectButton = document.getElementById('connectWallet');
    const walletInfo = document.getElementById('walletInfo');
    const ownerControls = document.getElementById('ownerControls');

    connectButton.style.display = 'inline-block';
    walletInfo.classList.add('hidden');
    ownerControls.style.display = 'none';

    provider = null;
    signer = null;
    contract = null;
    userAccount = null;
    isOwner = false;
}

// Update dashboard
async function updateDashboard() {
    if (!contract) return;

    try {
        await updateTradingPeriodStatus();
        await updateUserStats();
        await updateMarketStats();
    } catch (error) {
        console.error('Error updating dashboard:', error);
    }
}

// Update trading period status
async function updateTradingPeriodStatus() {
    try {
        const periodInfo = await contract.getCurrentTradingPeriodInfo();
        const [period, startTime, endTime, isActive, resultsRevealed] = periodInfo;

        document.getElementById('currentPeriod').textContent = period.toString();

        const statusElement = document.getElementById('periodStatusText');
        const startTradingBtn = document.getElementById('startTradingBtn');

        if (!isActive || resultsRevealed) {
            statusElement.textContent = 'Inactive';
            statusElement.className = 'status-badge inactive';
            startTradingBtn.classList.remove('hidden');
            document.getElementById('timeRemaining').textContent = 'Not active';
        } else {
            const currentTime = Math.floor(Date.now() / 1000);
            const endTimeNum = endTime.toNumber();

            if (currentTime >= endTimeNum) {
                statusElement.textContent = 'Settlement';
                statusElement.className = 'status-badge settlement';
                document.getElementById('timeRemaining').textContent = 'Settlement phase';
            } else {
                statusElement.textContent = 'Active';
                statusElement.className = 'status-badge active';
                startTradingBtn.classList.add('hidden');

                const timeLeft = endTimeNum - currentTime;
                document.getElementById('timeRemaining').textContent = formatTimeRemaining(timeLeft);
            }
        }
    } catch (error) {
        console.error('Error updating trading period status:', error);
    }
}

// Update user statistics
async function updateUserStats() {
    if (!userAccount) return;

    try {
        const offerCount = await contract.getProducerOfferCount(userAccount);
        const demandCount = await contract.getConsumerDemandCount(userAccount);

        document.getElementById('activeOffers').textContent = offerCount.toString();
        document.getElementById('activeDemands').textContent = demandCount.toString();

    } catch (error) {
        console.error('Error updating user stats:', error);
    }
}

// Update market statistics
async function updateMarketStats() {
    try {
        const currentPeriod = await contract.currentTradingPeriod();
        const totalTrades = await contract.getTotalTrades(currentPeriod);

        document.getElementById('totalTrades').textContent = totalTrades.toString();

        // Note: For encrypted values, we can't display actual numbers
        document.getElementById('totalOffers').textContent = 'Private';
        document.getElementById('totalDemands').textContent = 'Private';
        document.getElementById('carbonCredits').textContent = 'Private';

    } catch (error) {
        console.error('Error updating market stats:', error);
    }
}

// Start trading period
async function startTradingPeriod() {
    if (!contract) {
        showError('Please connect your wallet first');
        return;
    }

    try {
        showTransactionStatus('Starting new trading period...');

        const tx = await contract.startTradingPeriod();
        await tx.wait();

        hideTransactionStatus();
        await updateDashboard();

    } catch (error) {
        console.error('Error starting trading period:', error);
        showError('Failed to start trading period: ' + error.message);
        hideTransactionStatus();
    }
}

// Submit energy offer
async function submitEnergyOffer() {
    if (!contract) {
        showError('Please connect your wallet first');
        return;
    }

    const amount = document.getElementById('energyAmount').value;
    const price = document.getElementById('pricePerKwh').value;
    const energyType = document.getElementById('energyType').value;

    if (!amount || !price || !energyType) {
        showError('Please fill in all fields');
        return;
    }

    // Validate uint32 limits (0 to 4,294,967,295)
    const maxUint32 = 4294967295;
    const amountValue = parseInt(amount);
    const priceValue = parseInt(price);

    if (amountValue <= 0 || amountValue > maxUint32) {
        showError('Energy amount must be between 1 and 4,294,967,295 kWh');
        return;
    }

    if (priceValue <= 0 || priceValue > maxUint32) {
        showError('Price must be between 1 and 4,294,967,295 wei per kWh');
        return;
    }

    try {
        showTransactionStatus('Submitting energy offer...');

        const tx = await contract.submitEnergyOffer(
            amountValue,
            priceValue,
            parseInt(energyType)
        );
        await tx.wait();

        // Clear form
        document.getElementById('energyAmount').value = '';
        document.getElementById('pricePerKwh').value = '';

        hideTransactionStatus();
        await updateDashboard();

    } catch (error) {
        console.error('Error submitting offer:', error);
        showError('Failed to submit offer: ' + error.message);
        hideTransactionStatus();
    }
}

// Submit energy demand
async function submitEnergyDemand() {
    if (!contract) {
        showError('Please connect your wallet first');
        return;
    }

    const amount = document.getElementById('demandAmount').value;
    const maxPrice = document.getElementById('maxPrice').value;

    if (!amount || !maxPrice) {
        showError('Please fill in all fields');
        return;
    }

    // Validate uint32 limits (0 to 4,294,967,295)
    const maxUint32 = 4294967295;
    const amountValue = parseInt(amount);
    const maxPriceValue = parseInt(maxPrice);

    if (amountValue <= 0 || amountValue > maxUint32) {
        showError('Energy amount must be between 1 and 4,294,967,295 kWh');
        return;
    }

    if (maxPriceValue <= 0 || maxPriceValue > maxUint32) {
        showError('Max price must be between 1 and 4,294,967,295 wei per kWh');
        return;
    }

    try {
        showTransactionStatus('Submitting energy demand...');

        const tx = await contract.submitEnergyDemand(
            amountValue,
            maxPriceValue
        );
        await tx.wait();

        // Clear form
        document.getElementById('demandAmount').value = '';
        document.getElementById('maxPrice').value = '';

        hideTransactionStatus();
        await updateDashboard();

    } catch (error) {
        console.error('Error submitting demand:', error);
        showError('Failed to submit demand: ' + error.message);
        hideTransactionStatus();
    }
}

// Process trading (owner only)
async function processTrading() {
    if (!contract || !isOwner) {
        showError('Only the contract owner can process trading');
        return;
    }

    try {
        showTransactionStatus('Processing trading settlement...');

        const tx = await contract.processTrading();
        await tx.wait();

        hideTransactionStatus();
        await updateDashboard();

    } catch (error) {
        console.error('Error processing trading:', error);
        showError('Failed to process trading: ' + error.message);
        hideTransactionStatus();
    }
}

// Pause trading (owner only)
async function pauseTrading() {
    if (!contract || !isOwner) {
        showError('Only the contract owner can pause trading');
        return;
    }

    try {
        showTransactionStatus('Pausing trading...');

        const tx = await contract.pauseTrading();
        await tx.wait();

        hideTransactionStatus();
        await updateDashboard();

    } catch (error) {
        console.error('Error pausing trading:', error);
        showError('Failed to pause trading: ' + error.message);
        hideTransactionStatus();
    }
}

// Resume trading (owner only)
async function resumeTrading() {
    if (!contract || !isOwner) {
        showError('Only the contract owner can resume trading');
        return;
    }

    try {
        showTransactionStatus('Resuming trading...');

        const tx = await contract.resumeTrading();
        await tx.wait();

        hideTransactionStatus();
        await updateDashboard();

    } catch (error) {
        console.error('Error resuming trading:', error);
        showError('Failed to resume trading: ' + error.message);
        hideTransactionStatus();
    }
}

// Utility functions
function formatTimeRemaining(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    return `${hours}h ${minutes}m ${secs}s`;
}

function showTransactionStatus(message) {
    const statusDiv = document.getElementById('transactionStatus');
    const messageSpan = document.getElementById('transactionMessage');

    messageSpan.textContent = message;
    statusDiv.classList.remove('hidden');
}

function hideTransactionStatus() {
    const statusDiv = document.getElementById('transactionStatus');
    statusDiv.classList.add('hidden');
}

function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    const errorText = document.getElementById('errorText');

    errorText.textContent = message;
    errorDiv.classList.remove('hidden');

    // Auto-hide after 5 seconds
    setTimeout(() => {
        hideError();
    }, 5000);
}

function hideError() {
    const errorDiv = document.getElementById('errorMessage');
    errorDiv.classList.add('hidden');
}

// Auto-refresh dashboard every 30 seconds
setInterval(() => {
    if (contract) {
        updateDashboard();
    }
}, 30000);

// Initialize when page loads
document.addEventListener('DOMContentLoaded', init);