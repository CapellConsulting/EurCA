// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle is Ownable {
    IERC20 public eurcaToken;

    event TokensWithdrawn(address indexed customer, uint256 amount);
    event TokensDeposited(address indexed depositor, uint256 amount);
    event LiquidityCheckResult(bool liquidityStatus);

    constructor(address _eurcaTokenAddress) {
        require(_eurcaTokenAddress != address(0), "Invalid Eurca Token address");
        eurcaToken = IERC20(_eurcaTokenAddress);
    }

    function bankAccountLiquidityCheck(address _wallet, string memory _bankAccount) external view returns (bool) {
        // Placeholder implementation of bank account liquidity check
        // For the sake of example, let's assume it always returns true
        return true;
    }

    // This function is called by the off-chain oracle service
    function setLiquidityCheckResult(bool _liquidityStatus) external onlyOwner {
        emit LiquidityCheckResult(_liquidityStatus);
    }

    function withdrawTokens(address _customer, uint256 _amount) external onlyOwner {
        require(eurcaToken.balanceOf(address(this)) >= _amount, "Insufficient tokens in the Oracle");
        eurcaToken.transfer(_customer, _amount);
        emit TokensWithdrawn(_customer, _amount);
    }

    function depositTokens(uint256 _amount) external {
        require(eurcaToken.allowance(msg.sender, address(this)) >= _amount, "Token allowance not sufficient");
        eurcaToken.transferFrom(msg.sender, address(this), _amount);
        emit TokensDeposited(msg.sender, _amount);
    }

    function getOracleTokenBalance() external view returns (uint256) {
        return eurcaToken.balanceOf(address(this));
    }
}
