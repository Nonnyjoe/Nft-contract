// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    uint8 public numberOfPlayers; // the number of players needed in the lottery game
    address public organizer; // the create of the contract
    uint256 public minAmount; // the minimum amount to enter the lottery
    address public tokenAddress;

    struct Player {
        // a user defined type that gives the structure of the information that you want from the players of the lottery
        address participant;
        uint256 amount;
        // uint256 raffleNumber;
    }

    Player[] public players; // the array to hold the information of the players of the lottery

    // event log when the contract owner withdraw the profit after the lottery game has been concluded
    event _withdrawContractProfit(address indexed to, uint256 indexed amount);
    // event log when the players wants to enter the lottery game
    event _enterLottery(address indexed participant, uint256 indexed amount);
    // event log when the admin wants to transfer the eth to the winner of the lottery
    event _withdrawMoney(address indexed winner, uint256 indexed amount);

    /////////
    constructor(uint256 _amount, uint8 _noOfPlayers, address _addr) {
        organizer = msg.sender; // to set the creatot of the lottery contract
        minAmount = _amount; // to set the minimum amount a player can use to participate
        numberOfPlayers = _noOfPlayers; // to set the minimum amount a player can use to participate
        tokenAddress = _addr;
    }

    // only owner modifier
    modifier onlyOwner() {
        require(msg.sender == organizer, "You do not have the permission!");
        _;
    }

    // function that allows players to enter the lottery
    function enterLottery(uint _amount) external {
        address player_ = msg.sender;
        require(_amount >= minAmount, "Amount is not enough!");
        require(
            player_ != address(0) || player_ != organizer,
            "This address cannot enter the lottery!"
        );
        require(
            players.length + 1 <= numberOfPlayers,
            "The players in this lottery game is complete!"
        );

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        players.push(Player(player_, _amount));

        emit _enterLottery(player_, _amount);
    }

    // function to generate random number
    function randomNumber() private view returns (uint256) {
        return
            (uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % players.length) + 1;
    }

    // function to pick winner in the lottery game
    function pickWinner() external onlyOwner {
        require(
            players.length == numberOfPlayers,
            "You need more players before you can pick a winner"
        );
        uint256 index = randomNumber();

        uint contractBalance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).transfer(
            players[index].participant,
            contractBalance
        );

        // payable(players[index].participant).transfer(commissionAmount);
        emit _withdrawMoney(players[index].participant, contractBalance);
    }

    // function that allows the organizer to withdraw the profit after the lottery game
    function withdrawContractProfit(address _to) external payable onlyOwner {
        require(_to != address(0), "transfer to the zero address");

        uint contractBalance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).transfer(msg.sender, contractBalance);
    }

    // function to get balance of the contract
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
