// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Oracle.sol";

contract EurCA {

  address public owner;
  IERC20  public eurcaToken;
  Oracle  public oracle;
  
  uint256 public eurcaTokenQuantity;
  uint256 public constant maxUnpaidInstallments = 3;
  uint256 public constant paybackInterval = 30 days;

  struct Wallet {
        string  bankAccount;
        uint256 lockedLiquidity;
        uint256 totNumberInstallments;
        uint256 missingInstallments;
        uint256 lastPaybackTimeStamp;
        uint256 percLockedLiquidity;
  }
  
  mapping (address => Wallet) private wallets;

  event RequestLiquidityCheck(address indexed wallet, string bankAccount); // Event to signal the need for an external liquidity check
  
  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  modifier onlyLinkedBankAccount() {
    require(bytes(wallets[msg.sender].bankAccount).length != 0, "Bank account is not linked to any wallet.");
    _;
  }

  modifier paybackIntervalReached() {
    require(block.timestamp >= wallets[msg.sender].lastPaybackTimeStamp + paybackInterval, "Payback interval not reached.");
    _;
  }

  constructor(address _eurcaTokenAddress, address _oracleAddress) {
    require(_eurcaTokenAddress != address(0), "Invalid Eurca Token address");
    require(_oracleAddress != address(0), "Invalid Oracle address");

    owner = msg.sender;
    eurcaToken = IERC20(_eurcaTokenAddress);
    oracle = Oracle(_oracleAddress);
  }

  function linkBankAccount(string memory _bankAccount) external {
    require(bytes(wallets[msg.sender].bankAccount).length == 0, "Bank account already linked to a wallet.");
    wallets[msg.sender].bankAccount = _bankAccount;
    emit RequestLiquidityCheck(msg.sender, _bankAccount);
  }

function lockLiquidity(uint256 _capital, uint256 _numInstallments, uint256 _percLockedLiquidity) external onlyLinkedBankAccount {
    require(_capital > 0, "Capital must be greater than 0");
    require(_numInstallments > 0, "Number of installments must be greater than 0");
    require(_percLockedLiquidity >= 0 && _percLockedLiquidity <= 95, "Percentage of locked liquidity must be between 0 and 95");

    wallets[msg.sender].lockedLiquidity = _capital;
    wallets[msg.sender].totNumberInstallments = _numInstallments;
    wallets[msg.sender].percLockedLiquidity = _percLockedLiquidity;

    eurcaTokenQuantity = (wallets[msg.sender].lockedLiquidity * wallets[msg.sender].percLockedLiquidity) / 100 +
                          (wallets[msg.sender].lockedLiquidity * wallets[msg.sender].totNumberInstallments) / 1000;
  }

  function paybackRate(uint256 _rate) external onlyLinkedBankAccount paybackIntervalReached {
    require(_rate > 0, "Rate must be greater than 0");

    wallets[msg.sender].lockedLiquidity -= _rate;
    eurcaTokenQuantity -= _rate;

    if (wallets[msg.sender].lockedLiquidity < 0) {
        wallets[msg.sender].missingInstallments++;
        
        if (wallets[msg.sender].missingInstallments >= maxUnpaidInstallments) {
            oracle.withdrawTokens(msg.sender, eurcaTokenQuantity);
            eurcaToken.burn(eurcaTokenQuantity);
            eurcaTokenQuantity = 0;
        }
    }

    wallets[msg.sender].lastPaybackTimeStamp = block.timestamp;
  }

  function closeLoan() external onlyLinkedBankAccount {
    require(wallets[msg.sender].missingInstallments >= maxUnpaidInstallments, "Cannot close loan until maxUnpaidInstallments are missed");
    
    oracle.withdrawTokens(msg.sender, eurcaTokenQuantity);
    eurcaToken.burn(eurcaTokenQuantity);
    eurcaTokenQuantity = 0;

    wallets[msg.sender] = Wallet("", 0, 0, 0, 0, 0);
  }

}
