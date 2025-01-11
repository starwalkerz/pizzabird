// Please roast this file as much as you can.

// Smart Contract (Solidity)
pragma solidity ^0.8.0;

contract DriverPlatform {
    // Owner of the platform
    address public owner;

    // Driver Administrator
    address public driverAdministrator;

    // Driver structure
    struct Driver {
        bool isRegistered;
        bool isActive;
        uint256 totalRatings;
        uint256 numberOfRatings;
        uint256 standardPayout;
        uint256 bonus;
        string driverId;
    }

    // Customer structure
    struct Customer {
        bool isRegistered;
        string customerId;
    }

    // Mappings of addresses to their details
    mapping(address => Driver) public drivers;
    mapping(address => Customer) public customers;

    // Events
    event DriverRegistered(address indexed driver, string driverId);
    event DriverStatusUpdated(address indexed driver, bool isActive);
    event DriverDeRegistered(address indexed driver);
    event CustomerRegistered(address indexed customer, string customerId);
    event RatingUpdated(address indexed driver, uint256 newAverageRating);
    event OrderConfirmed(address indexed customer, address indexed driver, uint256 payout, uint256 bonus, uint256 tip);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyDriverAdministrator() {
        require(msg.sender == driverAdministrator, "Only the driver administrator can perform this action");
        _;
    }

    // Constructor
    constructor(address _driverAdministrator) {
        owner = msg.sender;
        driverAdministrator = _driverAdministrator;
    }

    // Register a new driver (requires driver administrator signature)
    function registerDriver(address _driver, string memory _driverId, uint256 _standardPayout) public onlyDriverAdministrator {
        require(!drivers[_driver].isRegistered, "Driver is already registered");
        drivers[_driver] = Driver(true, true, 0, 0, _standardPayout, 0, _driverId);
        emit DriverRegistered(_driver, _driverId);
    }

    // Update driver status (active/passive)
    function updateDriverStatus(address _driver, bool _isActive) public onlyDriverAdministrator {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        drivers[_driver].isActive = _isActive;
        emit DriverStatusUpdated(_driver, _isActive);
    }

    // De-register a passive driver
    function deRegisterDriver(address _driver) public onlyDriverAdministrator {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        require(!drivers[_driver].isActive, "Driver must be passive to be de-registered");
        delete drivers[_driver];
        emit DriverDeRegistered(_driver);
    }

    // Set bonus for a driver
    function setDriverBonus(address _driver, uint256 _bonus) public onlyDriverAdministrator {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        drivers[_driver].bonus = _bonus;
    }

    // Register a new customer
    function registerCustomer(address _customer, string memory _customerId) public onlyOwner {
        require(!customers[_customer].isRegistered, "Customer is already registered");
        customers[_customer] = Customer(true, _customerId);
        emit CustomerRegistered(_customer, _customerId);
    }

    // Confirm order and rate driver, include payout, bonus, and tip
    function confirmOrderAndRate(address _customer, address _driver, uint256 _rating, uint256 _tip) public {
        require(customers[_customer].isRegistered, "Customer is not registered");
        require(drivers[_driver].isRegistered, "Driver is not registered");
        require(drivers[_driver].isActive, "Driver is not active");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        Driver storage driver = drivers[_driver];
        driver.totalRatings += _rating;
        driver.numberOfRatings += 1;

        uint256 payout = driver.standardPayout + driver.bonus + _tip;

        emit OrderConfirmed(_customer, _driver, driver.standardPayout, driver.bonus, _tip);
        emit RatingUpdated(_driver, getAverageRating(_driver));
    }

    // Get average rating of a driver
    function getAverageRating(address _driver) public view returns (uint256) {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        Driver memory driver = drivers[_driver];

        if (driver.numberOfRatings == 0) {
            return 0;
        }

        // Return average rating with two decimal points precision
        return (driver.totalRatings * 100) / driver.numberOfRatings;
    }
}

// Node.js Middleware API Implementation
const express = require('express');
const { ethers } = require('ethers');
const bodyParser = require('body-parser');

// Blockchain setup
const provider = new ethers.providers.JsonRpcProvider('https://your-rpc-url'); // Replace with your RPC URL
const privateKey = 'your-private-key'; // Replace with your private key
const wallet = new ethers.Wallet(privateKey, provider);
const contractAddress = 'your-contract-address'; // Replace with your deployed contract address
const abi = [
    // Add the contract's ABI here
    {
        "inputs": [
            { "internalType": "address", "name": "_driver", "type": "address" },
            { "internalType": "string", "name": "_driverId", "type": "string" },
            { "internalType": "uint256", "name": "_standardPayout", "type": "uint256" }
        ],
        "name": "registerDriver",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_driver", "type": "address" },
            { "internalType": "bool", "name": "_isActive", "type": "bool" }
        ],
        "name": "updateDriverStatus",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_driver", "type": "address" }
        ],
        "name": "deRegisterDriver",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_driver", "type": "address" },
            { "internalType": "uint256", "name": "_bonus", "type": "uint256" }
        ],
        "name": "setDriverBonus",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_customer", "type": "address" },
            { "internalType": "string", "name": "_customerId", "type": "string" }
        ],
        "name": "registerCustomer",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_customer", "type": "address" },
            { "internalType": "address", "name": "_driver", "type": "address" },
            { "internalType": "uint256", "name": "_rating", "type": "uint256" },
            { "internalType": "uint256", "name": "_tip", "type": "uint256" }
        ],
        "name": "confirmOrderAndRate",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "_driver", "type": "address" }
        ],
        "name": "getAverageRating",
        "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
        "stateMutability": "view",
        "type": "function"
    }
];
const contract = new ethers.Contract(contractAddress, abi, wallet);

// Express app setup
const app = express();
app.use(bodyParser.json());

// API Routes

// Register a driver
app.post('/registerDriver', async (req, res) => {
    const { driverAddress, driverId, standardPayout } = req.body;
    try {
        const tx = await contract.registerDriver(driverAddress, driverId, standardPayout);
        await tx.wait();
        res.json({ success: true, message: 'Driver registered successfully!' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Update driver status
app.post('/updateDriverStatus', async (req, res) => {
    const { driverAddress, isActive } = req.body;
    try {
        const tx = await contract.updateDriverStatus(driverAddress, isActive);
        await tx.wait();
