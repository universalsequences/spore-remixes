const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("ZPlugin");
    const greeter = await Greeter.deploy();
    await greeter.deployed();

    let args = [
      "Retro Computing Test",
      "https://zequencer.io/ipfs/QmVvyPZX8DcLiMu7oDvNBdfuPfqMzmh3WDvNaAUngN5YfE",
      "QmVZNSQSSkLb5LwXccr77Cy7tt6FkV5pfZLCCakfMxWdkM",
      "0x70ccad860073e41ad55e97bd0df5c70ea781d1ad627a9268746ef208e0511a15",
      [
          4,
          4,
          92
      ]
  ]
  await greeter.createPlugin(...args);
    // wait until the transaction is mined
    await setGreetingTx.wait();

  });
});
