// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// 1. Deposit ETH and receive weekly rewards
// 2. Must be able to withdraw at any time
// 3. New rewards are deposited manually into the pool each week => only admin
// 4. When the team deposits the rewards, only users with staked tokens should receive rewards

/// @title Ether Pool with weekly rewards
/// @author Ian K. Guimaraes
/// @notice 
/// @dev 
contract ETHPool is AccessControl {
    bytes32 public constant REWARD_DEPOSITOR_ROLE = keccak256("REWARD_DEPOSITOR_ROLE");

    // TODO use safe transfer
    // TODO why use safe transfer
    IERC20 public rewardToken;

    error NotRewardDepositor();

    constructor(IERC20 _rewardToken, address _depositor) {
        rewardToken = _rewardToken;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REWARD_DEPOSITOR_ROLE, _depositor);
    }

    function depositRewards() public {
        if (hasRole(REWARD_DEPOSITOR_ROLE, msg.sender))
            revert NotRewardDepositor();

         console.log('Rewards deposited');
    }
}

