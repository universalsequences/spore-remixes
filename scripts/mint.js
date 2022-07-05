// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { AsksV11__factory } = require("@zoralabs/v3/dist/typechain/factories/AsksV11__factory");
const { IERC721__factory } = require("@zoralabs/v3/dist/typechain/factories/IERC721__factory");
const { ZoraModuleManager__factory } = require("@zoralabs/v3/dist/typechain/factories/ZoraModuleManager__factory");


async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy


  const SporePlayerMinter = await ethers.getContractFactory("SporePlayerMinter");
    let TOKEN_ID = 22;
    let ADDY = "0x525CDD1bE68a707e3FC5eEBCbd36e6A8ee6530D6";
    let sporePlayerMinter = null;
    if (ADDY !== null) {
      console.log('attaching');
      sporePlayerMinter = await SporePlayerMinter.attach(ADDY);
      console.log("Minter attached to:", sporePlayerMinter.address);
    } else {
      console.log("deploying");
      sporePlayerMinter = await SporePlayerMinter.deploy(
          "https://zequencer.mypinata.cloud/ipfs/QmUgvUx2oF2ntnEgRiRG8CqxmcyDHd8JhxLgopAqmcj5ao/"
          );
      await sporePlayerMinter.deployed();
      console.log("Minter deployed to:", sporePlayerMinter.address);
      return;
    }
    console.log("GWEI=",ethers.utils.parseEther("0.01") )
    const options = {value: ethers.utils.parseEther("0.01")}
    const tx = await sporePlayerMinter.mint(
        1,
        2,
        3,
        4,
        "QmWXo3NUrwHjgWrLBbsNLxsTGVPhnguNkEvkC6eoHx5KTk",
        options);

    await tx.wait();
    console.log("mint complete");

    console.log("TokenURI=", await sporePlayerMinter.tokenURI("0x9efe0C372310E179104AA5F478e20355a2538e43", TOKEN_ID));

    /*
    const _tx = await sporePlayerMinter.setRecipientAddress("0xBB416E0da90df72C17Af5E0a7782367f7ED2f425");
    await _tx.wait();
    */
    
    console.log("WITHDRAWING");
    const _tx = await sporePlayerMinter.withdraw();
    await _tx.wait();
    console.log("succesfully withdrew");
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

