// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TimeDecayLockedWeight.sol";

contract VoteEscrowNft is ERC721, TimeDecayLockedWeight, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public immutable underlying;

  uint256 public nextID;

  uint256[] public ownedIdx;
  mapping(address=>uint256[]) public owned;

  constructor(address underlyingToken) ERC721("foo", "foo") TimeDecayLockedWeight(underlyingToken) {
    require(underlyingToken != address(0), "Underlying token cannot be zero");
    underlying = IERC20(underlyingToken);
  }

  function tokenURI(uint256 id) public pure override returns (string memory) {
    return string(abi.encodePacked("foo://", Strings.toString(id)));
  }

  function mint(uint256 amount, uint32 length) public nonReentrant returns (uint256) {
    require(amount > 0, "Amount zero");
    require(length > 0, "Length zero");

    uint256 id = nextID;
    nextID++;
    owned[msg.sender].push(id);
    _safeMint(msg.sender, id);
    _createLock(msg.sender, id, amount, block.timestamp + (length * 1 weeks));

    return id;
  }

  function _addTokenForOwner(address owner_, uint256 id) internal {
    owned[owner_].push(id);
    ownedIdx[id] = owned[owner_].length - 1;
  }

  function _removeTokenForOwner(address owner_, uint256 id) internal {
    uint256[] memory temp = owned[owner_];
    uint idx = ownedIdx[id];
    temp[idx] = temp[temp.length-1];
    delete temp[temp.length-1];
    owned[owner_] = temp;
  }

  function redeem(uint256 id) public nonReentrant {
    require(_isApprovedOrOwner(msg.sender, id), "Not approved");

    _removeTokenForOwner(msg.sender, id);
    _burn(id);
    _withdraw(msg.sender, id);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    super.transferFrom(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    super.safeTransferFrom(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) public override {
    super.safeTransferFrom(from, to, id, data);
  }

  function tokenForOwner(address owner_, uint256 idx) public view returns(uint256) {
    return owned[owner_][idx];
  }
}
