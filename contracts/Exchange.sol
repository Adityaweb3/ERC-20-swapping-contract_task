// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// Requirements 
// Building  an exchange with asset pair (Eth and Our ERC20 token)
// My exchange platform will take fees of 1% of swaps
//  This is not in assignment requirement : When user adds liquidity, they should be given Liquidity Provider(LP)  tokens .



contract ERC20Swapper is ERC20 {
    // We are taking address of our ERC20 token
    address public TokenAddress;

    // Our Exchange will keep track of liquidity provider tokens 


    constructor(address _token) ERC20("LP Token", "LP") {
        require(_token != address(0), "You are passing null address for Token address");
        TokenAddress = _token;
    }

    // Now we are creating a function will will give the amount of ERC20 token that our contract is holding
    function getReserve() public view returns (uint) {
    return ERC20(TokenAddress).balanceOf(address(this));
}

// Now we are creating a function to maintain the liquidity on our platform 
// We have tp keep these 2 points in mind
//(ERC20TokenAmount user can add/ERC20TokenReserve in the contract) = (Eth Sent by the user/Eth Reserve in the contract)
//(LP tokens to be sent to the user (liquidity) / totalSupply of LP tokens in contract) = (Eth sent by the user) / (Eth reserve in the contract).

function addLiquidity(uint _amount) public payable returns (uint) {
    uint liquidity;
    uint ethBalance = address(this).balance;
    uint TokenReserve = getReserve();
    ERC20 Token = ERC20(TokenAddress);

    if(TokenReserve == 0) {
        Token.transferFrom(msg.sender, address(this), _amount);
        liquidity = ethBalance;
        _mint(msg.sender, liquidity);


    } else {
        uint ethReserve =  ethBalance - msg.value;
        uint TokenAmount = (msg.value * TokenReserve)/(ethReserve);
        require(_amount >= TokenAmount, "Amount of tokens sent is less than the minimum tokens required");
        Token.transferFrom(msg.sender, address(this), TokenAmount);
        liquidity = (totalSupply() * msg.value)/ ethReserve;
        _mint(msg.sender, liquidity);


    }
    return liquidity;
}

// Now we are creating a function that will returns the amount of token that would be returned to user in swap

function removeLiquidity(uint _amount) public returns (uint , uint) {
    require(_amount > 0, "_amount should be greater than zero");
    uint ethReserve = address(this).balance;
    uint _totalSupply = totalSupply();

    uint ethAmount = (ethReserve * _amount)/ _totalSupply;

    uint TokenAmount = (getReserve() * _amount)/ _totalSupply;

     _burn(msg.sender, _amount);

     payable(msg.sender).transfer(ethAmount);
     ERC20(TokenAddress).transfer(msg.sender, TokenAmount);
    return (ethAmount, TokenAmount);

}

// Now we are going to add swap functionality 

// So there are 2 possibility : One way would be Eth to our ERC20 tokens and other would be Our ERC20 token to Eth

// We also hgave to keep in mind that we are charging 1% platform fee 

function getAmountOfTokens(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
) public pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
    uint256 inputAmountWithFee = inputAmount * 99;

    uint256 numerator = inputAmountWithFee * outputReserve;
    uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
    return numerator / denominator;
}

// Function for ETH to our ERC20 token

function ethToCryptoDevToken(uint _minTokens) public payable {
    uint256 tokenReserve = getReserve();
    uint256 tokensBought = getAmountOfTokens(
        msg.value,
        address(this).balance - msg.value,
        tokenReserve
    );

    require(tokensBought >= _minTokens, "insufficient output amount");
    // Transfer the `Crypto Dev` tokens to the user
    ERC20(TokenAddress).transfer(msg.sender, tokensBought);
}


// Function for Our ERC20 toke  to ETH swapping

function TokenToEth(uint _tokensSold, uint _minEth) public {
    uint256 tokenReserve = getReserve();
    uint256 ethBought = getAmountOfTokens(
        _tokensSold,
        tokenReserve,
        address(this).balance
    );

    require(ethBought >= _minEth, "insufficient output amount");

    // Here we are transfering our ERC20 token to contract address


    ERC20(TokenAddress).transferFrom(
        msg.sender,
        address(this),
        _tokensSold
    );


    // And ETH in the wallet of user 

    payable(msg.sender).transfer(ethBought);
}

// Contract completed












}