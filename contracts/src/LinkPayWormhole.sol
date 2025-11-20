// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LinkPayWormhole - Automated Cross-Chain Payroll with Wormhole CCTP
 * @notice This contract enables companies to pay employees in USDC across multiple chains using Wormhole's CCTP Bridge
 *
 * @dev Key Features:
 * - Company registration and employee management
 * - Automated payroll scheduling with Chainlink Automation
 * - Cross-chain USDC transfers via Wormhole CCTP (native USDC, no wrapped tokens)
 * - Support for Base, Arbitrum, Avalanche, Optimism, and Ethereum Sepolia
 *
 * @custom:wormhole-integration
 * Wormhole CCTP Bridge replaces Chainlink CCIP for cross-chain transfers:
 * - Uses CircleIntegration contract for burn-and-mint USDC transfers
 * - Supports optional payloads for composability
 * - Automated relaying eliminates manual redemptions
 * - Native USDC on all supported chains
 */

/// ---------------------------------------------------------------
///                        INTERFACES
/// ---------------------------------------------------------------

interface AutomationCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

/// @notice Wormhole CircleIntegration interface for CCTP transfers
interface ICircleIntegration {
    struct TransferParameters {
        address token;           // Address of the token to be burned
        uint256 amount;          // Amount of the token to be burned
        uint16 targetChain;      // Wormhole chain ID of the target blockchain
        bytes32 mintRecipient;   // The recipient wallet or contract address on the target chain
    }

    function transferTokensWithPayload(
        TransferParameters memory transferParams,
        uint32 batchId,
        bytes memory payload
    ) external payable returns (uint64 messageSequence);
}

/// ---------------------------------------------------------------
///                        MAIN CONTRACT
/// ---------------------------------------------------------------

