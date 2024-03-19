// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NoBuNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 99 ether;
  uint256 constant public maxSupply = 2750;
  bool public paused = false;
  uint256[maxSupply] internal availableIds;
  
  address public teamWallet = 0x2713Ebec92C27E52d953b5d5911364b0815dbe05;
  uint256 public ArtistFee = 100; // 10%
  address public ArtistWallet = 0x40A2D2CFd09A6A743a26B808dCbAc8E0a3C183ac;
  address public creatorWallet = 0x89C3e96498efBf91633Eb2E4D36002f61eD805B8;
  uint256 public creatorFee = 200; // 20%
  address public LpWallet = 0x2B48Ff95E577b4dDdd0bFe9473C945D574e4e4E7;
  uint256 public LpFee = 550; // 55%
  uint256 public marketingFee =50; // 5%
  address public marketingWallet = 0xa2Be3029E6168540FC48017F43ec6691faa30E2f;

  uint256 constant SCALE = 1000;

  constructor(string memory _initBaseURI) ERC721("NoBuNFT", "NoBu") {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function _getNewId(uint256 _totalMinted) internal returns(uint256 value) {
    uint256 remaining = maxSupply - _totalMinted;
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
    value += 1;
  } 

  // public
  function mint(uint256 amount) public payable {
      require(!paused, "paused");
      require(amount > 0, "amount shouldn't be zero");
      uint256 supply = totalSupply();
      require(supply + amount <= maxSupply, "Max supply exceeded");
      require(msg.value >= cost * amount, "insufficient funds");
      for (uint256 i = 0; i < amount; i++) {
          _safeMint(msg.sender, _getNewId(supply+i));
      }        
  }

  function walletOfOwner(address _owner)
      public
      view
      returns (uint256[] memory)
  {
      uint256 ownerTokenCount = balanceOf(_owner);
      uint256[] memory tokenIds = new uint256[](ownerTokenCount);
      for (uint256 i; i < ownerTokenCount; i++) {
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokenIds;
  }

  function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
  {
      require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
      );

      string memory currentBaseURI = _baseURI();
      return
          bytes(currentBaseURI).length > 0
              ? string(
                  abi.encodePacked(
                      currentBaseURI,
                      tokenId.toString(),
                      baseExtension
                  )
              )
              : "";
  }

  function setCost(uint256 _newCost) public onlyOwner {
      cost = _newCost;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension)
      public
      onlyOwner
  {
      baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
      paused = _state;
  }

  //
  function mintCost(address)
      external
      view
      returns (uint256)
  {
      return cost;
  }

  function setTeamWallet(address account) external onlyOwner {
    teamWallet = account;
  }

  function airdropNFTs(
    address[] memory _holders,
    uint256[] memory _counts
  ) external onlyOwner {
    require(_holders.length == _counts.length, "Input Data error");
    uint256 _tokenId = totalSupply();
    for (uint256 i = 0; i < _holders.length; i++) {
      for (uint256 j = 0; j < _counts[i]; j++) {
        _mint(_holders[i], _tokenId+1);
        availableIds[_tokenId] = maxSupply - _tokenId - 1;
        _tokenId++;
      }
    }
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
}
