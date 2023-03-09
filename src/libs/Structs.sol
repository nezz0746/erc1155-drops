// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

enum DropType {
    Public,
    TokenGated,
    Allowlist
}

struct Drop {
    bool isLive;
    string dropUri;
    DropType dropType;
    bytes dropData;
}

struct PublicDropSettings {
    uint256 price;
    uint256 maxSupply;
    uint256 maxPerWallet;
}

struct PublicDropMintSettings {
    uint256 amount;
    address to;
}

struct ERC721GatedDropSettings {
    uint256 price;
    uint256 maxSupply;
    uint256 maxPerWallet;
    address tokenAddress;
}

struct ERC721GatedDropMintSettings {
    uint256 amount;
    address to;
}

struct AllowlistDropSettings {
    uint256 price;
    bytes32 listMerkleRoot;
}

struct AllowlistDropMintSettings {
    uint256 amount;
    address to;
    bytes32[] proof;
}