contract LinkPayWormhole is AutomationCompatibleInterface {
    using SafeERC20 for IERC20;

    /// ---------------------------------------------------------------
    ///                    STATE VARIABLES
    /// ---------------------------------------------------------------

    // General Configuration
    IERC20 public immutable usdc;
    address public owner;
    address public feeWallet;
    uint256 public registrationFee;
    uint256 public interval;

    // Wormhole Integration
    ICircleIntegration public immutable wormholeCircleBridge;
    mapping(uint16 => bool) public allowedWormholeChains;

    // Company and Employee Management
    uint256 public nextCompanyId = 1;
    uint256 public nextEmployeeId = 1;
    uint256 public lastCheckedCompanyIndex;
    uint256 public lastCheckedEmployeeIndex;
    uint256[] public companyIds;

    mapping(uint256 => Company) public companies;
    mapping(address => uint256) public companyOfOwner;
    mapping(uint256 => Employee) public employees;

    /// ---------------------------------------------------------------
    ///                    STRUCTS
    /// ---------------------------------------------------------------

    struct Company {
        address owner;
        string name;
        bool active;
        uint256 registrationDate;
        uint256 companyId;
        uint256[] employeeIds;
    }

    struct Employee {
        uint256 companyId;
        string name;
        address wallet;
        uint16 wormholeChainId;      // Wormhole chain ID (e.g., 30 for Base, 23 for Arbitrum)
        uint256 salary;
        uint256 nextPayDate;
        bool active;
        uint256 employeeId;
    }

    /// ---------------------------------------------------------------
    ///                    EVENTS
    /// ---------------------------------------------------------------

    event CompanyRegistered(uint256 indexed companyId, address indexed owner, string name);
    event EmployeeAdded(uint256 indexed companyId, uint256 indexed employeeId, string name, address wallet, uint256 salary, uint16 wormholeChainId);
    event EmployeeUpdated(uint256 indexed companyId, uint256 indexed employeeId);
    event EmployeeDeactivated(uint256 indexed companyId, uint256 indexed employeeId);
    event PaymentScheduled(uint256 indexed companyId, uint256 indexed employeeId, address indexed wallet, uint256 amount, uint16 wormholeChainId);
    event PaymentExecutedLocal(uint256 indexed companyId, uint256 indexed employeeId, address indexed wallet, uint256 amount);
    event PaymentExecutedViaWormhole(
        uint256 indexed companyId,
        uint256 indexed employeeId,
        address indexed wallet,
        uint256 amount,
        uint16 targetChain,
        uint64 wormholeSequence
    );
    event RegistrationFeeUpdated(uint256 newFee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event IntervalUpdated(uint256 newInterval);
    event WormholeChainAllowed(uint16 indexed wormholeChainId, bool allowed);

    /// ---------------------------------------------------------------
    ///                    ERRORS
    /// ---------------------------------------------------------------

    error NotOwner();
    error NotCompanyOwner();
    error ZeroAddress();
    error InvalidAmount();
    error InvalidChain();
    error ChainNotAllowed();
    error CompanyInactive();
    error EmployeeInactive();
    error InsufficientAllowance();
    error TransferFailed();

    /// ---------------------------------------------------------------
    ///                    MODIFIERS
    /// ---------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyCompanyOwner(uint256 _companyId) {
        if (companies[_companyId].owner != msg.sender) revert NotCompanyOwner();
        _;
    }

    /// ---------------------------------------------------------------
    ///                    CONSTRUCTOR
    /// ---------------------------------------------------------------

    /**
     * @notice Initializes the LinkPayWormhole contract
     * @param _usdc Address of USDC token contract
     * @param _feeWallet Address to receive registration fees
     * @param _registrationFee Fee amount for company registration (in USDC wei)
     * @param _wormholeCircleBridge Address of Wormhole CircleIntegration contract
     */
    constructor(
        address _usdc,
        address _feeWallet,
        uint256 _registrationFee,
        address _wormholeCircleBridge
    ) {
        if (_usdc == address(0)) revert ZeroAddress();
        if (_feeWallet == address(0)) revert ZeroAddress();
        if (_wormholeCircleBridge == address(0)) revert ZeroAddress();

        usdc = IERC20(_usdc);
        owner = msg.sender;
        feeWallet = _feeWallet;
        registrationFee = _registrationFee;
        interval = 5 minutes; // Testing interval (use 30 days for production)
        wormholeCircleBridge = ICircleIntegration(_wormholeCircleBridge);

        // Initialize allowed Wormhole chains for CCTP
        // Testnet chain IDs
        allowedWormholeChains[10004] = true;  // Base Sepolia
        allowedWormholeChains[10003] = true;  // Arbitrum Sepolia
        allowedWormholeChains[6] = true;      // Avalanche Fuji
        allowedWormholeChains[10005] = true;  // Optimism Sepolia
        allowedWormholeChains[10002] = true;  // Ethereum Sepolia
    }

    /// ---------------------------------------------------------------
    ///                    COMPANY MANAGEMENT
    /// ---------------------------------------------------------------

    /**
     * @notice Registers a new company
     * @param _name Company name
     */
    function registerCompany(string calldata _name) external {
        require(bytes(_name).length > 0, "name required");
        require(companyOfOwner[msg.sender] == 0, "wallet already has company");

        // Check allowance
        if (usdc.allowance(msg.sender, address(this)) < registrationFee) {
            revert InsufficientAllowance();
        }

        // Transfer registration fee
        bool success = usdc.transferFrom(msg.sender, feeWallet, registrationFee);
        if (!success) revert TransferFailed();

        // Create company
        uint256 cid = nextCompanyId++;
        Company storage c = companies[cid];
        c.owner = msg.sender;
        c.name = _name;
        c.active = true;
        c.registrationDate = block.timestamp;
        c.companyId = cid;

        companyOfOwner[msg.sender] = cid;
        companyIds.push(cid);

        emit CompanyRegistered(cid, msg.sender, _name);
    }

    /**
     * @notice Updates the registration fee (onlyOwner)
     * @param _fee New registration fee amount
     */
    function setRegistrationFee(uint256 _fee) external onlyOwner {
        registrationFee = _fee;
        emit RegistrationFeeUpdated(_fee);
    }

    /**
     * @notice Sets the payment interval (onlyOwner)
     * @param _interval New interval in seconds
     */
    function setInterval(uint256 _interval) external onlyOwner {
        require(_interval > 0, "invalid interval");
        interval = _interval;
        emit IntervalUpdated(_interval);
    }

    /**
     * @notice Deactivates a company (onlyOwner)
     * @param _companyId Company ID to deactivate
     */
    function deactivateCompany(uint256 _companyId) external onlyOwner {
        companies[_companyId].active = false;
    }

    /**
     * @notice Activates a company (onlyOwner)
     * @param _companyId Company ID to activate
     */
    function activateCompany(uint256 _companyId) external onlyOwner {
        companies[_companyId].active = true;
    }

    /// ---------------------------------------------------------------
    ///                    EMPLOYEE MANAGEMENT
    /// ---------------------------------------------------------------

    /**
     * @notice Adds an employee to the sender's company
     * @param _name Employee name
     * @param _wallet Employee wallet address
     * @param _wormholeChainId Wormhole chain ID where employee will receive payment
     * @param _salary Salary amount in USDC (wei)
     */
    function addEmployee(
        string calldata _name,
        address _wallet,
        uint16 _wormholeChainId,
        uint256 _salary
    ) external {
        uint256 _companyId = companyOfOwner[msg.sender];
        require(_companyId != 0, "not company owner");

        Company storage company = companies[_companyId];
        if (!company.active) revert CompanyInactive();
        if (_wallet == address(0)) revert ZeroAddress();
        if (_salary == 0) revert InvalidAmount();

        uint256 eid = nextEmployeeId++;
        Employee storage e = employees[eid];
        e.companyId = _companyId;
        e.name = _name;
        e.wallet = _wallet;
        e.wormholeChainId = _wormholeChainId;
        e.salary = _salary;
        e.nextPayDate = block.timestamp + interval;
        e.active = true;
        e.employeeId = eid;

        company.employeeIds.push(eid);

        emit EmployeeAdded(_companyId, eid, _name, _wallet, _salary, _wormholeChainId);
    }

    /**
     * @notice Updates an employee's details
     */
    function updateEmployee(
        uint256 _employeeId,
        string calldata _name,
        address _wallet,
        uint16 _wormholeChainId,
        uint256 _salary,
        uint256 _nextPayDate,
        bool _active
    ) external {
        uint256 _companyId = companyOfOwner[msg.sender];
        require(_companyId != 0, "not company owner");

        Employee storage e = employees[_employeeId];
        require(e.companyId == _companyId, "mismatched company");

        e.name = _name;
        e.wallet = _wallet;
        e.wormholeChainId = _wormholeChainId;
        e.salary = _salary;
        e.nextPayDate = _nextPayDate;
        e.active = _active;

        emit EmployeeUpdated(_companyId, _employeeId);
    }

    /**
     * @notice Deactivates an employee
     * @param _employeeId Employee ID to deactivate
     */
    function deactivateEmployee(uint256 _employeeId) external {
        uint256 _companyId = companyOfOwner[msg.sender];
        require(_companyId != 0, "not company owner");

        Employee storage e = employees[_employeeId];
        require(e.companyId == _companyId, "mismatched company");

        e.active = false;
        emit EmployeeDeactivated(_companyId, _employeeId);
    }

    /// ---------------------------------------------------------------
    ///                    WORMHOLE CCTP INTEGRATION
    /// ---------------------------------------------------------------

    /**
     * @notice Allows/disallows a Wormhole chain for cross-chain payments
     * @param _wormholeChainId Wormhole chain ID
     * @param _allowed Whether to allow this chain
     */
    function setAllowedWormholeChain(uint16 _wormholeChainId, bool _allowed) external onlyOwner {
        allowedWormholeChains[_wormholeChainId] = _allowed;
        emit WormholeChainAllowed(_wormholeChainId, _allowed);
    }

    /**
     * @notice Manual payment function using Wormhole CCTP
     * @param _employeeId Employee to pay
     * @dev Requires msg.value for Wormhole relayer fees
     */
    function payEmployeeViaWormhole(uint256 _employeeId) external payable {
        Employee storage emp = employees[_employeeId];
        uint256 _companyId = emp.companyId;

        // Validations
        if (companies[_companyId].owner != msg.sender) revert NotCompanyOwner();
        if (!emp.active) revert EmployeeInactive();
        if (!allowedWormholeChains[emp.wormholeChainId]) revert ChainNotAllowed();

        address companyOwner = companies[_companyId].owner;

        // Check if this is a same-chain payment (Base Sepolia testnet ID: 10004)
        if (emp.wormholeChainId == 10004) {
            // Same chain payment - direct transfer
            bool success = usdc.transferFrom(companyOwner, emp.wallet, emp.salary);
            if (!success) revert TransferFailed();

            emp.nextPayDate = block.timestamp + interval;
            emit PaymentExecutedLocal(_companyId, _employeeId, emp.wallet, emp.salary);
        } else {
            // Cross-chain payment via Wormhole CCTP

            // Transfer USDC from company to this contract
            bool success = usdc.transferFrom(companyOwner, address(this), emp.salary);
            if (!success) revert TransferFailed();

            // Approve Wormhole CircleIntegration
            usdc.approve(address(wormholeCircleBridge), emp.salary);

            // Prepare transfer parameters
            ICircleIntegration.TransferParameters memory params = ICircleIntegration.TransferParameters({
                token: address(usdc),
                amount: emp.salary,
                targetChain: emp.wormholeChainId,
                mintRecipient: bytes32(uint256(uint160(emp.wallet)))
            });

            // Encode employee data as payload for composability
            bytes memory payload = abi.encode(
                _employeeId,
                emp.name,
                block.timestamp
            );

            // Execute cross-chain transfer via Wormhole CCTP
            uint64 sequence = wormholeCircleBridge.transferTokensWithPayload{value: msg.value}(
                params,
                0, // batchId
                payload
            );

            // Update next payment date
            emp.nextPayDate = block.timestamp + interval;

            emit PaymentExecutedViaWormhole(
                _companyId,
                _employeeId,
                emp.wallet,
                emp.salary,
                emp.wormholeChainId,
                sequence
            );
        }
    }

    /// ---------------------------------------------------------------
    ///                    CHAINLINK AUTOMATION
    /// ---------------------------------------------------------------

    /**
     * @notice Checks if there are pending payments (Chainlink Automation)
     * @return upkeepNeeded Whether upkeep is needed
     * @return performData Encoded data for performUpkeep
     */
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 cLen = companyIds.length;
        if (cLen == 0) return (false, bytes(""));

        for (uint256 i = 0; i < cLen; i++) {
            uint256 cIdx = (lastCheckedCompanyIndex + i) % cLen;
            uint256 cid = companyIds[cIdx];
            Company storage comp = companies[cid];
            if (!comp.active) continue;

            uint256[] storage eids = comp.employeeIds;
            uint256 eLen = eids.length;
            if (eLen == 0) continue;

            uint256 start = lastCheckedEmployeeIndex % eLen;
            for (uint256 j = 0; j < eLen; j++) {
                uint256 eIdx = (start + j) % eLen;
                uint256 eid = eids[eIdx];
                Employee storage emp = employees[eid];
                if (!emp.active) continue;
                if (block.timestamp >= emp.nextPayDate) {
                    upkeepNeeded = true;
                    performData = abi.encode(cid, eid);
                    return (upkeepNeeded, performData);
                }
            }
        }

        return (false, bytes(""));
    }

    /**
     * @notice Executes payment when automation triggers (Chainlink Automation)
     * @param performData Encoded company and employee IDs
     */
    function performUpkeep(bytes calldata performData) external override {
        require(performData.length == 64, "bad performData");
        (uint256 cid, uint256 eid) = abi.decode(performData, (uint256, uint256));

        Company storage comp = companies[cid];
        require(comp.active, "company inactive");

        Employee storage emp = employees[eid];
        require(emp.companyId == cid, "mismatched");
        require(emp.active, "employee inactive");
        require(block.timestamp >= emp.nextPayDate, "not due");

        _executePayment(cid, eid, emp);
    }

    /**
     * @notice Internal payment execution logic
     * @dev Called by automation or manual payment functions
     */
    function _executePayment(
        uint256 _companyId,
        uint256 _employeeId,
        Employee storage emp
    ) internal {
        address companyOwner = companies[_companyId].owner;

        // Check allowance
        uint256 allowance = usdc.allowance(companyOwner, address(this));
        if (allowance < emp.salary) {
            emit PaymentScheduled(_companyId, _employeeId, emp.wallet, 0, emp.wormholeChainId);
            return;
        }

        // Same chain payment (Base Sepolia: 10004)
        if (emp.wormholeChainId == 10004) {
            bool success = usdc.transferFrom(companyOwner, emp.wallet, emp.salary);
            if (success) {
                emp.nextPayDate = block.timestamp + interval;
                emit PaymentExecutedLocal(_companyId, _employeeId, emp.wallet, emp.salary);
            } else {
                emit PaymentScheduled(_companyId, _employeeId, emp.wallet, 0, emp.wormholeChainId);
            }
        } else {
            // Cross-chain payment via Wormhole CCTP
            // Note: This requires ETH for Wormhole relayer fees, which performUpkeep cannot provide
            // For automated cross-chain payments, company must fund this contract with ETH
            // Or use manual payEmployeeViaWormhole() with msg.value

            uint256 contractBalance = address(this).balance;
            if (contractBalance < 0.01 ether) {
                // Not enough ETH for Wormhole fees - emit scheduled event
                emit PaymentScheduled(_companyId, _employeeId, emp.wallet, emp.salary, emp.wormholeChainId);
                return;
            }

            // Execute cross-chain payment
            bool transferSuccess = usdc.transferFrom(companyOwner, address(this), emp.salary);
            if (!transferSuccess) {
                emit PaymentScheduled(_companyId, _employeeId, emp.wallet, emp.salary, emp.wormholeChainId);
                return;
            }

            // Approve Wormhole CircleIntegration
            usdc.approve(address(wormholeCircleBridge), emp.salary);

            // Prepare transfer parameters
            ICircleIntegration.TransferParameters memory params = ICircleIntegration.TransferParameters({
                token: address(usdc),
                amount: emp.salary,
                targetChain: emp.wormholeChainId,
                mintRecipient: bytes32(uint256(uint160(emp.wallet)))
            });

            // Encode employee data as payload
            bytes memory payload = abi.encode(
                _employeeId,
                emp.name,
                block.timestamp
            );

            // Execute cross-chain transfer via Wormhole CCTP
            uint64 sequence = wormholeCircleBridge.transferTokensWithPayload{value: 0.01 ether}(
                params,
                0, // batchId
                payload
            );

            // Update next payment date
            emp.nextPayDate = block.timestamp + interval;

            emit PaymentExecutedViaWormhole(
                _companyId,
                _employeeId,
                emp.wallet,
                emp.salary,
                emp.wormholeChainId,
                sequence
            );
        }
    }

    /// ---------------------------------------------------------------
    ///                    VIEW FUNCTIONS
    /// ---------------------------------------------------------------

    /**
     * @notice Returns all company IDs
     */
    function getCompanyIds() external view returns (uint256[] memory) {
        return companyIds;
    }

    /**
     * @notice Gets employee IDs for a company
     * @param _companyId Company ID
     */
    function getEmployeesOfCompany(uint256 _companyId) external view returns (uint256[] memory) {
        return companies[_companyId].employeeIds;
    }

    /**
     * @notice Returns employee information
     * @param _employeeId Employee ID
     */
    function getEmployee(uint256 _employeeId) external view returns (
        uint256 companyId,
        string memory name,
        address wallet,
        uint16 wormholeChainId,
        uint256 salary,
        uint256 nextPayDate,
        bool active,
        uint256 employeeId
    ) {
        Employee storage e = employees[_employeeId];
        return (
            e.companyId,
            e.name,
            e.wallet,
            e.wormholeChainId,
            e.salary,
            e.nextPayDate,
            e.active,
            e.employeeId
        );
    }

    /**
     * @notice Gets the company ID for a wallet address
     * @param _owner Wallet address
     */
    function getCompanyIdByOwner(address _owner) external view returns (uint256) {
        return companyOfOwner[_owner];
    }

    /// ---------------------------------------------------------------
    ///                    ADMIN FUNCTIONS
    /// ---------------------------------------------------------------

    /**
     * @notice Transfers contract ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Admin function to deactivate an employee
     * @param _companyId Company ID
     * @param _employeeId Employee ID
     */
    function adminDeactivateEmployee(uint256 _companyId, uint256 _employeeId) external onlyOwner {
        Employee storage e = employees[_employeeId];
        require(e.companyId == _companyId, "mismatched company");
        require(e.active, "already inactive");

        e.active = false;
        emit EmployeeDeactivated(_companyId, _employeeId);
    }

    /// ---------------------------------------------------------------
    ///                    EMERGENCY FUNCTIONS
    /// ---------------------------------------------------------------

    /**
     * @notice Allows the contract to receive Ether for Wormhole fees
     */
    receive() external payable {}

    /**
     * @notice Withdraws ETH from contract (onlyOwner)
     * @param _beneficiary Address to receive ETH
     */
    function withdraw(address _beneficiary) external onlyOwner {
        if (_beneficiary == address(0)) revert ZeroAddress();
        uint256 amount = address(this).balance;
        require(amount > 0, "nothing to withdraw");

        (bool sent, ) = _beneficiary.call{value: amount}("");
        require(sent, "withdrawal failed");
    }

    /**
     * @notice Withdraws ERC20 tokens from contract (onlyOwner)
     * @param _beneficiary Address to receive tokens
     * @param _token Token address
     */
    function withdrawToken(address _beneficiary, address _token) external onlyOwner {
        if (_beneficiary == address(0)) revert ZeroAddress();
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "nothing to withdraw");
        IERC20(_token).safeTransfer(_beneficiary, amount);
    }
}
