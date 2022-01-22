// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IVoteEscrow {
  function votingPower(uint256) external view returns (uint256);
  function totalVotingPower() external view returns (uint256);
}

contract VoteEscrowNft is IVoteEscrow, ERC721, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public immutable underlying;
  uint256 public immutable firstEpochTime;
  uint256 public immutable epochLength;

  uint256 public override totalVotingPower;
  uint256 public totalAmount;
  uint256 public totalDecay;
  uint256 public totalLength;
  uint256 public lastUpdateEpoch;
  uint256 public nextID;
  uint256[] public tokens;
  mapping(uint256 => Lock) public locks;

  struct Lock {
    uint256 amount;
    uint256 startTime;
    uint32 length;
  }

  constructor(address underlyingToken, uint256 firstEpochTime_, uint256 epochLength_) ERC721("foo", "foo") {
    require(underlyingToken != address(0), "Underlying token cannot be zero");
    underlying = IERC20(underlyingToken);
    require(firstEpochTime_ >= block.timestamp);
    firstEpochTime = firstEpochTime_;
    require(epochLength_ > 0);
    epochLength = epochLength_;
  }

  function tokenURI(uint256 id) public pure override returns (string memory) {
    return string(abi.encodePacked("foo://", Strings.toString(id)));
  }

  function currentEpoch() public view returns (uint256) {
    if (firstEpochTime >= block.timestamp) {
      return 0;
    }
    return (block.timestamp - firstEpochTime) / epochLength;
  }

  function nextEpochTime() public view returns (uint256) {
    if (firstEpochTime >= block.timestamp) {
      return firstEpochTime + epochLength;
    }
    return ((currentEpoch() + 1) * epochLength) + firstEpochTime;
  }

  function votingPower(uint256 id) public view override returns (uint256) {
    Lock memory lock = locks[id];
    return lock.amount * lock.length;
  }

  function mint(uint256 amount, uint32 length) public nonReentrant returns (uint256) {
    require(amount > 0, "Amount zero");
    require(length > 0, "Length zero");

    uint256 id = nextID;
    nextID++;

    locks[id] = Lock({
      amount: amount,
      length: length,
      startTime: nextEpochTime()
    });
    totalVotingPower = totalVotingPower + (amount*length);
    _safeMint(msg.sender, id);
    underlying.safeTransferFrom(msg.sender, address(this), amount);

    return id;
  }

  function redeem(uint256 id) public nonReentrant {
    require(_isApprovedOrOwner(msg.sender, id), "Not approved");
    require(votingPower(id) == 0, "Lock not expired");

    Lock memory lock = locks[id];
    uint256 amount = lock.amount;
    uint256 length = lock.length;

    totalVotingPower = totalVotingPower - (amount*length);

    _burn(id);
    delete locks[id];

    underlying.transfer(msg.sender, amount);
  }
}
