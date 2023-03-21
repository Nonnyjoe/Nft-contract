// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import '@openzeppelin/contracts/utils/Counters.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NJMarketPlaceNft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address contractAddress;

    constructor(
        address marketPlaceAddress
    ) ERC721("NONNYJOE COLLECTION", "NJC") {
        contractAddress = marketPlaceAddress;
    }

    function createToken(
        string memory _tokenURI
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        setApprovalForAll(contractAddress, true);
        return newTokenId;
    }

    function getBalanceOfToken(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }
}
