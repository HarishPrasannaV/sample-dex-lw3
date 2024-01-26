// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address token) ERC20("Swap Token", "ST") {
        require(tokenAddress != address(0), "This ain't a real token");
        tokenAddress = token;
    }

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    function addLiquidity(
        uint256 amountOfToken
    ) public payable returns (uint256) {
        uint256 stTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        if (tokenReserveBalance == 0) {
            token.transferFrom(msg.sender, address(this), amountOfToken);
            stTokensToMint = ethReserveBalance;
            _mint(msg.sender, stTokensToMint);
            return stTokensToMint;
        }

        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance) /
            ethReservePriorToFunctionCall;

        require(
            amountOfToken >= minTokenAmountRequired,
            "Insufficient amount of tokens provided"
        );

        token.transferFrom(msg.sender, address(this), amountOfToken);

        stTokensToMint =
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;

        _mint(msg.sender, stTokensToMint);

        return stTokensToMint;
    }

    function removeLiquidity(
        uint256 amountOfSTTokens
    ) public view returns (uint256, uint256) {
        require(amountOfSTTokens > 0, "No trolling pls");
        uint256 ethReserveBalance = address(this).balance;
        uint256 stTokenTotalSupply = totalSupply();

        uint256 ethToReturn = (ethReserveBalance * amountOfSTTokens) /
            stTokenTotalSupply;
        uint256 tokenToReturn = (getReserve() * amountOfSTTokens) /
            stTokenTotalSupply;

        return (ethToReturn, tokenToReturn);
    }
}
