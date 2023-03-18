// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { DropType } from "./Structs.sol";

/**
 * @title ERC1155Drop Interface
 * @author nezzar.eth
 * @notice Interface with errors, events and methods specific to the ERC1155Drop contract
 **/
interface IERC1155Drop {
    /**
     * @dev Error when trying to create a drop that is not live
     */
    error DropIsNotLive();

    /**
     * @dev Error when trying to create a drop that is not supported
     */
    error DropTypeNotSupported();

    /**
     * @dev Error when trying to mint when not allowed
     */
    error MinterNotAllowed();

    /**
     * @dev Error when trying to mint when sender does not own ERC721
     */
    error SenderDoesnNotOwnERC721();

    /**
     * @dev Error when trying to mint when max supply is reached
     */
    error MaxSupplyReached();

    /**
     * @dev Error when trying to mint when max per wallet is reached
     */
    error MaxPerWalletReached();

    /**
     * @dev Error when trying to mint when incorrect amount is sent to contract
     */
    error IncorrectAmountSent();

    /**
     * @dev Error when trying to mint when recipient is not in allowlist
     */
    error NotInAllowlist();

    /**
     * @dev Error when trying to mint when recipient has already claimed
     */
    error AlreadyClaimed();

    /**
     * @dev Error when msg.sender is not the recipient of the mint
     */
    error NotSender();

    /**
     * @dev Event emitted when a new drop is created
     */
    event CreateDrop(uint256 indexed dropId, DropType indexed dropType, bytes dropData, string dropUri);

    /**
     * @dev Event emitted when a drop uri is updated
     */
    event UpdateDropUri(uint256 indexed dropId, string dropUri);

    /**
     * @dev Event emitted when a drop is paused
     */
    event PauseDrop(uint256 indexed dropId);

    /**
     * @dev Event emitted when a drop is unpaused
     */
    event UnpauseDrop(uint256 indexed dropId);

    /**
     * @dev Event emitted when a drop is deleted
     */
    event MintDrop(uint256 indexed dropId, address indexed to, bytes mintData);
}
