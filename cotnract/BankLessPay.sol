// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BankLessPay
 * @dev A decentralized payment system enabling peer-to-peer transactions without traditional banking
 * @author BankLessPay Team
 */
contract BankLessPay {
    // State variables
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(bytes32 => bool) private processedTransactions;
    
    address public owner;
    uint256 public totalSupply;
    uint256 public transactionFee; // Fee in wei (e.g., 0.001 ETH = 1000000000000000)
    uint256 private transactionCounter;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 amount, bytes32 txHash);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event FeeUpdated(uint256 newFee);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }
    
    modifier sufficientBalance(uint256 _amount) {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        _;
    }

    /**
     * @dev Constructor sets the contract owner and initial transaction fee
     */
    constructor() {
        owner = msg.sender;
        transactionFee = 0.001 ether; // Default fee
        transactionCounter = 0;
    }

    /**
     * @dev Core Function 1: Send Payment
     * Enables users to send payments to other addresses with transaction fees
     * @param _to Recipient address
     * @param _amount Amount to send (in wei)
     */
    function sendPayment(address _to, uint256 _amount) 
        external 
        payable 
        validAddress(_to) 
        sufficientBalance(_amount + transactionFee) 
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value >= transactionFee, "Insufficient transaction fee");
        
        // Generate unique transaction hash
        bytes32 txHash = keccak256(abi.encodePacked(
            msg.sender, 
            _to, 
            _amount, 
            block.timestamp, 
            transactionCounter++
        ));
        
        require(!processedTransactions[txHash], "Transaction already processed");
        
        // Process payment
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        // Mark transaction as processed
        processedTransactions[txHash] = true;
        
        // Send transaction fee to contract owner
        if (msg.value > 0) {
            payable(owner).transfer(msg.value);
        }
        
        emit Transfer(msg.sender, _to, _amount, txHash);
    }

    /**
     * @dev Core Function 2: Deposit Funds
     * Allows users to deposit ETH into their BankLessPay account
     */
    function depositFunds() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Core Function 3: Withdraw Funds
     * Enables users to withdraw their funds from the contract
     * @param _amount Amount to withdraw (in wei)
     */
    function withdrawFunds(uint256 _amount) 
        external 
        sufficientBalance(_amount) 
    {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        
        // Transfer funds to user
        payable(msg.sender).transfer(_amount);
        
        emit Withdrawal(msg.sender, _amount);
    }

    /**
     * @dev Get balance of a specific address
     * @param _account Address to check balance for
     * @return Balance of the account
     */
    function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
    }

    /**
     * @dev Get current transaction fee
     * @return Current transaction fee in wei
     */
    function getTransactionFee() external view returns (uint256) {
        return transactionFee;
    }

    /**
     * @dev Update transaction fee (only owner)
     * @param _newFee New transaction fee in wei
     */
    function updateTransactionFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 0.01 ether, "Fee too high"); // Max 0.01 ETH
        transactionFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    /**
     * @dev Check if a transaction has been processed
     * @param _txHash Transaction hash to check
     * @return Boolean indicating if transaction was processed
     */
    function isTransactionProcessed(bytes32 _txHash) external view returns (bool) {
        return processedTransactions[_txHash];
    }

    /**
     * @dev Get contract's total supply
     * @return Total supply of funds in the contract
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    /**
     * @dev Emergency withdraw function (only owner)
     * For contract maintenance and emergency situations
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Transfer ownership (only current owner)
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
}
