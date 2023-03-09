// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library Errors {
    error DropIsNotLive();
    error DropTypeNotSupported();

    error minterNotAllowed();

    error SenderDoesnNotOwnERC721();
    error MaxSupplyReached();
    error MaxPerWalletReached();
    error IncorrectAmountSent();
    error NotInAllowlist();
    error AlreadyClaimed();
    error NotSender();
}
