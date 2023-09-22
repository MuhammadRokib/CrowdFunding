// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__InsufficientBalance();

contract FundMe {

    using PriceConverter for uint256;

    address private i_owner;
    address[] private s_funders;
    uint256 public MIN_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;
    mapping(address => uint256) private s_addToAmount;

    constructor(address s_priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
        i_owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }
    
    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MIN_USD) revert FundMe__InsufficientBalance();
        s_funders.push(msg.sender);
        s_addToAmount[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public onlyOwner{
        if (amount > address(this).balance) revert FundMe__InsufficientBalance();

        (bool callSuccess,) = payable(msg.sender).call{value: amount}("");
        require(callSuccess, "Transaction Failed");
    }
    
    function withdrawAll() public onlyOwner{
        uint256 s = s_funders.length;
        for (uint256 i = 0; i < s; i++) {
            s_addToAmount[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Transaction Failed");
    }

    function cheapWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for(uint256 i = 0; i < funders.length; i++) {
            s_addToAmount[funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 i) public view returns (address) {
        return s_funders[i];
    }

    function getAddToAmount(address adr) public view returns (uint256) {
        return s_addToAmount[adr];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}