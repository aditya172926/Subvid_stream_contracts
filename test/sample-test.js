const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Subscribe", function () {
  // it("Should return the new greeting once it's changed", async function () {
  //   const Greeter = await ethers.getContractFactory("Greeter");
  //   const greeter = await Greeter.deploy("Hello, world!");
  //   await greeter.deployed();

  //   expect(await greeter.greet()).to.equal("Hello, world!");

  //   const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

  //   // wait until the transaction is mined
  //   await setGreetingTx.wait();

  //   expect(await greeter.greet()).to.equal("Hola, mundo!");

  // });

  it("Should return the movies number", async function() {
     const SubscribeMovie = await ethers.getContractFactory("SubscribeMovie");
     const subscriber = await SubscribeMovie.deploy(5);
     await subscriber.deployed();

     expect (await subscriber.viewMovieQuantity()).to.equal(5);
  });
});
