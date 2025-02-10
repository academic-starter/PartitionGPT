pragma solidity 0.8.0;

contract BlindAuction {
    address public beneficiary;
    uint64 private highestBid;
    mapping(address => uint64 ) private bids;
  

    // error TooEarly(uint256 time);
    // error TooLate(uint256 time);

    event BidMessagePassing(bool increment);
    event GetBidMessagePassing(uint64 amount);
    event ClaimMessagePassing(bool enable_claim);

    constructor(
        address _beneficiary,
        uint256 biddingTime,
        bool isStoppable
    ) {
       
    }

    function bid(address to, uint64 value) external {
        bool increment = false;

        uint64 existingBid = bids[to];
        if (existingBid > 0) {
            bool isHigher = existingBid < value;
            uint64 toTransfer = value - existingBid;
            uint64 amount = 0;
            if (isHigher) {
                amount = toTransfer;
            }
            bids[to] = existingBid + amount;
        } else {
            bids[to] = value;
            increment = true;
        }

        uint64 currentBid = bids[to];
        if (highestBid == 0) {
            highestBid = currentBid;
        } else {
            bool isNewWinner = highestBid < currentBid;
            if (isNewWinner) {
                highestBid = currentBid;
            }
        }

        emit BidMessagePassing(increment); // this message will be sent to invoke "bid_callback" function of public contract
    }

    function getBid(address account) external {
        uint64 amt = bids[account];
        emit GetBidMessagePassing(amt);
    }

    function claim(address user) external {
        bool enable_claim = false;
        uint64 bidValue = bids[user];
        if (bidValue >= highestBid){
            enable_claim = true;
            bids[user] = 0;
        }
        emit ClaimMessagePassing(enable_claim);
    }

    function withdraw(address sender) external {
        uint64 bidValue = bids[sender];
        if (bidValue < highestBid){
            // tokenContract.transfer(sender, bidValue);  
            bids[sender] = 0;  
        }
    }

}
