// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract MockUSDC is ERC20, Pausable {
    mapping(address account => bool blocked) public blacklisted;

    constructor() ERC20("Mock USDC", "mUSDC") { }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(
        address to,
        uint256 amount
    ) external {
        _mint(to, amount);
    }

    function setPaused(
        bool value
    ) external {
        if (value) _pause();
        else _unpause();
    }

    function setBlacklisted(
        address account,
        bool value
    ) external {
        blacklisted[account] = value;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override whenNotPaused {
        if (from != address(0) && blacklisted[from]) revert("BLACKLISTED_FROM");
        if (to != address(0) && blacklisted[to]) revert("BLACKLISTED_TO");
        super._update(from, to, value);
    }
}
