// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TimeDecayLockedWeight.sol";

contract VoteEscrowNft is ERC721Enumerable, TimeDecayLockedWeight, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public immutable underlying;

  uint256 public nextID;

  mapping(uint256 => uint256) public ownedIdx;
  mapping(address=> mapping(uint256 => uint256)) public owned;

  constructor(address underlyingToken, uint256 maxLockLength_) ERC721("foo", "foo") TimeDecayLockedWeight(underlyingToken, maxLockLength_) {
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
    _safeMint(msg.sender, id);
    _createLock(msg.sender, id, amount, block.timestamp + (length * 1 weeks));

    return id;
  }

  function redeem(uint256 id) public nonReentrant {
    require(_isApprovedOrOwner(msg.sender, id), "Not approved");

    _burn(id);
    _withdraw(msg.sender, id);
  }

  function increaseLockLength(uint256 id, uint256 length) public nonReentrant {
    require(_isApprovedOrOwner(msg.sender, id), "Not approved");
    LockedBalance memory lock = locked[id];
    _increaseLockLength(msg.sender, id, lock.end + (length * 1 weeks));
  }
}
