pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {ETHPool} from "../src/ETHPool.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20("Reward Token", 'RWD') {
    constructor(address _owner) {
        _mint(_owner, 100e18);
    }
}

contract DepositRewardsTest is Test {
    address rewardDepositor = address(1);
    address user0 = address(2);
    address user1 = address(3);

    ETHPool public pool;
    RewardToken public rewardToken;

    function setUp() public {
        vm.deal(user0, 10 ether);
        vm.deal(user1, 10 ether);

        rewardToken = new RewardToken(rewardDepositor);
        pool = new ETHPool(rewardToken, rewardDepositor);

        vm.prank(rewardDepositor);
        rewardToken.approve(address(pool), 10e20);

        // @dev advances a week so there is no need to call this function every
        // time the `depositReward` function is called for the first time
        vm.warp(block.timestamp + 7 days);
    }

    ////////////////// STAKE //////////////////

    function test_UpdateUserInfoOnStake() public {
        uint depositAmount = 10 ether;

        vm.prank(user0);
        pool.stakeETH{ value: depositAmount }();

        ETHPool.UserInfo memory user0Info = pool.getUser(user0);

        assertEq(user0Info.balance, depositAmount);
        assertEq(user0Info.lastCollectAt, pool.getRewardPerETHAccrued());
    }

    ////////////////// WITHDRAW //////////////////

    function test_Withdraw() public {
        uint depositAmount = 10 ether;
        uint userBalanceBeforeDeposit = user0.balance;

        vm.prank(user0);
        pool.stakeETH{ value: depositAmount }();

        vm.prank(rewardDepositor);
        pool.depositRewards(5e18);

        vm.prank(user0);
        pool.withdraw(depositAmount);

        uint balanceDelta = userBalanceBeforeDeposit - user0.balance;

        assertEq(balanceDelta, 0);
    }

    function test_UpdateUserInfoOnWithdraw() public {
        uint depositAmount = 10 ether;

        vm.prank(user0);
        pool.stakeETH{ value: depositAmount }();

        vm.prank(rewardDepositor);
        pool.depositRewards(5e18);

        vm.prank(user0);
        pool.withdraw(depositAmount);

        ETHPool.UserInfo memory user = pool.getUser(user0);

        assertEq(user.balance, 0);
    }

    ////////////////// WITHDRAW REWARDS //////////////////

    function test_WithdrawRewards() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        vm.prank(rewardDepositor);
        pool.depositRewards(5e18);

        vm.prank(user0);
        pool.withdrawRewards();

        assertEq(rewardToken.balanceOf(user0), 5e18);
    }

    function test_UpdateUserInfoOnWithdrawRewards() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        vm.prank(rewardDepositor);
        pool.depositRewards(5e18);

        vm.prank(user0);
        pool.withdrawRewards();

        ETHPool.UserInfo memory user = pool.getUser(user0);
        uint rewardPerETHAccrued = pool.getRewardPerETHAccrued();

        assertEq(user.lastCollectAt, rewardPerETHAccrued);
    }

    ////////////////// PENDING REWARDS //////////////////

    function test_PendingRewardsForSingleUser() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        vm.prank(rewardDepositor);
        pool.depositRewards(5e18);

        uint pendingRewards = pool.getPendingRewards(user0);

        assertEq(pendingRewards, 5e18);
    }

    function test_PendingRewardsForDepositBeforeLastReward() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        vm.prank(user1);
        pool.stakeETH{ value: 5 ether }();

        uint rewardsAmount = 10e18;
        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        uint pendingRewardsUser0 = pool.getPendingRewards(user0);
        uint pendingRewardsUser1 = pool.getPendingRewards(user1);

        assertEq(pendingRewardsUser0, uint(6666666666666666660));
        assertEq(pendingRewardsUser1, uint(3333333333333333330));
    }

    function test_PendingRewardsForDepositAfterLastReward() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        uint rewardsAmount = 10e18;
        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        vm.prank(user1);
        pool.stakeETH{ value: 5 ether }();

        uint pendingRewardsUser0 = pool.getPendingRewards(user0);
        uint pendingRewardsUser1 = pool.getPendingRewards(user1);

        assertEq(pendingRewardsUser0, rewardsAmount);
        assertEq(pendingRewardsUser1, uint(0));
    }

    function test_PendingRewardsAfterWithdrawRewards() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        uint rewardsAmount = 10e18;
        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        vm.prank(user0);
        pool.withdrawRewards();

        uint pendingRewardsUser0 = pool.getPendingRewards(user0);

        assertEq(pendingRewardsUser0, 0);
    }

    function test_PendingRewardsAfterWithdrawAllTokens() public {
        uint depositAmount = 10 ether;
        uint rewardsAmount = 10e18;

        vm.prank(user0);
        pool.stakeETH{ value: depositAmount }();

        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        vm.prank(user0);
        pool.withdraw(depositAmount);

        assertEq(pool.getPendingRewards(user0), 0);

        vm.warp(block.timestamp + 7 days);
        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        assertEq(pool.getPendingRewards(user0), 0);
    }

    ////////////////// REWARDS //////////////////

    function test_DepositRewards() public {
        uint rewardsAmount = 10e18;

        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        assertEq(pool.getAvailableRewards(), rewardToken.balanceOf(address(pool)));
    }

    function test_RevertsIfDepositIsEarlierThanOneWeek() public {
        uint rewardsAmount = 10e18;

        vm.startPrank(rewardDepositor);

        pool.depositRewards(rewardsAmount);

        vm.expectRevert(ETHPool.TooEarlyForRewards.selector);
        pool.depositRewards(rewardsAmount);

        vm.stopPrank();
    }

    function test_UpdateRewardPerEthAccrued() public {
        uint rewardsAmount = 10e18;

        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        uint rewardPerETHAccrued = pool.getRewardPerETHAccrued();

        assertEq(rewardPerETHAccrued, 0);
    }

    function test_UpdateRewardPerEthAccruedWithETHInPool() public {
        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        vm.prank(rewardDepositor);
        pool.depositRewards(5e18);

        uint rewardPerETHAccrued = pool.getRewardPerETHAccrued();

        assertEq(rewardPerETHAccrued, 5e17);
    }

    function test_RewardPerEthAccruedWhenNoEthInThePool() public {
        uint rewardsAmount = 5e18;

        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        vm.prank(user0);
        pool.stakeETH{ value: 10 ether }();

        uint rewardPerETHAccrued = pool.getRewardPerETHAccrued();

        assertEq(rewardPerETHAccrued, 0);

        vm.warp(block.timestamp + 7 days);
        vm.prank(rewardDepositor);
        pool.depositRewards(rewardsAmount);

        uint expectedRewardsPerToken = (rewardsAmount * 2) * 1e18 / address(pool).balance;

        assertEq(pool.getRewardPerETHAccrued(), expectedRewardsPerToken);
    }

    function test_IncreaseRewards() public {
        uint rewardsAmount = 10e18;

        vm.startPrank(rewardDepositor);

        pool.depositRewards(rewardsAmount);

        vm.warp(block.timestamp + 7 days);
        pool.depositRewards(rewardsAmount);

        vm.stopPrank();

        assertEq(pool.getAvailableRewards(), rewardToken.balanceOf(address(pool)));
    }

    function test_NotRewardDepositor() public {
        vm.expectRevert(ETHPool.NotRewardDepositor.selector);
        vm.prank(address(2));
        pool.depositRewards(10e18);
    }
}
