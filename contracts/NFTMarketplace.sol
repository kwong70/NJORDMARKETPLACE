//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    using Counters for Counters.Counter;
    //_tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIds;
    //Keeps track of the number of items sold on the marketplace
    Counters.Counter private _itemsSold;
    //Keep track of the # of NFTs open for sale 
    Counters.Counter private _itemsOnTheMarket;
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 listPrice = 0.01 ether;
    //Enums for state of an NFT 
    enum NFTState { HOLD, SELL, REPAYMENT }
    enum BNPLOutcome { SUCCESS, DEFAULT }

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        NFTState nftState;
        Repayment repayment;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        NFTState nftState, 
        Repayment repayment
    );

    event BNPLPaymentEvent (
        uint256 indexed tokenId,
        uint256 amountPaid,
        uint256 totalAmountPaid,
        uint256 totalDue,
        uint256 startTime, 
        uint256 loanLength,
        uint256 payPeriodAmount,
        uint256 payPeriodLength, 
        address seller, 
        address buyer
    );

    struct Repayment {
        uint256 startTime; // start of the loan time
        uint256 totalDue; // 
        uint256 amountPaidOff; // total amount of loan paid off. amountPaidOff == intitialPrice + (initialPrice * interest) in order to complete loan
        uint256 loanLength; // total length of loan
        uint256 payPeriodLength; // amount of time alotted to pay payPeriodAmount
        uint256 payPeriodAmount; // amount due before payPeriodLength is up
        address renter;
    }

    event BNPLOutcomeEvent (
        uint256 indexed tokenId,
        Repayment repayment,
        address seller, 
        address buyer, 
        BNPLOutcome outcome
    );

    

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    //The first time a token is created, it is listed here
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        //Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        //Mint the NFT with tokenId newTokenId to the address who called createToken
        //_safeMint makes sure the given address can accept NFT... avoids an "address blackhole" 
        _safeMint(msg.sender, newTokenId);

        //Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenURI);

        //Helper function to update Global variables and emit an event
        createTokenHelper(newTokenId, price);

        return newTokenId;
    }

    function createTokenHelper(uint256 tokenId, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Hopefully sending the correct price");
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        ListedToken memory tokenMetaData = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            NFTState.HOLD, 
            Repayment(0,0,0,0,0,0, address(0))
        );

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToListedToken[tokenId] = tokenMetaData;

        _transfer(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenMetaData.tokenId,
            tokenMetaData.owner,
            tokenMetaData.seller,
            tokenMetaData.price,
            tokenMetaData.nftState, 
            tokenMetaData.repayment
        );
    }

    function listToken(uint256 tokenId, uint price) public payable returns (ListedToken memory) {
        require(msg.value == listPrice, "Hopefully sending the correct price");
        // get the token 
        ListedToken storage nft = idToListedToken[tokenId];
        // check if user owns/has the ability to sell nft 
        require(idToListedToken[tokenId].seller == msg.sender, "You do not have rights to sell the NFT");
        // set the nft state to sell 
        nft.nftState = NFTState.SELL;
        // overwrite the sell price 
        nft.price = price;
        //update the current selling nft counter 
        _itemsOnTheMarket.increment();
        emit TokenListedSuccess(
            tokenId,
            nft.owner, 
            nft.seller, 
            nft.price, 
            nft.nftState,
            nft.repayment
        );
        return nft;
    }

    function updateTokenPrice(uint256 tokenId, uint price) public payable returns (ListedToken memory) {
        require(msg.value == listPrice, "Hopefully sending the correct price");
        // get the token 
        ListedToken storage nft = idToListedToken[tokenId];
        // check if user owns/has the ability to sell nft 
        require(idToListedToken[tokenId].seller == msg.sender, "You do not have rights to update the NFT");
        // overwrite the sell price 
        nft.price = price;
        return nft;
    }
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](_itemsOnTheMarket.current());
        uint currentIndex = 0;

        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=1;i<=nftCount;i++) {
            ListedToken storage currentItem = idToListedToken[i];
            if(currentItem.nftState == NFTState.SELL) {
                tokens[currentIndex++] = currentItem;
            }
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }
    
    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=1; i <= totalItemCount; i++) {
            if(idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender || idToListedToken[i].repayment.renter == msg.sender ){
                itemCount++;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=1; i <= totalItemCount; i++) {
            if(idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender || idToListedToken[i].repayment.renter == msg.sender) {
                uint currentId = i;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex++] = currentItem;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToListedToken[tokenId].nftState = NFTState.HOLD;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();
        _itemsOnTheMarket.decrement();

        //Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);
        //give the marketplace the rights to sell the NFT agian in the future on behalf of msg.sender 
        approve(address(this), tokenId);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    }

    function initiateBNPL(uint256 tokenId, uint256 loanLength, uint256 payPeriod, uint256 totalDue, uint256 payPeriodAmount) public payable {
        ListedToken storage nft = idToListedToken[tokenId];
        Repayment memory repaymentDetails = Repayment(
            block.timestamp,
            totalDue,
            0,
            loanLength,
            payPeriod,
            payPeriodAmount,
            msg.sender
        );

        //update the details of the token
        nft.nftState = NFTState.REPAYMENT;
        nft.repayment = repaymentDetails;
        _itemsOnTheMarket.decrement();
    }

    function makeBNPLPayment(uint256 tokenId) public payable {
        ListedToken storage nft = idToListedToken[tokenId];
        Repayment storage repayment = nft.repayment;
        require(repayment.renter ==  msg.sender, "You do not have permission to make a BNPL payment");

        repayment.amountPaidOff += msg.value;
        emit BNPLPaymentEvent(tokenId, msg.value, repayment.amountPaidOff, repayment.totalDue, repayment.startTime, repayment.loanLength, repayment.payPeriodAmount, repayment.payPeriodLength, nft.seller, repayment.renter);

        // handle success
        if(repayment.amountPaidOff >= repayment.totalDue) {
            //Actually transfer the token to the new owner
            _transfer(address(this), msg.sender, tokenId);
            //give the marketplace the rights to sell the NFT agian in the future on behalf of msg.sender 
            approve(address(this), tokenId);
            // Emit Successfull BNPLOutcomeEvent 
            emit BNPLOutcomeEvent(tokenId, repayment, nft.seller, repayment.renter, BNPLOutcome.SUCCESS);
            // Update application state
            _itemsSold.increment();
            nft.repayment =  Repayment(0,0,0,0,0,0, address(0));
            nft.nftState = NFTState.HOLD;
            nft.seller = payable(msg.sender);
        } 

        //Transfer the proceeds from the sale to the seller of the NFT
        payable(nft.seller).transfer(msg.value);

    }

    
}
