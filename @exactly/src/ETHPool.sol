// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ETHPool is AccessControl {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint lastCollectAt;
        uint balance;
    }

    IERC20 public rewardToken;
    /** 
    * @dev Since only the team can deposit rewards, this variable is used to keep track
    * of the tokens deposited in the contract by the wallet who has REWARD_DEPOSITOR_ROLE
    */
    uint internal availableRewards;
    uint internal rewardPerETHAccrued;
    uint internal lastRewardDeposit;
    bytes32 internal constant REWARD_DEPOSITOR_ROLE = keccak256("REWARD_DEPOSITOR_ROLE");
    mapping(address => UserInfo) internal userInfo;

    uint64 internal constant ETH_ACCRUED_BASIS_POINTS = 1e18;
    uint64 internal constant ONE_WEEK = 7 days;

    event ETHStaked(address user, uint amount);
    event ETHWithdrawn(uint amount);
    event RewardsDeposited(uint amount);
    event RewardsWithdrawn(uint amount);

    error ETHTransferFail();
    error TooEarlyForRewards();
    error NotRewardDepositor();
    error AmountGreaterThanBalance();

    constructor(IERC20 _rewardToken, address _rewardDepositor) {
        rewardToken = _rewardToken;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REWARD_DEPOSITOR_ROLE, _rewardDepositor);
    }

    ////////////////// ONLY REWARD DEPOSITOR //////////////////

    function depositRewards(uint _amount) public {
        if (!hasRole(REWARD_DEPOSITOR_ROLE, msg.sender))
            revert NotRewardDepositor();

        if (lastRewardDeposit + ONE_WEEK > block.timestamp)
            revert TooEarlyForRewards();

        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        availableRewards += _amount;

        updateRewardPerETHAccrued();

        lastRewardDeposit = block.timestamp;

        emit RewardsDeposited(_amount);
    }

    ////////////////// PUBLIC //////////////////

    function stakeETH() public payable {
        UserInfo storage user = userInfo[msg.sender];

        user.balance += msg.value;
        user.lastCollectAt += rewardPerETHAccrued;

        emit ETHStaked(msg.sender, msg.value);
    }

    function withdraw(uint _amount) payable external {
        uint balance = userInfo[msg.sender].balance;

        if (_amount > balance)
            revert AmountGreaterThanBalance();

        userInfo[msg.sender].balance = balance - _amount;

        (bool success, ) = payable(msg.sender).call{ value: _amount }("");

        if (!success)
            revert ETHTransferFail();

        withdrawRewards();
    }

    function withdrawRewards() public {
        uint pendingRewards = getPendingRewards(msg.sender);
        userInfo[msg.sender].lastCollectAt = rewardPerETHAccrued;

        rewardToken.safeTransfer(msg.sender, pendingRewards);
    }

    function getPendingRewards(address _user) public view returns (uint) {
        UserInfo memory user = userInfo[_user];

        return user.balance * (rewardPerETHAccrued - user.lastCollectAt) / ETH_ACCRUED_BASIS_POINTS;
    }

    ////////////////// INTERNAL //////////////////

    function updateRewardPerETHAccrued() internal {
        uint balance = address(this).balance;

        if (balance > 0)
            rewardPerETHAccrued = availableRewards * ETH_ACCRUED_BASIS_POINTS / balance;
    }

    ////////////////// EXTERNAL //////////////////

    function getAvailableRewards() external view returns (uint) {
        return availableRewards;
    }

    function getUser(address _user) external view returns (UserInfo memory) {
        return userInfo[_user];
    }

    function getRewardPerETHAccrued() external view returns (uint) {
        return rewardPerETHAccrued;
    }
}

