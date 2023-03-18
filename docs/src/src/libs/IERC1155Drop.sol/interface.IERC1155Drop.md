# IERC1155Drop
[Git Source](https://github.com/nezz0746/erc1155-drops/blob/d7f880b61660eee2cfba35343e42e0de1e47c5a1/src/libs/IERC1155Drop.sol)

**Author:**
nezzar.eth

Interface with errors, events and methods specific to the ERC1155Drop contract


## Events
### CreateDrop
*Event emitted when a new drop is created*


```solidity
event CreateDrop(uint256 indexed dropId, DropType indexed dropType, bytes dropData, string dropUri);
```

### UpdateDropUri
*Event emitted when a drop uri is updated*


```solidity
event UpdateDropUri(uint256 indexed dropId, string dropUri);
```

### PauseDrop
*Event emitted when a drop is paused*


```solidity
event PauseDrop(uint256 indexed dropId);
```

### UnpauseDrop
*Event emitted when a drop is unpaused*


```solidity
event UnpauseDrop(uint256 indexed dropId);
```

### MintDrop
*Event emitted when a drop is deleted*


```solidity
event MintDrop(uint256 indexed dropId, address indexed to, bytes mintData);
```

## Errors
### DropIsNotLive
*Error when trying to create a drop that is not live*


```solidity
error DropIsNotLive();
```

### DropTypeNotSupported
*Error when trying to create a drop that is not supported*


```solidity
error DropTypeNotSupported();
```

### MinterNotAllowed
*Error when trying to mint when not allowed*


```solidity
error MinterNotAllowed();
```

### SenderDoesnNotOwnERC721
*Error when trying to mint when sender does not own ERC721*


```solidity
error SenderDoesnNotOwnERC721();
```

### MaxSupplyReached
*Error when trying to mint when max supply is reached*


```solidity
error MaxSupplyReached();
```

### MaxPerWalletReached
*Error when trying to mint when max per wallet is reached*


```solidity
error MaxPerWalletReached();
```

### IncorrectAmountSent
*Error when trying to mint when incorrect amount is sent to contract*


```solidity
error IncorrectAmountSent();
```

### NotInAllowlist
*Error when trying to mint when recipient is not in allowlist*


```solidity
error NotInAllowlist();
```

### AlreadyClaimed
*Error when trying to mint when recipient has already claimed*


```solidity
error AlreadyClaimed();
```

### NotSender
*Error when msg.sender is not the recipient of the mint*


```solidity
error NotSender();
```

