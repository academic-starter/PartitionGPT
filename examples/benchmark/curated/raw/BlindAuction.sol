// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.25;
import "./EncryptedERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract BlindAuction is Ownable2Step {
    uint256 public endTime;

    address public beneficiary;

    // Current highest bid.
    uint64 private highestBid;

    // Mapping from bidder to their bid value.
    mapping(address account => uint64 bidAmount) private bids;

    // Number of bid
    uint256 public bidCounter;

    // The token contract used for encrypted bids.
    EncryptedERC20 public tokenContract;

    // Whether the auction object has been claimed.
    // WARNING : if there is a draw, only first highest bidder will get the prize (an improved implementation could handle this case differently)
    bool private objectClaimed;

    // If the token has been transferred to the beneficiary
    bool public tokenTransferred;

    bool public stoppable;

    bool public manuallyStopped = false;

    // The function has been called too early.
    // Try again at `time`.
    error TooEarly(uint256 time);
    // The function has been called too late.
    // It cannot be called after `time`.
    error TooLate(uint256 time);

    constructor(
        address _beneficiary,
        EncryptedERC20 _tokenContract,
        uint256 biddingTime,
        bool isStoppable
    ) Ownable(msg.sender) {
        beneficiary = _beneficiary;
        tokenContract = _tokenContract;
        endTime = block.timestamp + biddingTime;
        objectClaimed = false;
        tokenTransferred = false;
        bidCounter = 0;
        stoppable = isStoppable;
    }

    // Bid an `encryptedValue`.
    function bid(uint64 value) external onlyBeforeEnd {
        uint64 existingBid = bids[msg.sender];
        uint64 sentBalance;
        if (existingBid>0) {
            uint64 balanceBefore = tokenContract.balanceOf(address(this));
            bool isHigher = existingBid < value;
            uint64 toTransfer = value - existingBid;

            // Transfer only if bid is higher, also to avoid overflow from previous line
            uint64 amount = 0;
            if (isHigher){
                amount = toTransfer;
            }
            tokenContract.transferFrom(msg.sender, address(this), amount);

            uint64 balanceAfter = tokenContract.balanceOf(address(this));
            sentBalance = balanceAfter - balanceBefore;
            uint64 newBid = existingBid + sentBalance;
            bids[msg.sender] = newBid;
        } else {
            bidCounter++;
            uint64 balanceBefore = tokenContract.balanceOf(address(this));
            tokenContract.transferFrom(msg.sender, address(this), value);
            uint64 balanceAfter = tokenContract.balanceOf(address(this));
            sentBalance = balanceAfter - balanceBefore;
            bids[msg.sender] = sentBalance;
        }
        uint64 currentBid = bids[msg.sender];

        if (highestBid == 0) {
            highestBid = currentBid;
        } else {
            bool isNewWinner = highestBid < currentBid;
            if (isNewWinner){
                highestBid = currentBid;
            }
        }
    }

    // Returns the `account`'s encrypted bid, can be used in a reencryption request
    function getBid(address account) external view returns (uint64) {
        return bids[account];
    }

    function stop() external onlyOwner {
        require(stoppable);
        manuallyStopped = true;
    }
    
    // Claim the object. Succeeds only if the caller was the first to get the highest bid.
    function claim() public onlyAfterEnd {
        require(!objectClaimed);
        uint64 bidValue = bids[msg.sender];
        if (bidValue >= highestBid){
            objectClaimed = true;
        }
    }


    // Transfer token to beneficiary
    function auctionEnd() public onlyAfterEnd {
        require(!tokenTransferred);
        tokenTransferred = true;
        tokenContract.transfer(beneficiary, highestBid);
    }

    // Withdraw a bid from the auction to the caller once the auction has stopped.
    function withdraw() public onlyAfterEnd {
        uint64 bidValue = bids[msg.sender];
        if (bidValue < highestBid){
            tokenContract.transfer(msg.sender, bidValue);    
        }
    }

    modifier onlyBeforeEnd() {
        if (block.timestamp >= endTime || manuallyStopped == true) revert TooLate(endTime);
        _;
    }

    modifier onlyAfterEnd() {
        if (block.timestamp < endTime && manuallyStopped == false) revert TooEarly(endTime);
        _;
    }
}
