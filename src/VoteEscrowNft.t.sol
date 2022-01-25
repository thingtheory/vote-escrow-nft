// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./BasicERC20.sol";
import "./VoteEscrowNft.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IHevm {
    // Set timestamp to x
    function warp(uint x) external;
    // Set block to x
    function roll(uint x) external;
    //  Sets the slot loc of contract c to val
    function store(address c, bytes32 loc, bytes32 val) external;
    // Reads the slot loc of contract c
    function load(address c, bytes32 loc) external returns (bytes32 val);
    // Signs the digest using the private key sk.
    // Note that signatures produced via hevm.sign will leak the private key.
    function sign(uint sk, bytes32 digest)
        external returns (uint8 v, bytes32 r, bytes32 s);
    // Derives an ethereum address from the private key sk.
    // Note that hevm.addr(0) will fail with BadCheatCode as
    // 0 is an invalid ECDSA private key.
    function addr(uint sk) external returns (address addr);
    // Executes the arguments as a command in the system shell and returns stdout.
    // --ffi flag is required
    function ffi(string[] calldata) external returns (bytes memory);
}

contract VoteEscrowNftTest is DSTest, IERC721Receiver {
    VoteEscrowNft nft;
    BasicERC20 underlying;
    IHevm hevm;
    uint256 firstEpochTime;
    uint expect = 958904109588902400;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
      return this.onERC721Received.selector;
    }

    function setUp() public {
      hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
      underlying = new BasicERC20("Foobar", "FOO", 18);
      underlying.mint(address(this), 1000 ether);
      nft = new VoteEscrowNft(address(underlying), 10);
    }

    function test_mint() public {
      underlying.approve(address(nft), 150 ether);
      uint id = nft.mint(50 ether, 2);
    }

    function test_token_for_owner() public {
      underlying.approve(address(nft), 150 ether);
      uint id = nft.mint(50 ether, 2);
      assertEq(nft.tokenOfOwnerByIndex(address(this), 0), id);
      id = nft.mint(50 ether, 2);
      assertEq(nft.tokenOfOwnerByIndex(address(this), 1), id);
    }

    function test_total_weight() public {
      underlying.approve(address(nft), 150 ether);
      nft.mint(50 ether, 2);
      nft.mint(50 ether, 2);
      assertEq(nft.totalWeight(), 4*expect);
    }

    function test_weight_of() public {
      underlying.approve(address(nft), 150 ether);
      uint id = nft.mint(50 ether, 1);
      assertEq(nft.weightOf(id), expect);
      id = nft.mint(50 ether, 2);
      assertEq(nft.weightOf(id), 2*expect);
      id = nft.mint(50 ether, 3);
      assertEq(nft.weightOf(id), 3*expect);
    }

    function test_weight_decays() public {
      underlying.approve(address(nft), 100 ether);
      uint id = nft.mint(50 ether, 4);
      assertEq(nft.weightOf(id), expect*4);
      hevm.warp(block.timestamp + 1 weeks);
      assertEq(nft.weightOf(id), expect*3);
      hevm.warp(block.timestamp + 1 weeks);
      assertEq(nft.weightOf(id), expect*2);
      hevm.warp(block.timestamp + 1 weeks);
      assertEq(nft.weightOf(id), expect);
      hevm.warp(block.timestamp + 1 weeks);
      assertEq(nft.weightOf(id), 0);
    }

    function test_redeem() public {
      underlying.approve(address(nft), 100 ether);
      uint bal = underlying.balanceOf(address(this));
      uint id = nft.mint(50 ether, 1);

      assertEq(bal-underlying.balanceOf(address(this)), 50 ether);

      try nft.redeem(id) {
        revert("expected redeem to fail");
      } catch {
      }

      (int128 amount, uint256 end) = nft.locked(id);
      hevm.warp(end);

      assertEq(nft.weightOf(id), 0);
      bal = underlying.balanceOf(address(this));
      nft.redeem(id);
      assertEq(underlying.balanceOf(address(this))-bal, 50 ether);
    }

    function test_increase_lock_length() public {
      underlying.approve(address(nft), 100 ether);
      uint bal = underlying.balanceOf(address(this));
      uint id = nft.mint(50 ether, 1);
      assertEq(nft.weightOf(id), expect);
      nft.increaseLockLength(id, 1);
      assertEq(nft.weightOf(id), 2*expect);
    }
}
