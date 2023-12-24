// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lending {
    IERC20 public depositToken;
    IERC20 public borrowToken;

    uint256 public constant depositInterestRate = 3;
    uint256 public constant borrowInterestRate = 5;
    uint256 public constant collateralFactor = 75;

    uint256 public depositTokenPrice;
    uint256 public borrowTokenPrice;

    struct UserInfo {
        uint256 depositAmount;
        uint256 depositInterest;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 lastUpdate;
    }

    mapping(address => UserInfo) public users;

    constructor(address _depositToken, address _borrowToken, uint256 _depositTokenPrice, uint256 _borrowTokenPrice) {
        depositToken = IERC20(_depositToken);
        borrowToken = IERC20(_borrowToken);
        depositTokenPrice = _depositTokenPrice;
        borrowTokenPrice = _borrowTokenPrice;
    }

    function deposit(uint256 _amount) external {
        updateInterest(msg.sender);

        depositToken.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].depositAmount += _amount;
    }

    function withdraw(uint256 _amount) external {
        UserInfo storage user = users[msg.sender];
        updateInterest(msg.sender);

        require(user.borrowAmount == 0, "outstanding loan exists");
        require(user.depositAmount >= _amount, "insufficient balance");

        user.depositAmount -= _amount;
        depositToken.transfer(msg.sender, _amount);
    }

    function borrow(uint256 _amount) external {
        UserInfo storage user = users[msg.sender];
        updateInterest(msg.sender);

        uint256 maxBorrow = user.depositAmount * depositTokenPrice * collateralFactor / 100;
        uint256 borrowAmount = (user.borrowAmount + _amount) * borrowTokenPrice;
        require(maxBorrow >= borrowAmount, "insufficient collateral");

        user.borrowAmount += _amount;
        borrowToken.transfer(msg.sender, _amount);
    }

    function repay(uint256 _amount) external {
        UserInfo storage user = users[msg.sender];
        updateInterest(msg.sender);

        uint256 owed = user.borrowAmount + user.borrowInterest;
        require(_amount <= owed, "repaying more than owed");

        borrowToken.transferFrom(msg.sender, address(this), _amount);
        if (_amount == owed) {
            user.borrowAmount = 0;
            user.borrowInterest = 0;
        } else {
            user.borrowAmount -= _amount;
        }
    }

    function updateInterest(address _user) internal {
        UserInfo storage user = users[_user];
        uint256 timeElapsed = block.timestamp - user.lastUpdate;

        if (user.depositAmount > 0) {
            user.depositInterest += user.depositAmount * depositInterestRate / 100 * timeElapsed / 365 days;
        }

        if (user.borrowAmount > 0) {
            user.borrowInterest += user.borrowAmount * borrowInterestRate / 100 * timeElapsed / 365 days;
        }

        user.lastUpdate = block.timestamp;
    }

    function withdrawWithInterest() external {
        UserInfo storage user = users[msg.sender];
        updateInterest(msg.sender);

        require(user.borrowAmount == 0, "outstanding loan exists");

        uint256 totalAmount = user.depositAmount + user.depositInterest;
        user.depositAmount = 0;
        user.depositInterest = 0;

        depositToken.transfer(msg.sender, totalAmount);
    }
}
