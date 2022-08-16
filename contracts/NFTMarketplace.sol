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

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        NFTState nftState;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        NFTState nftState
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
            NFTState.HOLD
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
            tokenMetaData.nftState
        );
    }

    function listToken(uint256 tokenId, uint price) public returns (ListedToken memory) {
        // get the token 
        ListedToken memory nft = idToListedToken[tokenId];
        // check if user owns/has the ability to sell nft 
        require(idToListedToken[tokenId].seller == msg.sender, "You do not have rights to sell the NFT");
        // set the nft state to sell 
        nft.nftState = NFTState.SELL;
        // overwrite the sell price 
        nft.price = price;
        // write/update nft details back to memory
        idToListedToken[tokenId] = nft; 
        //update the current selling nft counter 
        _itemsOnTheMarket.increment();

        return nft;
    }

    function updateTokenPrice(uint256 tokenId, uint price) public returns (ListedToken memory) {
        // get the token 
        ListedToken memory nft = idToListedToken[tokenId];
        // check if user owns/has the ability to sell nft 
        require(idToListedToken[tokenId].seller == msg.sender, "You do not have rights to update the NFT");
        // overwrite the sell price 
        nft.price = price;
        // write/update nft details back to memory
        idToListedToken[tokenId] = nft; 
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
            if(idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender){
                itemCount++;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=1; i <= totalItemCount; i++) {
            if(idToListedToken[i].owner == msg.sender || idToListedToken[i].seller == msg.sender) {
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
        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    }

    //We might add a resell token function in the future
    //In that case, tokens won't be listed by default but users can send a request to actually list a token
    //Currently NFTs are listed by default
}
