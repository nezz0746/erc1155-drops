// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC1155Supply, ERC1155, IERC1155 } from "@openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Counters } from "@openzeppelin-contracts/utils/Counters.sol";
import { MerkleProof } from "@openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { IERC721 } from "@openzeppelin-contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin-contracts/access/AccessControl.sol";
import "src/libs/Structs.sol";
import { Errors } from "src/libs/Errors.sol";

/**
 * @title ERC1155Drop
 * @author nezzar.eth
 * @notice ERC1155Drop is a contract for creating and managing ERC1155 drops
 *
 * Attempt a creating a simple ERC1155 which carries multiple mint strategies for
 * each token created. Could be made upgradable to allow for more mint strategies
 * in the future.
 */
contract ERC1155Drop is ERC1155Supply, Ownable, AccessControl {
    using Counters for Counters.Counter;

    event CreateDrop(uint256 indexed dropId, DropType indexed dropType, bytes dropData, string dropUri);
    event UpdateDropUri(uint256 indexed dropId, string dropUri);
    event PauseDrop(uint256 indexed dropId);
    event UnpauseDrop(uint256 indexed dropId);
    event MintDrop(uint256 indexed dropId, address indexed to, bytes mintData);

    /**
     * @notice Counter for dropIds
     */
    Counters.Counter private _dropIds;

    /**
     * @notice Mapping of dropId to Drop
     */
    mapping(uint256 dropId => Drop drop) public drops;

    /**
     * @notice Mapping of dropId to address to bool for claiming mint strategies
     */
    mapping(uint256 dropId => mapping(address account => bool claimed) dropClaims) public dropsClaims;

    bytes32 public constant DROP_CREATOR = keccak256("DROP_CREATOR");

    address payable public treasury;

    /**
     * @dev Grants all roles to the admin account.
     * Feel free to distribute roles as you see fit.
     *
     * See {ERC1155}.
     */
    constructor(address _admin, address payable _treasury) ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(DROP_CREATOR, _admin);
        // Set the contract owner for opensea collection management
        // Note: Owner can add collaborators to the collection on opensea interface
        transferOwnership(_admin);

        treasury = _treasury;

        _dropIds.increment();
    }

    /// @notice require that mint callers be non-contract owners
    modifier onlyValidMinter() {
        if (tx.origin != msg.sender) revert Errors.minterNotAllowed();
        _;
    }

    /**
     *
     * @param dropType type of drop (public, tokenGated, allowlist)
     * @param _dropUri uri for drop metadata
     * @param _dropData encoded drop settings data
     */
    function createDrop(
        DropType dropType,
        string memory _dropUri,
        bytes memory _dropData
    ) external onlyRole(DROP_CREATOR) {
        uint256 dropId = _dropIds.current();

        drops[dropId].isLive = true;
        drops[dropId].dropType = dropType;
        drops[dropId].dropUri = _dropUri;
        drops[dropId].dropData = _dropData;

        _dropIds.increment();

        emit CreateDrop(dropId, dropType, _dropData, _dropUri);
    }

    /**
     *
     * @param dropId id of drop
     * @param _dropUri uri for the new drop metadata
     */
    function updateDropUri(uint256 dropId, string memory _dropUri) external onlyRole(DROP_CREATOR) {
        Drop memory drop = drops[dropId];

        if (drop.isLive) {
            drops[dropId].dropUri = _dropUri;

            emit UpdateDropUri(dropId, _dropUri);
        } else {
            revert Errors.DropIsNotLive();
        }
    }

    /**
     *
     * @param dropId id of drop
     */
    function pauseDrop(uint256 dropId) external onlyRole(DROP_CREATOR) {
        drops[dropId].isLive = false;

        emit PauseDrop(dropId);
    }

    /**
     *
     * @param dropId id of drop
     */
    function unpauseDrop(uint256 dropId) external onlyRole(DROP_CREATOR) {
        drops[dropId].isLive = true;

        emit UnpauseDrop(dropId);
    }

    /**
     *
     * @param dropId id of drop
     * @param dropType type of drop (public, tokenGated, allowlist)
     * @param mintData encoded mint settings data
     */
    function mint(uint256 dropId, DropType dropType, bytes calldata mintData) external payable onlyValidMinter {
        Drop memory drop = drops[dropId];

        if (drop.isLive == false) revert Errors.DropIsNotLive();

        if (dropType == DropType.TokenGated) {
            _mintERC721GatedDrop(dropId, drop.dropData, mintData);
            emit MintDrop(dropId, msg.sender, mintData);
        } else if (dropType == DropType.Public) {
            _mintPublicDrop(dropId, drop.dropData, mintData);
            emit MintDrop(dropId, msg.sender, mintData);
        } else if (dropType == DropType.Allowlist) {
            _mintAllowlistDrop(dropId, drop.dropData, mintData);
            emit MintDrop(dropId, msg.sender, mintData);
        } else {
            revert Errors.DropTypeNotSupported();
        }
    }

    /**
     *
     * @param dropId id of drop
     * @param dropData encoded drop settings data
     * @param mintData encoded mint settings data
     */
    function _mintERC721GatedDrop(uint256 dropId, bytes memory dropData, bytes memory mintData) internal {
        ERC721GatedDropMintSettings memory mintSettings = abi.decode(mintData, (ERC721GatedDropMintSettings));

        ERC721GatedDropSettings memory dropSettings = abi.decode(dropData, (ERC721GatedDropSettings));

        if (msg.value < mintSettings.amount * dropSettings.price) {
            revert Errors.IncorrectAmountSent();
        }

        if (mintSettings.to != msg.sender) revert Errors.NotSender();

        if (totalSupply(dropId) + mintSettings.amount > dropSettings.maxSupply) {
            revert Errors.MaxSupplyReached();
        }

        if (balanceOf(mintSettings.to, dropId) + mintSettings.amount > dropSettings.maxPerWallet) {
            revert Errors.MaxPerWalletReached();
        }

        if (IERC721(dropSettings.tokenAddress).balanceOf(mintSettings.to) == 0) {
            revert Errors.SenderDoesnNotOwnERC721();
        }

        _mint(mintSettings.to, dropId, mintSettings.amount, "");

        treasury.transfer(msg.value);
    }

    /**
     *
     * @param dropId id of drop
     * @param dropData encoded drop settings data
     * @param mintData encoded mint settings data
     */
    function _mintPublicDrop(uint256 dropId, bytes memory dropData, bytes memory mintData) internal {
        PublicDropMintSettings memory mintSettings = abi.decode(mintData, (PublicDropMintSettings));

        PublicDropSettings memory dropSettings = abi.decode(dropData, (PublicDropSettings));

        if (mintSettings.to != msg.sender) revert Errors.NotSender();

        if (totalSupply(dropId) + mintSettings.amount > dropSettings.maxSupply) {
            revert Errors.MaxSupplyReached();
        }

        if (balanceOf(mintSettings.to, dropId) + mintSettings.amount > dropSettings.maxPerWallet) {
            revert Errors.MaxPerWalletReached();
        }

        if (msg.value < mintSettings.amount * dropSettings.price) {
            revert Errors.IncorrectAmountSent();
        }

        _mint(mintSettings.to, dropId, mintSettings.amount, "");
    }

    /**
     *
     * @param dropId id of drop
     * @param dropData encoded drop settings data
     * @param mintData encoded mint settings data
     */
    function _mintAllowlistDrop(uint256 dropId, bytes memory dropData, bytes memory mintData) internal {
        (uint256 amount, address account, bytes32[] memory proof) = abi.decode(mintData, (uint256, address, bytes32[]));

        AllowlistDropSettings memory dropSettings = abi.decode(dropData, (AllowlistDropSettings));

        if (account != msg.sender) revert Errors.NotSender();

        if (
            MerkleProof.verify(proof, dropSettings.listMerkleRoot, keccak256(abi.encodePacked(account, amount))) ==
            false
        ) revert Errors.NotInAllowlist();

        if (dropsClaims[dropId][account]) revert Errors.AlreadyClaimed();

        if (msg.value > amount * dropSettings.price) {
            revert Errors.IncorrectAmountSent();
        }

        _mint(account, dropId, amount, "");

        dropsClaims[dropId][account] = true;
    }

    ////////////// OVERRIDES //////////////////////

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return drops[_id].dropUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
