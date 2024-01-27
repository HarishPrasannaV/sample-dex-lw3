// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address token) ERC20("Swap Token", "ST") {
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

    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserves must be grater than 0"
        );
        uint256 inputAmountWithFee = 99 * inputAmount;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    // ethToTokenSwap allows users to swap ETH for tokens
    function ethToTokenSwap(uint256 minTokensToReceive) public payable {
        uint256 tokenReserveBalance = getReserve();
        uint256 tokensToReceive = getOutputAmountFromSwap(
            msg.value,
            address(this).balance - msg.value,
            tokenReserveBalance
        );

        require(
            tokensToReceive >= minTokensToReceive,
            "Tokens received are less than minimum tokens expected"
        );

        ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
    }

    // tokenToEthSwap allows users to swap tokens for ETH
    function tokenToEthSwap(
        uint256 tokensToSwap,
        uint256 minEthToReceive
    ) public {
        uint256 tokenReserveBalance = getReserve();
        uint256 ethToReceive = getOutputAmountFromSwap(
            tokensToSwap,
            tokenReserveBalance,
            address(this).balance
        );

        require(
            ethToReceive >= minEthToReceive,
            "ETH received is less than minimum ETH expected"
        );

        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokensToSwap
        );

        payable(msg.sender).transfer(ethToReceive);
    }
}
