// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract marketPlace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    // soliity creates a getter function that returns the listingPrice
    uint256 public constant listingPrice = 0.00067 ether;

    uint256 internal soldItems;

    address payable owner;

    address[] internal Buyers;
    address[] internal Sellers;

    mapping(address => bool) internal isBuyer;
    mapping(address => bool) internal isSeller;

    mapping(address => uint256) internal totalBuy;
    mapping(address => uint256) internal totalSell;

    ////////
    mapping(address => Items[]) internal tokensBougth;

    mapping(address => Items[]) internal tokensSold;

    struct Items {
        address nftContract;
        uint256 tokenId;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        uint256 listTime;
    }

    struct SoldItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 soldTime;
    }

    mapping(uint256 => MarketItem) private marketItems;

    mapping(uint256 => mapping(address => SoldItem)) private SoldItems;

    /////////////////EVENT////////////////////////
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event MarketItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() {
        owner = payable(msg.sender);
    }

    // @dev create listing for ERC721 Assets
    // @params _nftcontract
    // @params _tokenId
    // @price _price
    function ListItemForSale(
        address _nftcontract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(_price > 0, "amount must be greater than zero");
        require(msg.value == listingPrice, "not listing price");
        _itemIds.increment();
        uint256 itemIds = _itemIds.current();
        MarketItem storage _m = marketItems[itemIds];
        _m.itemId = itemIds;
        _m.nftContract = _nftcontract;
        _m.tokenId = _tokenId;
        _m.seller = payable(msg.sender);
        _m.owner = payable(address(0));
        _m.price = _price;
        _m.sold = false;
        _m.listTime = block.timestamp;

        IERC721(_nftcontract).transferFrom(msg.sender, address(this), _tokenId);
        /////////////////////
        bool _isSeller = isSeller[msg.sender];
        if (!_isSeller) {
            Sellers.push(msg.sender);
            isSeller[msg.sender] = true;
        }

        emit MarketItemCreated(
            itemIds,
            _nftcontract,
            _tokenId,
            msg.sender,
            address(0),
            _price,
            false
        );
    }

    function buyAsset(
        address _nftcontract,
        uint256 itemId
    ) public payable nonReentrant {
        uint256 price = marketItems[itemId].price;
        uint256 tokenIds = marketItems[itemId].tokenId;
        address seller = marketItems[itemId].seller;
        require(msg.value >= price, "amount not asking price");
        require(seller != msg.sender, "cannot buy asset listed");
        marketItems[itemId].seller.transfer(msg.value);
        IERC721(_nftcontract).transferFrom(address(this), msg.sender, tokenIds);
        marketItems[itemId].owner = payable(msg.sender);
        marketItems[itemId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
        soldItems = soldItems + 1;
        /////////////
        updateSellDetails(
            itemId,
            _nftcontract,
            tokenIds,
            seller,
            msg.sender,
            price
        );
        logSale(seller, _nftcontract, itemId);

        emit MarketItemSold(
            itemId,
            _nftcontract,
            tokenIds,
            seller,
            owner,
            price,
            true
        );
    }

    function logSale(
        address seller,
        address _nftcontract,
        uint256 itemId
    ) internal {
        bool _isBuyer = isBuyer[msg.sender];
        if (!_isBuyer) {
            Buyers.push(msg.sender);
            isBuyer[msg.sender] = true;
        }
        uint256 buys = totalBuy[msg.sender];
        uint256 sales = totalSell[seller];

        totalBuy[msg.sender] = buys + 1;
        totalSell[seller] = sales + 1;
        ////////////check
        Items memory _items;
        _items.nftContract = _nftcontract;
        _items.tokenId = itemId;
        tokensSold[seller].push(_items);
        tokensBougth[msg.sender].push(_items);
    }

    function updateSellDetails(
        uint256 itemId,
        address _nftcontract,
        uint256 tokenIds,
        address seller,
        address buyer,
        uint256 price
    ) internal {
        SoldItem storage _s = SoldItems[itemId][msg.sender];
        //////////
        _s.itemId = itemId;
        _s.nftContract = _nftcontract;
        _s.tokenId = tokenIds;
        _s.seller = payable(seller);
        _s.buyer = payable(buyer);
        _s.price = price;
        _s.soldTime = block.timestamp;
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemsCount = (_itemIds.current()) -
            (_itemsSold.current());
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemsCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (marketItems[i + 1].owner == address(0)) {
                uint256 currentId = marketItems[i + 1].itemId;
                MarketItem storage currentItem = marketItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNfts() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (marketItems[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (marketItems[i + 1].owner == msg.sender) {
                uint256 currentId = marketItems[i + 1].itemId;
                MarketItem storage currentItem = marketItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (marketItems[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (marketItems[i + 1].seller == msg.sender) {
                uint256 currentId = marketItems[i + 1].itemId;
                MarketItem storage currentItem = marketItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function NumberOfSoldItems() public view returns (uint256) {
        return soldItems;
    }

    function DisplayBuyers() public view returns (address[] memory) {
        return Buyers;
    }

    function DisplaySellers() public view returns (address[] memory) {
        return Sellers;
    }

    function DisplayTotalBuy(address buyer) public view returns (uint256) {
        return totalBuy[buyer];
    }

    function DisplayTotalSell(address seller) public view returns (uint256) {
        return totalSell[seller];
    }

    function DisplayTokensBought(
        address buyer
    ) public view returns (Items[] memory) {
        return tokensBougth[buyer];
    }

    function DisplayTokensSold(
        address seller
    ) public view returns (Items[] memory) {
        return tokensSold[seller];
    }

    function SoldItemsDetails(
        uint256 tokenId,
        address buyerAddress
    ) public view returns (SoldItem memory) {
        return SoldItems[tokenId][buyerAddress];
    }
}
