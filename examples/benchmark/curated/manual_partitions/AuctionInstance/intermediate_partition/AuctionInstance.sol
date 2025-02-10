// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.8.0 <0.9.0;

contract AuctionInstance {
    //                       ./AuctionCall.sol                     
    //                                                              
    OrderDetail public orderdetail; //     orderdetail               
    address _owner; //     _owner          
    address address_auctioncall; //     address_auctioncall            
    bool auction_state = true; //     auction_state                          true                         false  
    bool auction_retracted = false; //     auction_retracted                         false               false  

    struct OrderDetail {
        //      OrderDetail                                      
        string OrderInfo; // OrderInfo                                   
        string Coal_Category; // Coal_Category      
        uint256 Reserve_PriceInUnit; // Reserve_PriceInUnit      
        uint256 Quantity; // Quantity       
        uint256 Minimalsplit; // Minimalsplit      /                                            
        uint256 Launch_Time; // Launch_Time        
        uint256 Deadline; // Deadline        
    }

    struct Bidding {
        //      Bidding             
        uint32 PriceInUnit; // PriceInUnit      
        uint32 Quantity; // Quantity   /     
        uint256 Bidding_Time; // Bidding_Time      
        bool Liveness; // Liveness                                    
    }

    struct ExtractedFinal {
        //     ExtractedFinal                                     
        uint8 Bidder_Cindex; // Bidder_Cindex                     
        uint32 Linearized_Ciphertext; // Linearized_Ciphertext         
    }

    struct TopBidder4seller {
        //      TopBidder4seller                      
        uint8 Bidder_index; // Bidder_index                     
        uint8 Linearized_Ciphertext; // Linearized_Ciphertext         
    }

    constructor(OrderDetail memory _orderdetail) {
        //          ./AuctionCall.sol CreateNewAuction        _orderdetail        
        orderdetail = _orderdetail; //    _orderdetail      orderdetail          
        address_auctioncall = msg.sender; //            CreateNewAuction              address_auctioncall              
        _owner = tx.origin; //  CreateNewAuction            _owner                    
    }

    function owner() public view returns (address) {
        // TODO: delete, make public owner
        //             
        return _owner;
    }

    function isOwner_general(address someaddress) public view returns (bool) {
        //                  
        return _owner == someaddress;
    }

    function isOwner_self() internal view returns (bool) {
        //               
        return msg.sender == _owner;
    }

    function isOwner_center() internal view returns (bool) {
        //                     
        return tx.origin == _owner && msg.sender == address_auctioncall;
    }

    modifier onlyOwner_self() {
        require(isOwner_self(), "You are not the creator of this auction contract.");
        _;
    }

    modifier forbidOwner() {
        require(tx.origin != _owner, "The creator himself should not interfere in the procedure of bidding.");
        _;
    }

    modifier onlyOwner_center() {
        // isOwner_center         
        require(isOwner_center(), "You are not the creator of this auction contract.");
        _;
    }

    modifier AuctionOn() {
        if (block.timestamp > orderdetail.Deadline) {
            auction_state = false;
            return;
        } else {
            _;
        }
    }

    modifier AuctionOff() {
        require(block.timestamp <= orderdetail.Deadline, "The auction is still accepting biddings.");
        auction_state = false;
        _;
    }

    modifier OutsourseImmutability() {
        require(msg.sender == tx.origin, "You are not an external account in Ethereum.");
        _;
    }

    function isAuctioninProgress() public returns (bool) {
        if (block.timestamp > orderdetail.Deadline) {
            auction_state = false;
        }
        return auction_state;
    }

    function RetractMyAuction() public onlyOwner_center {
        //                             RetractAuction       
        auction_state = false;
        auction_retracted = true; // TODO:enum
    }

    modifier normalfunctioned() {
        require(!auction_retracted, "The auction has been retracted.");
        _;
    }
    ///////////////////////////////////////////////////////////////////////////////////////
    //    
    ///////////////////////////////////////////////////////////////////////////////////////

    mapping(address => Bidding) Biddinglist; //   Biddinglist                 
    address[] BiddingAddress; //   BiddingAddress                  Biddinglist                    
    uint public BiddersNum;

    function RaiseBidding(
        uint32 _priceinunit,
        uint32 _quantity
    ) external AuctionOn OutsourseImmutability forbidOwner normalfunctioned {
        RaiseBidding_priv(_priceinunit, _quantity);
    }
    
    function RaiseBidding_priv(
        uint32 _priceinunit,
        uint32 _quantity
    ) internal {
        uint32 epriceinunit = _priceinunit; 
        uint32 equantity = _quantity; 
        uint32 ereservepriceinunit = uint32(orderdetail.Reserve_PriceInUnit); 
        uint32 equantityintotal = uint32(orderdetail.Quantity); 
        uint32 eminimalsplit = uint32(orderdetail.Minimalsplit); 
        bool condition4price = epriceinunit >= ereservepriceinunit; 
        bool condition4enoughquantity = equantity <= equantityintotal; 
        bool condition4splitquantity = eminimalsplit <= equantity;
        bool condition4quantity = condition4enoughquantity && condition4splitquantity;

        require(
            condition4price,
            "The price for the current bidding is invalid, your state of bidding remains unchanged."
        );
        require( 
            condition4quantity,
            "The quantity for the current bidding is invalid, your state of bidding remains unchanged."
        );
        if (!Biddinglist[msg.sender].Liveness) {
            BiddingAddress.push(msg.sender);
        }
        Biddinglist[msg.sender] = Bidding(epriceinunit, equantity, block.timestamp, true);
    }

    function RetractBidding() external AuctionOn OutsourseImmutability forbidOwner normalfunctioned {
        RetractBidding_priv();
    }

    function RetractBidding_priv() internal {
        Biddinglist[msg.sender].Liveness = false;
        Biddinglist[msg.sender].Bidding_Time = 0;
    }

    function CipherLinearization(Bidding memory bidding) private pure returns (uint32) {
        uint32 conpensatedprice = bidding.PriceInUnit * 2 ^ 16; 
        return conpensatedprice + bidding.Quantity;
    }

    function List_Sorting(address[] memory biddingaddress) private view returns (address[] memory) {
      
        uint lengthoflist = biddingaddress.length;
        uint nullindex = lengthoflist; 
        for (uint i = 0; i < lengthoflist - 1; i++) {
            uint flagindex = i; 
            for (uint j = i + 1; j < lengthoflist - 2; j++) {
                if (Biddinglist[biddingaddress[j]].Bidding_Time < Biddinglist[biddingaddress[flagindex]].Bidding_Time) {
                    flagindex = j; 
                }
            }
            if (flagindex != i) {
                (biddingaddress[i], biddingaddress[flagindex]) = (biddingaddress[flagindex], biddingaddress[i]);
            }
            if (Biddinglist[biddingaddress[i]].Bidding_Time == 0) {
                nullindex = i;
            }
        }
        if (nullindex != lengthoflist) {
            address[] memory supportbiddingaddress = new address[](lengthoflist - nullindex - 1);
            for (uint k = 0; k < lengthoflist - nullindex - 1; k++) {
                supportbiddingaddress[k] = biddingaddress[k + nullindex + 1];
            }
            return supportbiddingaddress;
        } else {
            return biddingaddress;
        }
    }

    function FindWinner(
    ) public onlyOwner_self AuctionOff normalfunctioned returns (TopBidder4seller[] memory, address[] memory) {
        (TopBidder4seller[] memory SortedTopBidders4seller, address[] memory BiddingAddress) = FindWinner_priv();
        return FindWinner_callback(SortedTopBidders4seller, BiddingAddress);
    }

    function FindWinner_callback(TopBidder4seller[] memory SortedTopBidders4seller, address[] memory BiddingAddress
    ) internal returns (TopBidder4seller[] memory, address[] memory) {
      return (SortedTopBidders4seller, BiddingAddress);
    }

    function FindWinner_priv(
    ) internal returns (TopBidder4seller[] memory, address[] memory) {
        uint8 TrunctionNumber = uint8(orderdetail.Quantity / orderdetail.Minimalsplit); 
        BiddingAddress = List_Sorting(BiddingAddress); 
        BiddersNum = BiddingAddress.length;
        if (BiddersNum == 0) {
            auction_state = false;
            orderdetail.Deadline = orderdetail.Deadline + 86400;
        }
        ExtractedFinal[] memory SortedFinalBiddings = new ExtractedFinal[](TrunctionNumber);
        for (uint8 i = 0; i < TrunctionNumber; i++) {
            SortedFinalBiddings[i] = ExtractedFinal(0, 0);
        }
        for (uint j = 0; j < BiddersNum; j++) {
            Bidding memory currentbidding = Biddinglist[BiddingAddress[j]]; 
            uint32 currentlinearizedbidding = CipherLinearization(currentbidding); 
            bool[] memory SortConditions = new bool[](TrunctionNumber + 1); 
            for (uint k = 0; k < TrunctionNumber; k++) {
                SortConditions[k] = currentlinearizedbidding > SortedFinalBiddings[k].Linearized_Ciphertext;
            }
            SortConditions[TrunctionNumber] = false;
            for (uint t = 0; t < TrunctionNumber; t++) {
                ExtractedFinal memory currentprocessing = SortedFinalBiddings[t]; 
                SortedFinalBiddings[t] = ExtractedFinal(
                        SortConditions[t] && !SortConditions[t + 1]? uint8(j):uint8(currentprocessing.Bidder_Cindex),
                        SortConditions[t] && !SortConditions[t + 1]? currentlinearizedbidding: currentprocessing.Linearized_Ciphertext
                );
            }
        }
        TopBidder4seller[] memory SortedTopBidders4seller = new TopBidder4seller[](TrunctionNumber); 
        for (uint l = 0; l < TrunctionNumber; l++) {
            SortedTopBidders4seller[l] = TopBidder4seller(
                uint8(SortedFinalBiddings[l].Bidder_Cindex),
               uint8(SortedFinalBiddings[l].Linearized_Ciphertext)
            );
        }
     
        return (SortedTopBidders4seller, BiddingAddress);
    }
}