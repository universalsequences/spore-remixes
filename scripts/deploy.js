// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { AsksV11__factory } = require("@zoralabs/v3/dist/typechain/factories/AsksV11__factory");
const mainnetZoraAddresses = require("@zoralabs/v3/dist/addresses/4.json"); // Mainnet addresses, 4.json would be Rinkeby Testnet
const { IERC721__factory } = require("@zoralabs/v3/dist/typechain/factories/IERC721__factory");
const { IERC20__factory } = require("@zoralabs/v3/dist/typechain/factories/IERC20__factory");
const { ZoraModuleManager__factory } = require("@zoralabs/v3/dist/typechain/factories/ZoraModuleManager__factory");


async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  const ACCOUNTS = [
    "0x3df0767B5ae12f4Fb08d6ab0C4bbC4dbD88f9818"   ,
    "0x3e2e9604AE811e29b8Fa22B12F67f79eb67D17bA",
    "0x581481184670D0E0B7ed90A8f5cF1Da01eAaCfD5", // checked
    "0xBB416E0da90df72C17Af5E0a7782367f7ED2f425",   
];

  const SporesMinter = await ethers.getContractFactory("SporesMinter");

  const DEPLOYED_ADDRESS = "0x8cf6d785615b472467339e66A4f41c356EbA2558";

  const SPLITS_MAIN_ADDRESS = '0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE';
  const SPORES_MANIFOLD_ADDRESS = '0x9efe0c372310e179104aa5f478e20355a2538e43';
  const ZORA_ASKS_ADDRESS = '0xA98D3729265C88c5b3f861a0c501622750fF4806';
  const SPORES_DAO_ADDRESS = '0xdc94060e37dcb8816188508536595019c8F0C98a';

  let sporesMinter;
  if (DEPLOYED_ADDRESS) {
    sporesMinter = await SporesMinter.attach(DEPLOYED_ADDRESS);
  } else {
    sporesMinter = await SporesMinter.deploy();
    await sporesMinter.deployed();
    console.log("Greeter deployed/ to:", sporesMinter.address);
    await approveAllModules(sporesMinter.address, SPORES_MANIFOLD_ADDRESS);
    return;
  }
  console.log("Greeter deployed/ to:", sporesMinter.address);
 

    const DISTRIBUTER_FEE = 200;

    const tx = await sporesMinter.mintSong(
      SPORES_MANIFOLD_ADDRESS,
      1,
      "0x8599a338944E083dc1bF390A0D8De75309f95Ed0",
      "hello world",
      DISTRIBUTER_FEE,
      ethers.utils.parseEther("0.01"),
      4,
      true
    );

    await tx.wait();
    console.log("SUCCESSFULLY MINTED");

}

const approveAllModules = async (sporesMinterContract, sporesOutputContract) => {

  const accounts = await hre.ethers.getSigners();
  const signer = accounts[0];

  const moduleManagerAddress = mainnetZoraAddresses.ZoraModuleManager;

  const erc721Contract = IERC721__factory.connect(sporesOutputContract, signer);
  console.log("conneted to erc721");
  // Initialize ERC20 currency demo contract
  // Initialize Zora V3 Module Manager contract
  const moduleManagerContract = ZoraModuleManager__factory
    .connect(mainnetZoraAddresses.ZoraModuleManager, signer);
  const erc721TransferHelperAddress = mainnetZoraAddresses.ERC721TransferHelper;


  // first approve the SporesMinter contract as operator for Spores Manifold Contract
  console.log("SETTING spores minter as approved operator for spores manifold");
  let tx = await erc721Contract.setApprovalForAll(sporesMinterContract, true);
  await tx.wait();

  // should go here
  let approved = await erc721Contract.isApprovedForAll(
      accounts[0].address, // NFT owner address
      erc721TransferHelperAddress // V3 Module Transfer Helper to approve
  );
  console.log("token transfer module approved?", approved);

  // If the approval is not already granted, add it.
  if (approved === false) {
      // Notice: Since this interaction submits a transaction to the blockchain it requires an ethers signer.
      // A signer interfaces with a wallet. You can use walletconnect or injected web3.
      console.log("approving token transfer module");
      let tx = await erc721Contract.setApprovalForAll(erc721TransferHelperAddress, true);
      await tx.wait();
  }

  // Approving Asks v1.1
  approved = await moduleManagerContract.isModuleApproved(sporesMinterContract, mainnetZoraAddresses.AsksV1_1);
  console.log("ASKS ARE APPROVED? ", approved);

  if (approved === false) {
    console.log("approving asks module");
    // does this need to happen from the smart contract? we approve this address (i.e. the contract for moving shit)
    let tx = await moduleManagerContract.setApprovalForModule(mainnetZoraAddresses.AsksV1_1, true);
    await tx.wait();
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

