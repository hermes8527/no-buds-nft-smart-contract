// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract NoBuddies is ERC1155, Ownable {
  
  uint256 public mintRate = 99 ether;
  uint256[] public minted = [0, 0, 0, 0];
  uint256[] public supplies = [250, 500, 875, 1125];
  uint256[] public tokenIds;
  uint256 constant public MAX_SUPPLY = 2750;
  uint256[MAX_SUPPLY] internal availableIds;
  uint256 public totalMinted;

  address public teamWallet = 0x2713Ebec92C27E52d953b5d5911364b0815dbe05;

  uint256 public PUBLICSALE = 1660827600 ; // Aug 18 2022 9 AM est

  uint256 public ArtistFee = 100; // 10%
  address public ArtistWallet = 0x40A2D2CFd09A6A743a26B808dCbAc8E0a3C183ac;
  address public creatorWallet = 0x89C3e96498efBf91633Eb2E4D36002f61eD805B8;
  uint256 public creatorFee = 200; // 20%
  address public LpWallet = 0x2B48Ff95E577b4dDdd0bFe9473C945D574e4e4E7;
  uint256 public LpFee = 550; // 55%
  uint256 public marketingFee =50; // 5%
  address public marketingWallet = 0xa2Be3029E6168540FC48017F43ec6691faa30E2f;

  uint256 constant SCALE = 1000;

  constructor() ERC1155("") {}

  struct TokenInfo{
    uint id;
    uint count;
    uint max;
  }

  function setURI(string memory newuri) public onlyOwner {
     _setURI(newuri);
  }

  function _getNewId(uint _totalMinted) internal returns(uint256 value) {
    uint256 remaining = MAX_SUPPLY - _totalMinted;
    uint256 rand = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, remaining))) % remaining;
    value = 0;
    // if array value exists, use, otherwise, use generated random value
    if (availableIds[rand] != 0)
      value = availableIds[rand];
    else
      value = rand;
    // store remaining - 1 in used ID to create mapping
    if (availableIds[remaining - 1] == 0)
      availableIds[rand] = remaining - 1;
    else
      availableIds[rand] = availableIds[remaining - 1];
    uint256 i = 1;
    while(value >= supplies[i]) {
      value -= supplies[i];
      i ++;
    }
    return i;
  } 

  function mint(uint256 amount) public payable {
    require(msg.value >= (amount * mintRate), "Insufficient Fund");
    require(totalMinted + amount <= MAX_SUPPLY, "Limit exceed");
    for (uint i = 0; i < amount; i++ ) {
      uint256 id = _getNewId(totalMinted+i);
      _mint(msg.sender, id, 1, "");
    }
    totalMinted += amount;
  }

  function burn(
      address from,
      uint256 id,
      uint256 amount
  ) public onlyOwner {
      _burn(from, id, amount);
  }
    
  function setMintrate(uint256 _newMintrate) public onlyOwner {
      mintRate = _newMintrate;
  }

  function walletOfOwner(address from) public view returns (TokenInfo[] memory){
    uint256 i = 0;
    uint256 count = 0;
    while (i < 4){
      if(balanceOf(from, i) > 0) count++;
      i++;
    }

    TokenInfo[] memory tokenIDs = new TokenInfo[](count);
    uint256 balance;
    uint256 tokenIdx = 0;
    for (i = 0; i < 4; i++) {
      balance = balanceOf(from, i);
      if (balance > 0) {
        tokenIDs[tokenIdx] = TokenInfo(i, balance, supplies[i]);
        tokenIdx++;
      }
    }
    
    return tokenIDs;
  }

  function withdraw() external {
    uint256 balance = address(this).balance;
    uint256 artist = balance * ArtistFee / SCALE;
    uint256 creator = balance * creatorFee / SCALE;
    uint256 lp = balance * LpFee / SCALE;
    uint256 marketing = balance * marketingFee / SCALE;
    
    (bool sent,) = payable(ArtistWallet).call{value: artist}("");
    require(sent, "Sending eth failed");
    (sent, ) = payable(creatorWallet).call{value: creator}("");
    require(sent, "Sending eth failed");
    (sent, ) = payable(LpWallet).call{value: lp}("");
    require(sent, "Sending eth failed");
    (sent, ) = payable(marketingWallet).call{value: marketing}("");
    require(sent, "Sending eth failed");
    (sent, ) = payable(teamWallet).call{value: address(this).balance}("");
    require(sent, "Sending eth failed");
  }

  function setTeamWallet(address account) external onlyOwner {
    teamWallet = account;
  }

  function airdropNFTs(
    address[] memory _holders,
    uint256[] memory _counts
  ) external onlyOwner {
    require(_holders.length == _counts.length, "Input Data error");
    for (uint256 i = 0; i < _holders.length; i++) {
      _mint(_holders[i], 0, _counts[i], "");
      totalMinted += _counts[i];
    }
  }

}