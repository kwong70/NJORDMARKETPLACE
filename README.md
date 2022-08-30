# Basic NFT Marketplace end to end

This code is for the Tutorial [Build your own NFT Marketplace from Scratch](https://docs.alchemy.com/alchemy/) built by [alchemy.com](https://alchemy.com)

To set up the repository and run the marketplace locally, run the below
```bash
git clone https://github.com/OMGWINNING/NFT-Marketplace-Tutorial
cd NFT-Marketplace-Tutorial
npm install
npm start
```


Pinata Keys 
API Key: ba6e11bbd4912a106e70
API Secret: ccf7d1dbd9ca31d28121531b7b7d9658885dc02282069a34335fd95c04691514
JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJjNTE5MGI4ZS02OGY1LTRkNTItOGMwMi1jNWQzMTdhNzQwZTMiLCJlbWFpbCI6ImtlbmRhbGx3b25nMUBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJpZCI6IkZSQTEiLCJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MX0seyJpZCI6Ik5ZQzEiLCJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MX1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiYmE2ZTExYmJkNDkxMmExMDZlNzAiLCJzY29wZWRLZXlTZWNyZXQiOiJjY2Y3ZDFkYmQ5Y2EzMWQyODEyMTUzMWI3YjdkOTY1ODg4NWRjMDIyODIwNjlhMzQzMzVmZDk1YzA0NjkxNTE0IiwiaWF0IjoxNjU5NDAyMjgwfQ.4zj8PXSgH0dGc5EPAxFMsNTby4aMPxszaaFOEdMxF1k

Deploying smart contract: 
1st time:
- create alchemy account get creds 
- in hardhat.config.js set a pointer to your alchemy account: url 
- get your wallet private key and add it to hardhat config too 
- gaulifaucet to add fake money to your wallet 

Everytime: 
- npx hardhat run --network goerli scripts/deploy.js
    - this command will deploy the smart contract on the network given 
    - it will also create/overwrite a file called Marketplace.json which has the contract details (addres, interface...) which the front end points to in order to interact with the contract/backend