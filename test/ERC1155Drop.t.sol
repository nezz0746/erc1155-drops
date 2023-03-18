// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Merkle } from "@murky/Merkle.sol";
import { ERC721 } from "@openzeppelin-contracts/token/ERC721/ERC721.sol";
import { DSTestFull } from "./DSTestFull.sol";
import { ERC1155Drop } from "src/ERC1155Drop.sol";
import { IERC1155Drop } from "src/libs/IERC1155Drop.sol";
import { DropType } from "src/libs/Structs.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockERC721", "M721") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract ERC1155DropTests is DSTestFull, IERC1155Drop {
    address admin;
    address payable treasury;

    address listed1;
    address listed2;
    address listed3;

    ERC1155Drop drops;
    MockERC721 mockERC721A;

    uint256 publicMintPrice = 0.01 ether;
    uint256 publicMaxSupply = 100;
    uint256 publicMaxPerWallet = 10;

    function setUp() public virtual {
        admin = msg.sender;
        treasury = payable(admin);

        drops = new ERC1155Drop(admin, treasury);

        listed1 = label("listed1");
        listed2 = label("listed2");
        listed3 = label("listed3");

        vm.startPrank(admin);
        drops.createDrop(
            DropType.Public,
            "ipfs://bafkreiepxqvixhkaqd4tr4uym6q6wyvxcwai7ethmhieompdnlrcldc6rm",
            abi.encode(publicMintPrice, publicMaxSupply, publicMaxPerWallet)
        );

        mockERC721A = new MockERC721();

        drops.createDrop(
            DropType.TokenGated,
            "ipfs://bafkreiepxqvixhkaqd4tr4uym6q6wyvxcwai7ethmhieompdnlrcldc6rm",
            abi.encode(publicMintPrice, publicMaxSupply, publicMaxPerWallet, address(mockERC721A))
        );

        vm.stopPrank();
    }
}

contract Unit_ERC1155Drops_CreateDrop is ERC1155DropTests {
    function testCreateDrop() public {
        string memory uri = "ipfs://bafkreiepxqvixhkaqd4tr4uym6q6wyvxcwai7ethmhieompdnlrcldc6rm";
        DropType dropType = DropType.Public;
        bytes memory data = abi.encode(publicMintPrice, publicMaxSupply, publicMaxPerWallet);

        vm.prank(admin);
        drops.createDrop(dropType, uri, data);
        vm.stopPrank();

        (bool isLive, string memory dropUri, DropType _dropType, bytes memory dropData) = drops.drops(1);

        assertEq(isLive, true);
        assertEq(dropUri, uri);
        assertEq(uint256(_dropType), uint256(dropType));
        assertEq(dropData, data);
    }

    function testFailCreateDropWhenNotAdmin() public {
        labelAndPrank("dropCreator");
        drops.createDrop(
            DropType.Public,
            "ipfs://bafkreiepxqvixhkaqd4tr4uym6q6wyvxcwai7ethmhieompdnlrcldc6rm",
            abi.encode(publicMintPrice, publicMaxSupply, publicMaxPerWallet)
        );
    }
}

contract Unit_ERC1155Drops_MintPublic is ERC1155DropTests {
    function testPublicMint() public {
        address minter = labelAndPrank("minter");
        drops.mint{ value: 0.1 ether }(1, DropType.Public, abi.encode(1, minter));
    }

    function testCannotMintWhenPriceNotMet() public {
        address minter = labelAndPrank("minter");
        vm.expectRevert(IncorrectAmountSent.selector);
        drops.mint{ value: 0.001 ether }(1, DropType.Public, abi.encode(1, minter));
    }

    function testCannotMintOverMaxPerWallet() public {
        uint256 amount = 11;
        address minter = labelAndPrank("minter");
        vm.expectRevert(MaxPerWalletReached.selector);
        drops.mint{ value: 0.1 ether * amount }(1, DropType.Public, abi.encode(amount, minter));
    }

    function testCannotMintOverMaxSupply() public {
        for (uint256 i = 0; i < publicMaxSupply / publicMaxPerWallet; i++) {
            address minter = labelAndPrank("minter");
            drops.mint{ value: publicMaxPerWallet * publicMintPrice }(
                1,
                DropType.Public,
                abi.encode(publicMaxPerWallet, minter)
            );
        }

        address lastMinter = labelAndPrank("minter");
        vm.expectRevert(MaxSupplyReached.selector);
        drops.mint{ value: publicMintPrice }(1, DropType.Public, abi.encode(1, lastMinter));
    }
}

contract Unit_ERC1155Drops_MintTokenGated is ERC1155DropTests {
    function setUp() public override {
        super.setUp();
    }
}

contract Unit_ERC1155Drops_MintAllowList is ERC1155DropTests {
    Merkle private m = new Merkle();
    bytes32[] public data = new bytes32[](4);

    function setUp() public override {
        super.setUp();

        // Toy Data
        data[0] = keccak256(abi.encodePacked(admin, uint256(1)));
        data[1] = keccak256(abi.encodePacked(listed1, uint256(1)));
        data[2] = keccak256(abi.encodePacked(listed2, uint256(1)));
        data[3] = keccak256(abi.encodePacked(listed3, uint256(1)));

        vm.startPrank(admin);
        drops.createDrop(
            DropType.Allowlist,
            "ipfs://bafkreiepxqvixhkaqd4tr4uym6q6wyvxcwai7ethmhieompdnlrcldc6rm",
            abi.encode(publicMintPrice, m.getRoot(data))
        );
        vm.stopPrank();
    }

    function testAllowlistMint() public {
        vm.startPrank(admin);
        drops.mint(3, DropType.Allowlist, abi.encode(1, admin, m.getProof(data, 0)));
        vm.stopPrank();
    }

    function testOnlyAccountCanClaim() public {
        vm.startPrank(admin);
        bytes32[] memory proof = m.getProof(data, 1);
        vm.expectRevert(NotSender.selector);
        drops.mint(3, DropType.Allowlist, abi.encode(1, listed1, proof));
        vm.stopPrank();
    }

    function testCannotAllowlistMintTwice() public {
        vm.startPrank(admin);
        bytes32[] memory proof = m.getProof(data, 0);
        drops.mint(3, DropType.Allowlist, abi.encode(1, admin, proof));
        vm.expectRevert(AlreadyClaimed.selector);
        drops.mint(3, DropType.Allowlist, abi.encode(1, admin, proof));
        vm.stopPrank();
    }
}
