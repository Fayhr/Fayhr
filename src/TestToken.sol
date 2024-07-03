// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("FayhrUSD", "FUSD") {
        _mint(msg.sender, 1e24); // 1 million tokens to the deployer
    }
}
