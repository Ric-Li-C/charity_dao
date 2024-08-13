// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ContractFactory is Ownable {
    error NotAuthorized();

    mapping(address => bool) internal _isEnabled;
    mapping(address => address) internal _fundingTokenAddress;
    mapping(address => uint) internal _goalAmount;

    constructor() Ownable(_msgSender()) {}

    /*
     * Only owner of the contract can initialize a new campaign.
     *
     * `goalAmount` is target token amount without decimals.
     */
    function initializeCampaign(
        address initializer,
        address fundingTokenAddress,
        uint goalAmount
    ) external onlyOwner {
        _isEnabled[initializer] = true;
        _fundingTokenAddress[initializer] = fundingTokenAddress;
        _goalAmount[initializer] = goalAmount;
    }
}
