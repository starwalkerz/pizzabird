// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DriverPlatform {
    // Owner of the platform
    address public owner;

    // Driver administrator role
    address public driverAdmin;

    // Driver structure
    struct Driver {
        bool isRegistered;
        bool isActive;
        uint256 totalRatings;
        uint256 numberOfRatings;
        uint256 standardPayout; // This is dynamically set based on the zone
        uint256 bonus;
        uint256 zoneId; // Zone identifier
        string driverId;
    }

    // Customer structure
    struct Customer {
        bool isRegistered;
        string customerId;
    }

    // Mappings
    mapping(address => Driver) public drivers;
    mapping(address => Customer) public customers;
    mapping(uint256 => uint256) public zoneRates; // Maps zoneId to standard payout rate

    // Events
    event DriverRegistered(address indexed driver, string driverId);
    event DriverStatusUpdated(address indexed driver, bool isActive);
    event DriverDeRegistered(address indexed driver);
    event CustomerRegistered(address indexed customer, string customerId);
    event RatingUpdated(address indexed driver, uint256 newAverageRating);
    event OrderConfirmed(address indexed customer, address indexed driver, uint256 tip);
    event PayoutUpdated(address indexed driver, uint256 standardPayout, uint256 bonus);
    event ZoneRateUpdated(uint256 zoneId, uint256 standardRate);
    event DriverZoneUpdated(address indexed driver, uint256 zoneId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyDriverAdmin() {
        require(msg.sender == driverAdmin, "Only the driver administrator can perform this action");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == driverAdmin, "Not authorized");
        _;
    }

    // Constructor
    constructor(address _driverAdmin) {
        owner = msg.sender;
        driverAdmin = _driverAdmin;
    }

    // Register a new driver
    function registerDriver(address _driver, string memory _driverId, uint256 _zoneId) public onlyDriverAdmin {
        require(!drivers[_driver].isRegistered, "Driver is already registered");
        require(zoneRates[_zoneId] > 0, "Zone rate must be set before registering drivers to this zone");

        drivers[_driver] = Driver(true, true, 0, 0, zoneRates[_zoneId], 0, _zoneId, _driverId);
        emit DriverRegistered(_driver, _driverId);
    }

    // Update driver status (active/passive)
    function updateDriverStatus(address _driver, bool _isActive) public onlyDriverAdmin {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        drivers[_driver].isActive = _isActive;
        emit DriverStatusUpdated(_driver, _isActive);
    }

    // De-register a passive driver
    function deRegisterDriver(address _driver) public onlyDriverAdmin {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        require(!drivers[_driver].isActive, "Driver must be passive to be de-registered");
        delete drivers[_driver];
        emit DriverDeRegistered(_driver);
    }

    // Update the payout rate for a zone
    function setZoneRate(uint256 _zoneId, uint256 _standardRate) public onlyDriverAdmin {
        require(_standardRate > 0, "Standard rate must be greater than zero");
        zoneRates[_zoneId] = _standardRate;
        emit ZoneRateUpdated(_zoneId, _standardRate);
    }

    // Update driver payout based on the assigned zone
    function updateDriverZone(address _driver, uint256 _zoneId) public onlyDriverAdmin {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        require(zoneRates[_zoneId] > 0, "Zone rate must be set before assigning");

        drivers[_driver].zoneId = _zoneId;
        drivers[_driver].standardPayout = zoneRates[_zoneId];
        emit DriverZoneUpdated(_driver, _zoneId);
    }

    // Set driver payout details
    function setDriverBonus(address _driver, uint256 _bonus) public onlyDriverAdmin {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        drivers[_driver].bonus = _bonus;
        emit PayoutUpdated(_driver, drivers[_driver].standardPayout, _bonus);
    }

    // Register a new customer
    function registerCustomer(address _customer, string memory _customerId) public onlyAuthorized {
        require(!customers[_customer].isRegistered, "Customer is already registered");
        customers[_customer] = Customer(true, _customerId);
        emit CustomerRegistered(_customer, _customerId);
    }

    // Confirm order and rate driver
    function confirmOrderAndRate(address _customer, address _driver, uint256 _rating, uint256 _tip) public {
        require(customers[_customer].isRegistered, "Customer is not registered");
        require(drivers[_driver].isRegistered, "Driver is not registered");
        require(drivers[_driver].isActive, "Driver is not active");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        Driver storage driver = drivers[_driver];
        driver.totalRatings += _rating;
        driver.numberOfRatings += 1;

        emit OrderConfirmed(_customer, _driver, _tip);
        emit RatingUpdated(_driver, getAverageRating(_driver));
    }

    // Get average rating of a driver
    function getAverageRating(address _driver) public view returns (uint256) {
        require(drivers[_driver].isRegistered, "Driver is not registered");
        Driver memory driver = drivers[_driver];

        if (driver.numberOfRatings == 0) {
            return 0;
        }

        return (driver.totalRatings * 100) / driver.numberOfRatings; // Average rating with two decimal precision
    }
}
