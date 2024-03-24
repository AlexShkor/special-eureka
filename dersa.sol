// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeReSMCI {
    address public owner;
    uint256 public totalRevenue = 0;
    uint256 constant capMultiplier = 2;
    struct Investor {
        uint256 amountInvested;
        uint256 cap;
        uint256 amountReturned;
    }
    
    mapping(address => Investor) public investors;
    uint256 public totalInvested;

    // Events
    event InvestmentReceived(address investor, uint256 amount);
    event RevenueDistributed(uint256 totalRevenueDistributed);
    event InvestmentReturned(address investor, uint256 amountReturned);

    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict functions to the DAO owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the DAO owner can call this function.");
        _;
    }

    // Function for investors to invest
    function invest() external payable {
        require(msg.value > 0, "Investment must be greater than 0.");
        
        if(investors[msg.sender].amountInvested == 0) {
            investors[msg.sender].cap = msg.value * capMultiplier;
        }
        
        investors[msg.sender].amountInvested += msg.value;
        totalInvested += msg.value;

        emit InvestmentReceived(msg.sender, msg.value);
    }

    // Function to add revenue (only DAO owner can call)
    function addRevenue(uint256 _amount) external onlyOwner {
        totalRevenue += _amount;
        distributeRevenue();
    }

    // Private function to distribute revenue among investors
    function distributeRevenue() private {
        uint256 totalRevenueDistributed = 0;
        
        for(uint256 i=0; i < totalInvested; i++) {
            // Simplified distribution logic
            address investorAddress = address(uint160(i)); // This is a placeholder logic to iterate over investors
            Investor storage investor = investors[investorAddress];

            // Calculate the share of the revenue for this investor
            uint256 investorShare = totalRevenue * (investor.amountInvested / totalInvested);
            
            // Ensure we do not exceed the cap
            if(investor.amountReturned + investorShare > investor.cap) {
                investorShare = investor.cap - investor.amountReturned;
            }

            // Transfer the share to the investor
            payable(investorAddress).transfer(investorShare);
            investor.amountReturned += investorShare;
            totalRevenueDistributed += investorShare;

            emit InvestmentReturned(investorAddress, investorShare);
        }

        emit RevenueDistributed(totalRevenueDistributed);
    }

    // Function to withdraw contract balance (for DAO expenses, etc.) by the owner
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance.");
        payable(owner).transfer(_amount);
    }
}