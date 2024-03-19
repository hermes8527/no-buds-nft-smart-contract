import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import airdropList from '../airdrops';

let holders: any[] = [];
let counts: any[] = [];

airdropList.map((account : any[]) => {
  holders.push(account[0]);
  counts.push(account[1]);
})

async function airdropNFTs(nobu3d: any) {
  let txHandle = await nobu3d.airdropNFTs(holders.slice(0, holders.length/2), counts.slice(0, holders.length/2));
  await txHandle.wait();
  txHandle = await nobu3d.airdropNFTs(holders.slice(holders.length/2), counts.slice(holders.length/2));
  await txHandle.wait()
}

describe("NoBuGe3D", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNoBuddiesFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, nobuholder, wlmember, user, otherAccount] = await ethers.getSigners();

    const NoBuddies = await ethers.getContractFactory("NoBuNFT");
    const nobuddies = await NoBuddies.deploy("https://test.uri/");

    await nobuddies.connect(nobuholder).mint(1, {value: ethers.utils.parseEther('99')});

    const NoBuGen3D = await ethers.getContractFactory("NoBuGen3D");
    const nobu3d = await NoBuGen3D.deploy("https://test.uri/", nobuddies.address);

    await nobu3d.setWhitelisted(wlmember.address, true);

    return { nobu3d, nobuddies, owner, nobuholder, wlmember, user, otherAccount };
  }

  describe("Deployment", function () {
    it("Should mint 3321 ~ 3333 to team wallet", async function () {
      const { nobu3d } = await loadFixture(deployNoBuddiesFixture);

      await expect(await nobu3d.totalSupply()).to.be.equal(13);
      const teamWallet = await nobu3d.teamWallet();
      await expect(await nobu3d.balanceOf(teamWallet)).to.be.equal(13);
    });

    it("Should airdrop random nfts", async function () {
        const { nobu3d } = await loadFixture(deployNoBuddiesFixture);
        await airdropNFTs(nobu3d);
        await expect(await nobu3d.totalSupply()).to.be.equal(263);
        // console.log(await nobu3d.walletOfOwner(holders[0]));
        await expect(await nobu3d.balanceOf(holders[0])).to.be.equal(counts[0]);
        const lastIdx = holders.length - 1;
        await expect(await nobu3d.balanceOf(holders[lastIdx])).to.be.equal(counts[lastIdx]);
        await expect(await nobu3d.balanceOf(holders[lastIdx/2])).to.be.equal(counts[lastIdx/2]);
    });

    it("Should able to get correct cost", async function() {
      const { nobu3d, nobuholder, wlmember, user } = await loadFixture(deployNoBuddiesFixture);
      await expect(await nobu3d.mintCost(user.address)).to.be.equal(ethers.utils.parseEther('499'));
      await expect(await nobu3d.mintCost(wlmember.address)).to.be.equal(ethers.utils.parseEther('449'));
      await expect(await nobu3d.mintCost(nobuholder.address)).to.be.equal(ethers.utils.parseEther('399'));

      let mintCost = await nobu3d.mintCost(user.address);
      const price = mintCost.mul(2);
      await nobu3d.connect(user).mint(2, {value: price.toString()});
      await expect(await nobu3d.balanceOf(user.address)).to.be.equal(2);
      mintCost = await nobu3d.mintCost(wlmember.address);
      await nobu3d.connect(wlmember).mint(2, {value: mintCost.mul(2).toString()});
      await expect(await nobu3d.balanceOf(wlmember.address)).to.be.equal(2);
      mintCost = await nobu3d.mintCost(nobuholder.address);
      await nobu3d.connect(nobuholder).mint(2, {value: mintCost.mul(2).toString()});
      await expect(await nobu3d.balanceOf(nobuholder.address)).to.be.equal(2);

      await expect(nobu3d.mint(2, {value: '1000000'})).to.revertedWith(
        "insufficient funds"
      );
    });

    it("Should not mint more than 3333", async function() {
      const { nobu3d } = await loadFixture(deployNoBuddiesFixture);
      await airdropNFTs(nobu3d);
      await nobu3d.setCost('10000000000000000');
      for (let i = 0; i < 307; i++)
        await nobu3d.mint(10, {value: '100000000000000000'});
      await expect(await nobu3d.totalSupply()).to.equal(3333);
      await expect(nobu3d.mint(1, {value: '10000000000000000'})).to.revertedWith(
        "Max supply exceeded"
      );
    });

    it("Should withdraw exactly", async function() {
      const { nobu3d, owner } = await loadFixture(deployNoBuddiesFixture);
      await nobu3d.setCost('10000000000000000');
      for (let i = 0; i < 10; i++)
        await nobu3d.mint(10, {value: '100000000000000000'});
        await nobu3d.setTeamWallet(owner.address);
        await expect(nobu3d.withdraw()).to.changeEtherBalance(
            owner,
            '150000000000000000'
          )
    });

    it("Should return exact token uri", async function() {
      const { nobu3d } = await loadFixture(deployNoBuddiesFixture);
      await expect(await nobu3d.tokenURI(3333)).to.be.equal("https://test.uri/3333.json");
    });

    it("Should be able to update mint costs", async function() {
      const { nobu3d, nobuholder, wlmember, user } = await loadFixture(deployNoBuddiesFixture);
      await nobu3d.setCost(ethers.utils.parseEther('199'));
      await nobu3d.setWlCost(ethers.utils.parseEther('149'));
      await nobu3d.setMemberCost(ethers.utils.parseEther('99'));
      await expect(await nobu3d.mintCost(user.address)).to.be.equal(ethers.utils.parseEther('199'));
      await expect(await nobu3d.mintCost(wlmember.address)).to.be.equal(ethers.utils.parseEther('149'));
      await expect(await nobu3d.mintCost(nobuholder.address)).to.be.equal(ethers.utils.parseEther('99'));
    });
  });
});
