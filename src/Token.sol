// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract DAOToken is ERC20, ERC20Burnable,Ownable {
     /**
     * @dev Public variable representing the price of a token.
     */
     uint256 public tokenPrice = 0.1 ether;
    
    
    constructor()
        ERC20("Aidance", "Adn")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 1000*10**18);
    }

    /***
    * @dev function to mint a DAO Token for Aidance vote 
    *
    * @param to The address of the user where to mint.
    * @param _amount The amount of tokens to mint.
    */
    function mint(address to, uint256 _amount) external payable {
        uint256 totalPrice = tokenPrice * _amount;
        require(msg.value >= totalPrice, "Insufficient Ether sent.");
        _mint(to, ((_amount)* 10 ** 18));
        (bool sent,) = payable(msg.sender).call{value: msg.value - totalPrice}("");
        require(sent, "Failed to send Ether");
    }


    /**
     * @dev Updates the token price.
     *
     * @param newPrice The new price for the token.
     */
     function updateTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    /**
     * @dev Withdraws the entire contract balance to the owner.
     * 
     * Requirements:
     * - The contract balance must be greater than zero.
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero.");
        payable(owner()).transfer(address(this).balance); // Transfer entire contract balance to owner
    }

     /**
     * @dev Burns a specified amount of tokens from a given address.
     * @param from The address from which the tokens will be burned.
     * @param amount The amount of tokens to be burned.
     */
    function burnToken(address from, uint256 amount) external {
        _burn(from, amount);
    }
}