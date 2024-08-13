// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721_template} from "./ERC721_template.sol";

contract ERC721_ETH is ERC721_template {
    error CampaignEnded();
    error InsufficientAmount(address account, uint amount);
    error ExcessiveAmount(address account, uint amount, uint totalMinted);
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
        string memory initialUri,
        address beneficiary
    )
        ERC721_template(
            admin,
            tokenName,
            tokenSymbol,
            totalSupply,
            price,
            initialUri,
            beneficiary
        )
    {}

    function fundRaising() external payable {
        uint totalMinted = _totalMinted();
        if (totalMinted >= _maxSupply) {
            revert CampaignEnded();
        }

        if (msg.value < _price) {
            revert InsufficientAmount(_msgSender(), msg.value);
        }

        uint tokenAmount = (msg.value * 10 ** 18) / _price;
        if (tokenAmount + totalMinted > _maxSupply) {
            revert ExcessiveAmount(_msgSender(), msg.value, totalMinted);
        }

        _safeMint(_msgSender(), tokenAmount, "");

        // When all NFTs are sold out, mark end time.
        if (totalMinted >= _maxSupply) {
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
