import Navbar from "./Navbar";
import axie from "../tile.jpeg";
import { useLocation, useParams } from "react-router-dom";
import MarketplaceJSON from "../Marketplace.json";
import { uploadFileToIPFS, uploadJSONToIPFS } from "../pinata";
import axios from "axios";
import { useState, useEffect } from "react";
import RepaymentTile from "./RepaymentTile";



export default function NFTPage(props) {
  const [data, updateData] = useState({});
  const [dataFetched, updateDataFetched] = useState(false);
  const [message, updateMessage] = useState("");
  const [currAddress, updateCurrAddress] = useState("0x");
  const [showSellForm, updateShowSellForm] = useState(false);
  const [showBNPLForm, updateShowBNPLForm] = useState(false);
  const [newSellPrice, updateNewSellPrice] = useState(0.0);
  const [repaymentAmount, updateRepaymentAmount] = useState(0.0);
  const [BNPLDetails, updateBNPLDetails] = useState({});
  const interest = 0.05;

  async function getNFTData(tokenId) {
    const ethers = require("ethers");
    //After adding your Hardhat network to your metamask, this code will get providers and signers
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const addr = await signer.getAddress();
    //Pull the deployed contract instance
    let contract = new ethers.Contract(
      MarketplaceJSON.address,
      MarketplaceJSON.abi,
      signer
    );
    //create an NFT Token
    const tokenURI = await contract.tokenURI(tokenId);
    const listedToken = await contract.getListedTokenForId(tokenId);
    let meta = await axios.get(tokenURI);
    meta = meta.data;
    let prettyPrice = ethers.utils.formatUnits(
      listedToken.price.toString(),
      "ether"
    );

    console.log(listedToken);
    let item = {
      price: prettyPrice,
      tokenId: tokenId,
      seller: listedToken.seller,
      owner: listedToken.owner,
      image: meta.image,
      name: meta.name,
      description: meta.description,
      nftState: listedToken.nftState,
      repayment: listedToken.repayment,
      tokenURI: tokenURI,
    };
    updateDataFetched(true);
    updateData(item);
    updateCurrAddress(addr);
  }

  //This function uploads the metadata to IPDS
  async function uploadMetadataToIPFS() {
    const { name, description, tokenURI } = data;
    //Make sure that none of the fields are empty
    if (!name || !description || !newSellPrice || !tokenURI) return;

    const nftJSON = {
      name,
      description,
      newSellPrice,
      image: tokenURI,
    };

    try {
      //upload the metadata JSON to IPFS
      const response = await uploadJSONToIPFS(nftJSON);
      if (response.success === true) {
        console.log("Uploaded JSON to Pinata: ", response);
        return response.pinataURL;
      }
    } catch (e) {
      console.log("error uploading JSON metadata:", e);
    }
  }

  async function buyNFT(tokenId) {
    try {
      const ethers = require("ethers");
      //After adding your Hardhat network to your metamask, this code will get providers and signers
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      //Pull the deployed contract instance
      let contract = new ethers.Contract(
        MarketplaceJSON.address,
        MarketplaceJSON.abi,
        signer
      );
      const salePrice = ethers.utils.parseUnits(data.price, "ether");
      updateMessage("Buying the NFT... Please Wait (Upto 5 mins)");
      //run the executeSale function
      let transaction = await contract.executeSale(data.tokenId, {
        value: salePrice,
      });
      await transaction.wait();

      alert("You successfully bought the NFT!");
      updateMessage("");
    } catch (e) {
      alert("Upload Error" + e);
    }
  }

  async function BNPLNFT(tokenId) {
    try {
      console.log("here");
      const ethers = require("ethers");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      console.log("1");
      let contract = new ethers.Contract(
        MarketplaceJSON.address, 
        MarketplaceJSON.abi, 
        signer
      );
      let firstPaymentAmount = parseFloat(BNPLDetails.payPeriodLength / BNPLDetails.loanLength) * calculateTotalDue();
      firstPaymentAmount = ethers.utils.parseUnits(firstPaymentAmount.toString(), "ether");
      const totalDue = ethers.utils.parseUnits(calculateTotalDue().toString(), "ether");
      console.log(firstPaymentAmount);
      console.log(totalDue);
      let transaction = await contract.initiateBNPL(data.tokenId, BNPLDetails.loanLength, BNPLDetails.payPeriodLength, totalDue, firstPaymentAmount);
      await transaction.wait();

      alert("You successfully invoked BNPL");
    } catch(e) {
      console.log("Error in BNPLNFT");
      console.log(e);
    }
  }

  

  async function listNFT(e) {
    try {
      e.preventDefault();
      
      const ethers = require("ethers");
      //After adding your Hardhat network to your metamask, this code will get providers and signers
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      
      //Pull the deployed contract instance
      let contract = new ethers.Contract(
        MarketplaceJSON.address,
        MarketplaceJSON.abi,
        signer
      );
      const newSellPriceInEther = ethers.utils.parseUnits(
        newSellPrice,
        'ether'
      );
      let listingPrice = await contract.getListPrice();
      listingPrice = listingPrice.toString();
      //run the executeSale function
      let transaction = await contract.listToken(
        data.tokenId,
        newSellPriceInEther,
        { value: listingPrice }
      );
      await transaction.wait();
      //const metadataURL = await uploadMetadataToIPFS();
      alert("You successfully listed the NFT!");
      updateMessage("You successfully listed the NFT!");
    } catch (e) {
      alert("THERE IS AN Upload Error" + e);
    }
  }

  async function updateNFTPrice(e) {
    try {
      e.preventDefault();
      console.log("Updating price of NFT");
    } catch(e) {
      alert("Error updating NFT price: " + e)
    }
  }

  async function unlistNFT(e) {
    try {
      e.preventDefault();
      console.log("Unlisting NFT");
    } catch(e) {
      alert("Error unlisting NFT: " + e)
    }
  }

  const params = useParams();
  const tokenId = params.tokenId;
  if (!dataFetched) getNFTData(tokenId);
  function sellForm() {
    return (
      <div className="flex flex-col place-items-center mt-10" id="nftForm">
        <form className="bg-white shadow-md rounded px-8 pt-4 pb-8 mb-4">
          <h3 className="text-center font-bold text-purple-500 mb-8">
            Upload your NFT to the marketplace
          </h3>
          <div className="mb-6">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="price"
            >
              Original Price (in ETH): {data.price}
            </label>
          </div>
          <div className="mb-6">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="description"
            >
              Set Price (Eth):{" "}
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              type="number"
              placeholder="Min 0.01 ETH"
              step="0.01"
              value={newSellPrice}
              onChange={(e) => updateNewSellPrice(e.target.value)}
            ></input>
          </div>
          <br></br>
          <div className="text-green text-center">{message}</div>
          <button
            onClick={listNFT}
            className="font-bold mt-10 w-full bg-purple-500 text-white rounded p-2 shadow-lg"
          >
            List NFT
          </button>
        </form>
      </div>
    );
  }
  function convertRepaymentTime() {
    console.log("getCurrentAmountdue");
  }

  function convertPaymentPeriodTime() {
    console.log("getCurrentAmountdue");
  }

  function getCurrentAmountdue() {
    console.log("getCurrentAmountdue");
  }

  function convertSecondsToStringDate(seconds) {
    const secondsInADay = 86400;
    const days = seconds / secondsInADay;
    var date = new Date();
    date.setDate(date.getDate() + days);
    return date.toString().substring(0, 25);
  }

  function handleBNPLSelection(e, loanLength, payPeriodLength) {
    e.preventDefault();
    updateBNPLDetails({"loanLength": loanLength, "payPeriodLength": payPeriodLength});
  }

  function calculateTotalDue() {
    return Math.round((parseFloat(data.price * interest) + parseFloat(data.price)) * 100000) / 100000
  }

  async function makeBNPLPayment() {
      const ethers = require("ethers");
      //After adding your Hardhat network to your metamask, this code will get providers and signers
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      //Pull the deployed contract instance
      let contract = new ethers.Contract(
        MarketplaceJSON.address,
        MarketplaceJSON.abi,
        signer
      );
      const paymentAmount = ethers.utils.parseUnits(repaymentAmount, "ether");
      updateMessage("Making payment... Please Wait (Upto 5 mins)");
      //run the executeSale function
      let transaction = await contract.makeBNPLPayment(data.tokenId, {
        value: paymentAmount,
      });
      await transaction.wait();
      alert("Successfully made payment");
  }

  function BNPLForm() {
    const totalDue = calculateTotalDue();
    const firstPaymentDate = convertSecondsToStringDate(BNPLDetails.payPeriodLength);
    const firstPaymentAmount = parseFloat(BNPLDetails.payPeriodLength / BNPLDetails.loanLength) * calculateTotalDue();
    return (
      <div className="flex flex-col place-items-center mt-10" id="nftForm">
        <div className="bg-white shadow-md rounded px-8 pt-4 pb-8 mb-4">
          <h3 className="text-center font-bold text-purple-500 mb-8">
            BNPL Options
          </h3>
          <div>Total Due (5% interest): {totalDue} eth</div>
          <div>First Payment due: {firstPaymentDate}</div>
          <div>Amount Due: {firstPaymentAmount} eth</div>
          <div className="mb-6">
            <button style={{border: '15px'}} className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={(e) => handleBNPLSelection(e, 7890000, 604800)}>
              3 months | weekly payments
            </button>
            <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={(e) => handleBNPLSelection(e, 2630000, 604800)}> 
              1 month | weekly payments 
            </button>
            <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={(e) => handleBNPLSelection(e, 604800, 86400)}>
              1 week | daily payments
            </button>
          </div>
          <div className="text-green text-center">{message}</div>
          <button onClick={BNPLNFT} className="font-bold mt-10 w-full bg-purple-500 text-white rounded p-2 shadow-lg">
            Buy Now Pay Later
          </button>
        </div>
      </div>
    );
  }
  const ethers = require("ethers");
  return (
    <div style={{ minHeight: "100vh" }}>
      <Navbar></Navbar>
      <div className="flex ml-20 mt-20">
        <h1>{showSellForm && sellForm()}</h1>
        <h1>{showBNPLForm && BNPLForm()}</h1>
        <img src={data.image} alt="" className="w-2/5" />
        <div className="text-xl ml-20 space-y-8 text-white shadow-2xl rounded-lg border-2 p-5">
          <div>Name: {data.name}</div>
          <div>Description: {data.description}</div>
          <div>TokenId: #{data.tokenId}</div>
          <div>
            Price: <span className="">{data.price + " ETH"}</span>
          </div>
          <div>
            Owner: <span className="text-sm">{data.owner}</span>
          </div>
          <div>
            Seller: <span className="text-sm">{data.seller}</span>
          </div>
          <div>
            State:{" "}
            <span className="text-sm">
              {data.nftState === 0
                ? "HOLD"
                : data.nftState === 1
                ? "SELL"
                : data.nftState === 2
                ? "REPAYMENT"
                : "ENUM NOT SUPPORTED"}
            </span>
          </div>
          <div>
            {currAddress == data.owner || currAddress == data.seller || data.nftState == 2 && data.repayment.renter == currAddress ? (
              data.nftState === 0 ? (
                <button
                  className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={() => updateShowSellForm(true)}>
                  Sell
                </button>
              ) : (
                data.nftState === 1 ? (
                  <div>
                    <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={updateNFTPrice}>
                      Update Price
                    </button>
                    <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={unlistNFT}>
                      Unlist NFT
                    </button>
                  </div> 
                ) : (
                  currAddress == data.seller ? (
                    <div className="text-emerald-700">
                      You are loaning
                    </div>
                  ) : (
                    <div> 
                      <div>
                        Amount Paid Off / Total Amount Due:
                      </div>
                      <div>
                        <p  className="text-emerald-700">
                          {ethers.utils.formatUnits(data.repayment.amountPaidOff, "ether")} / {ethers.utils.formatUnits(data.repayment.totalDue, "ether")} eth
                        </p>
                      </div>
                      
                      <div>
                        <button  className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={() => makeBNPLPayment()}>
                          Make Payment
                        </button>
                        <input className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" type="number" placeholder="ETH" step="0.01"  onChange={e => updateRepaymentAmount(e.target.value)} value={repaymentAmount}></input>
                      </div>
                    </div>
                  )
                )
              )
            ) : (
              <div>
                <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={() => buyNFT(tokenId)}>
                  Buy this NFT
                </button>
                <button  className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={() => updateShowBNPLForm(true)}>
                  Buy Now Pay Later
                </button>
              </div>
            )}
            <div className="text-green text-center mt-3">{message}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
