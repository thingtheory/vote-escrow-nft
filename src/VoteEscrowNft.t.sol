// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./VoteEscrowNft.sol";

contract VoteEscrowNftTest is DSTest {
    VoteEscrowNft nft;

    function setUp() public {
        nft = new VoteEscrowNft();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
