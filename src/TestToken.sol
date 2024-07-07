// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("FayhrUSD", "FUSD") {
        _mint(msg.sender, 1000000000000 * 10 ** 18); // 1 billion tokens to the deployer
    }
}
