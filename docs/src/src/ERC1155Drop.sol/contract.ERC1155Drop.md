# ERC1155Drop
[Git Source](https://github.com/nezz0746/erc1155-drops/blob/d7f880b61660eee2cfba35343e42e0de1e47c5a1/src/ERC1155Drop.sol)

**Inherits:**
[IERC1155Drop](/src/libs/IERC1155Drop.sol/interface.IERC1155Drop.md), ERC1155Supply, Ownable, AccessControl

**Author:**
nezzar.eth

ERC1155Drop is a contract for creating and managing ERC1155 drops
Attempt a creating a simple ERC1155 which carries multiple mint strategies for
each token created. Could be made upgradable to allow for more mint strategies
in the future.


## State Variables
### DROP_CREATOR

```solidity
bytes32 public constant DROP_CREATOR = keccak256("DROP_CREATOR");
```


### _dropIds
Counter for dropIds


```solidity
Counters.Counter private _dropIds;
```


### drops
Mapping of dropId to Drop


```solidity
mapping(uint256 dropId => Drop drop) public drops;
```


### dropsClaims
Mapping of dropId to address to bool for claiming mint strategies


```solidity
mapping(uint256 dropId => mapping(address account => bool claimed) dropClaims) public dropsClaims;
```


### treasury
address of the treasury


```solidity
address payable public treasury;
```


## Functions
### constructor

*Grants all roles to the admin account.
Feel free to distribute roles as you see fit.
See {ERC1155}.*


```solidity
constructor(address _admin, address payable _treasury) ERC1155("");
```

### onlyValidMinter

require that mint callers be non-contract owners


```solidity
modifier onlyValidMinter();
```

### createDrop


```solidity
function createDrop(
    DropType dropType,
    string memory _dropUri,
    bytes memory _dropData
)
    external
    onlyRole(DROP_CREATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropType`|`DropType`|type of drop (public, tokenGated, allowlist)|
|`_dropUri`|`string`|uri for drop metadata|
|`_dropData`|`bytes`|encoded drop settings data|


### updateDropUri


```solidity
function updateDropUri(uint256 dropId, string memory _dropUri) external onlyRole(DROP_CREATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|
|`_dropUri`|`string`|uri for the new drop metadata|


### pauseDrop


```solidity
function pauseDrop(uint256 dropId) external onlyRole(DROP_CREATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|


### unpauseDrop


```solidity
function unpauseDrop(uint256 dropId) external onlyRole(DROP_CREATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|


### mint


```solidity
function mint(uint256 dropId, DropType dropType, bytes calldata mintData) external payable onlyValidMinter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|
|`dropType`|`DropType`|type of drop (public, tokenGated, allowlist)|
|`mintData`|`bytes`|encoded mint settings data|


### _mintERC721GatedDrop


```solidity
function _mintERC721GatedDrop(uint256 dropId, bytes memory dropData, bytes memory mintData) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|
|`dropData`|`bytes`|encoded drop settings data|
|`mintData`|`bytes`|encoded mint settings data|


### _mintPublicDrop


```solidity
function _mintPublicDrop(uint256 dropId, bytes memory dropData, bytes memory mintData) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|
|`dropData`|`bytes`|encoded drop settings data|
|`mintData`|`bytes`|encoded mint settings data|


### _mintAllowlistDrop


```solidity
function _mintAllowlistDrop(uint256 dropId, bytes memory dropData, bytes memory mintData) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dropId`|`uint256`|id of drop|
|`dropData`|`bytes`|encoded drop settings data|
|`mintData`|`bytes`|encoded mint settings data|


### uri


```solidity
function uri(uint256 _id) public view virtual override returns (string memory);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool);
```

