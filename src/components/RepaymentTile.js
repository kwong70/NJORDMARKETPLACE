import Navbar from "./Navbar";
import axie from "../tile.jpeg";
import { useLocation, useParams } from "react-router-dom";
import MarketplaceJSON from "../Marketplace.json";
import { uploadFileToIPFS, uploadJSONToIPFS } from "../pinata";
import axios from "axios";
import { useEffect } from "react";


export default function RepaymentTile(props) {
    const [nftData, updateNFTData] = (false);
    useEffect(() => {
        console.log(props.tokenId);
        // Update the document title using the browser API
        //getNFTData();
    }, []);

    // async function getNFTData() {
    //     const tokenId = props.tokenId;
    //     const ethers = require("ethers");
    //     //After adding your Hardhat network to your metamask, this code will get providers and signers
    //     const provider = new ethers.providers.Web3Provider(window.ethereum);
    //     const signer = provider.getSigner();
    //     const addr = await signer.getAddress();
    //     //Pull the deployed contract instance
    //     let contract = new ethers.Contract(
    //       MarketplaceJSON.address,
    //       MarketplaceJSON.abi,
    //       signer
    //     );
    //     //create an NFT Token
    //     const tokenURI = await contract.tokenURI(tokenId);
    //     const listedToken = await contract.getListedTokenForId(tokenId);
    //     let meta = await axios.get(tokenURI);
    //     meta = meta.data;
    //     let prettyPrice = ethers.utils.formatUnits(
    //       listedToken.price.toString(),
    //       "ether"
    //     );
    //     let item = {
    //       price: prettyPrice,
    //       tokenId: tokenId,
    //       seller: listedToken.seller,
    //       owner: listedToken.owner,
    //       image: meta.image,
    //       name: meta.name,
    //       description: meta.description,
    //       nftState: listedToken.nftState,
    //       tokenURI: tokenURI,
    //       repayment: listedToken.repayment
    //     };
    //     updateNFTData(item);
    //     console.log(nftData)
    // }


}