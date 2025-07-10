const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("PrivateRenewableEnergyMarket - Sepolia Integration", function () {
  let contract;
  let contractAddress;
  let deployer;
  let step, steps;

  function progress(message) {
    console.log(`  ${++step}/${steps} ${message}`);
  }

  before(async function () {
    // Only run on Sepolia testnet
    if (network.name !== "sepolia") {
      console.warn("⚠️  This test suite can only run on Sepolia testnet");
      console.warn(`   Current network: ${network.name}`);
      console.warn("   Run: npx hardhat test --network sepolia");
      this.skip();
    }

    console.log(`\n🌐 Running on network: ${network.name}`);

    // Get signers
    const signers = await ethers.getSigners();
    deployer = signers[0];

    console.log(`👤 Deployer: ${deployer.address}`);

    // Try to load contract address from deployment files
    try {
      const deploymentFile = path.join(
        __dirname,
        "..",
        "deployments",
        `latest-${network.name}.json`
      );

      if (fs.existsSync(deploymentFile)) {
        const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
        contractAddress = deploymentInfo.contractAddress;
        console.log(`📄 Loaded contract from deployment file`);
        console.log(`📍 Contract: ${contractAddress}`);
      } else if (process.env.CONTRACT_ADDRESS) {
        contractAddress = process.env.CONTRACT_ADDRESS;
        console.log(`📄 Loaded contract from environment variable`);
        console.log(`📍 Contract: ${contractAddress}`);
      } else {
        throw new Error(
          "Contract address not found. Please deploy first: npm run deploy"
        );
      }

      // Get contract instance
      contract = await ethers.getContractAt(
        "PrivateRenewableEnergyMarket",
        contractAddress
      );

      // Verify contract is deployed
      const code = await ethers.provider.getCode(contractAddress);
      if (code === "0x") {
        throw new Error(`No contract found at address: ${contractAddress}`);
      }

      console.log(`✅ Contract connected successfully\n`);
    } catch (error) {
      console.error(`\n❌ Error loading contract: ${error.message}\n`);
      throw error;
    }
  });

  beforeEach(function () {
    step = 0;
    steps = 0;
  });

  describe("Contract Verification", function () {
    it("should be deployed and accessible", async function () {
      steps = 2;
      this.timeout(60000); // 60 seconds

      progress("Checking contract address...");
      expect(contractAddress).to.be.properAddress;

      progress("Verifying contract code...");
      const code = await ethers.provider.getCode(contractAddress);
      expect(code).to.not.equal("0x");
    });

    it("should have correct owner", async function () {
      steps = 1;
      this.timeout(30000);

      progress("Fetching owner address...");
      const owner = await contract.owner();
      expect(owner).to.be.properAddress;
      console.log(`      Owner: ${owner}`);
    });

    it("should have initialized state", async function () {
      steps = 3;
      this.timeout(60000);

      progress("Checking current trading period...");
      const currentPeriod = await contract.currentTradingPeriod();
      expect(currentPeriod).to.be.gte(1n);

      progress("Checking next offer ID...");
      const nextOfferId = await contract.nextOfferId();
      expect(nextOfferId).to.be.gte(1n);

      progress("Checking next demand ID...");
      const nextDemandId = await contract.nextDemandId();
      expect(nextDemandId).to.be.gte(1n);
    });
  });

  describe("View Functions", function () {
    it("should return trading period information", async function () {
      steps = 2;
      this.timeout(60000);

      progress("Fetching current period info...");
      const periodInfo = await contract.getCurrentTradingPeriodInfo();

      progress("Validating period data...");
      expect(periodInfo[0]).to.be.gte(1n); // period number
      console.log(`      Period: ${periodInfo[0]}`);
      console.log(`      Active: ${periodInfo[3]}`);
      console.log(`      Results Revealed: ${periodInfo[4]}`);
    });

    it("should return carbon factors", async function () {
      steps = 4;
      this.timeout(60000);

      progress("Checking Solar carbon factor...");
      const solar = await contract.carbonFactors(1);
      expect(solar).to.equal(500);

      progress("Checking Wind carbon factor...");
      const wind = await contract.carbonFactors(2);
      expect(wind).to.equal(450);

      progress("Checking Hydro carbon factor...");
      const hydro = await contract.carbonFactors(3);
      expect(hydro).to.equal(400);

      progress("Checking Geothermal carbon factor...");
      const geothermal = await contract.carbonFactors(4);
      expect(geothermal).to.equal(350);
    });

    it("should return trading time status", async function () {
      steps = 2;
      this.timeout(60000);

      progress("Checking if trading time is active...");
      const isTradingActive = await contract.isTradingTimeActive();
      console.log(`      Trading Active: ${isTradingActive}`);

      progress("Checking if settlement time is active...");
      const isSettlementActive = await contract.isSettlementTimeActive();
      console.log(`      Settlement Active: ${isSettlementActive}`);

      expect(typeof isTradingActive).to.equal("boolean");
      expect(typeof isSettlementActive).to.equal("boolean");
    });

    it("should return producer offer count", async function () {
      steps = 1;
      this.timeout(30000);

      progress("Fetching offer count...");
      const offerCount = await contract.getProducerOfferCount(deployer.address);
      expect(offerCount).to.be.gte(0n);
      console.log(`      Offer Count: ${offerCount}`);
    });

    it("should return consumer demand count", async function () {
      steps = 1;
      this.timeout(30000);

      progress("Fetching demand count...");
      const demandCount = await contract.getConsumerDemandCount(deployer.address);
      expect(demandCount).to.be.gte(0n);
      console.log(`      Demand Count: ${demandCount}`);
    });
  });

  describe("State Queries", function () {
    it("should fetch trading period history", async function () {
      steps = 2;
      this.timeout(60000);

      progress("Getting current period number...");
      const currentPeriod = await contract.currentTradingPeriod();

      progress("Fetching period history...");
      const history = await contract.getTradingPeriodHistory(currentPeriod);

      console.log(`      Start Time: ${new Date(Number(history[0]) * 1000).toLocaleString()}`);
      console.log(`      End Time: ${new Date(Number(history[1]) * 1000).toLocaleString()}`);
      console.log(`      Is Active: ${history[2]}`);
      console.log(`      Results Revealed: ${history[3]}`);
      console.log(`      Total Trades: ${history[4]}`);
      console.log(`      Total Volume: ${history[5]}`);
    });
  });

  describe("Gas Usage Analysis", function () {
    it("should report gas costs for view functions", async function () {
      steps = 5;
      this.timeout(120000);

      progress("Measuring getCurrentTradingPeriodInfo...");
      const tx1 = await contract.getCurrentTradingPeriodInfo.estimateGas();
      console.log(`      Gas: ${tx1.toString()}`);
      expect(tx1).to.be.lt(100000n);

      progress("Measuring getProducerOfferCount...");
      const tx2 = await contract.getProducerOfferCount.estimateGas(deployer.address);
      console.log(`      Gas: ${tx2.toString()}`);
      expect(tx2).to.be.lt(50000n);

      progress("Measuring getConsumerDemandCount...");
      const tx3 = await contract.getConsumerDemandCount.estimateGas(deployer.address);
      console.log(`      Gas: ${tx3.toString()}`);
      expect(tx3).to.be.lt(50000n);

      progress("Measuring isTradingTimeActive...");
      const tx4 = await contract.isTradingTimeActive.estimateGas();
      console.log(`      Gas: ${tx4.toString()}`);
      expect(tx4).to.be.lt(50000n);

      progress("Measuring getTradingPeriodHistory...");
      const currentPeriod = await contract.currentTradingPeriod();
      const tx5 = await contract.getTradingPeriodHistory.estimateGas(currentPeriod);
      console.log(`      Gas: ${tx5.toString()}`);
      expect(tx5).to.be.lt(50000n);
    });
  });

  describe("Network Information", function () {
    it("should display network details", async function () {
      steps = 4;
      this.timeout(60000);

      progress("Fetching network information...");
      const networkData = await ethers.provider.getNetwork();
      console.log(`      Network: ${networkData.name}`);
      console.log(`      Chain ID: ${networkData.chainId}`);

      progress("Fetching block number...");
      const blockNumber = await ethers.provider.getBlockNumber();
      console.log(`      Block: ${blockNumber}`);

      progress("Fetching deployer balance...");
      const balance = await ethers.provider.getBalance(deployer.address);
      console.log(`      Balance: ${ethers.formatEther(balance)} ETH`);

      progress("Fetching gas price...");
      const feeData = await ethers.provider.getFeeData();
      console.log(`      Gas Price: ${ethers.formatUnits(feeData.gasPrice, "gwei")} gwei`);
    });

    it("should verify Etherscan link", async function () {
      steps = 1;

      progress("Generating Etherscan URL...");
      const etherscanUrl = `https://sepolia.etherscan.io/address/${contractAddress}`;
      console.log(`      URL: ${etherscanUrl}`);
      console.log(`      Deployer: https://sepolia.etherscan.io/address/${deployer.address}`);
    });
  });

  describe("Contract Interaction Safety", function () {
    it("should handle read-only calls safely", async function () {
      steps = 3;
      this.timeout(90000);

      progress("Testing multiple concurrent reads...");
      const promises = [
        contract.owner(),
        contract.currentTradingPeriod(),
        contract.nextOfferId(),
        contract.nextDemandId(),
        contract.isTradingTimeActive(),
      ];

      progress("Waiting for responses...");
      const results = await Promise.all(promises);

      progress("Validating results...");
      expect(results).to.have.lengthOf(5);
      console.log(`      All ${results.length} reads successful`);
    });

    it("should report current system state", async function () {
      steps = 1;
      this.timeout(60000);

      progress("Generating state report...");

      const [owner, period, nextOffer, nextDemand, tradingActive, settlementActive] =
        await Promise.all([
          contract.owner(),
          contract.currentTradingPeriod(),
          contract.nextOfferId(),
          contract.nextDemandId(),
          contract.isTradingTimeActive(),
          contract.isSettlementTimeActive(),
        ]);

      console.log(`\n      📊 Current System State:`);
      console.log(`      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`      Owner:             ${owner}`);
      console.log(`      Trading Period:    ${period}`);
      console.log(`      Next Offer ID:     ${nextOffer}`);
      console.log(`      Next Demand ID:    ${nextDemand}`);
      console.log(`      Trading Active:    ${tradingActive}`);
      console.log(`      Settlement Active: ${settlementActive}`);
      console.log(`      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
    });
  });
});
