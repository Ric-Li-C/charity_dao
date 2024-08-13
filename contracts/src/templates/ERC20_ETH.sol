// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20_template} from "./ERC20_template.sol";

contract ERC20_ETH is ERC20_template {
    error CampaignEnded();
    error InsufficientAmount(address account, uint amount);
    error ExcessiveAmount(address account, uint amount, uint maxAmount);
    error Suspended();
    error WithinGracePeriod();
    error ZeroBalance();
    error WithdrawalFailed();

    // Compiler issue, this constructor need not to be provided.
    constructor(
        address admin,
        string memory tokenName,
        string memory tokenSymbol,
        uint totalSupply,
        uint price,
        address beneficiary
    )
        ERC20_template(
            admin,
            tokenName,
            tokenSymbol,
            totalSupply,
            price,
            beneficiary
        )
    {}

    function fundRaising() external payable {
        if (balanceOf(address(this)) == 0) {
            revert CampaignEnded();
        }

        if (msg.value < _price) {
            revert InsufficientAmount(_msgSender(), msg.value);
        }

        uint maxAmount = balanceOf(address(this)) * _price;
        if (msg.value > maxAmount) {
            revert ExcessiveAmount(_msgSender(), msg.value, maxAmount);
        }

        uint tokenAmount = (msg.value * 10 ** 18) / _price;
        transfer(_msgSender(), tokenAmount);

        // When all tokens are sold out, mark end time.
        if (balanceOf(address(this)) == 0) {
            _endTime = block.timestamp;
        }
    }

    /*
     * Only beneficiary is allowed to withdraw;
     * Withdrawal allowed only after grace period;
     * Total contract balance will be withdrawn at once.
     */
    function withdraw() external {
        if (_msgSender() != _beneficiary) {
            revert InvalidCaller(_msgSender());
        }

        if (_isSuspended) {
            revert Suspended();
        }

        bool isAllowed = _endTime > 0 &&
            block.timestamp >= _endTime + _gracePeriod;
        if (!isAllowed) {
            revert WithinGracePeriod();
        }

        uint256 balance = address(this).balance;
        if (balance <= 0) {
            revert ZeroBalance();
        }

        (bool success, ) = payable(_beneficiary).call{value: balance}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }
}
