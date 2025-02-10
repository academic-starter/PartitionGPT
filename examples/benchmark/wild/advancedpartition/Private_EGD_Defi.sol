// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../router.sol";

contract EGD_Finance is OwnableUpgradeable {
    IPancakeRouter02 public router;
    IERC20 public U;
    IERC20 public EGD;
    address public pair;
    uint startTime;
    uint[] public rate;
    address public fund;
    uint[] referRate;
    mapping(uint => uint) public dailyStake;
    address wallet;
    uint stakeId;
    struct UserInfo {
        uint totalAmount;
        uint[] userStakeList;
        address invitor;
        bool isRefer;

    mapping(address => UserInfo) public userInfo;
