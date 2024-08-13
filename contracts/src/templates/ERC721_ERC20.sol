// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721_template} from "./ERC721_template.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * For funding token, only supports ERC-20 token with 18 decimal places.
 *
 * Does not support ERC-20 token with 6 decimal places, eg. USDC.
 */
contract ERC721_ERC20 is ERC721_template {
    error CampaignEnded();
    error InsufficientAmount(address account, uint amount);
    error ExcessiveAmount(address account, uint amount, uint totalMinted);
    error PaymentNotApproved(
        address account,
        uint256 allowance,
        uint256 amount
    );
    error Suspended();
    error WithinGracePeriod();
    error ZeroBalance();
    error WithdrawalFailed();

    IERC20 private _fundingToken;
    address private _fundingTokenAddr;

    // Compiler issue, this constructor need not to be provided.
    constructor(
        address admin,
        string memory tokenName,
        string memory tokenSymbol,
        uint totalSupply,
        address fundingTokenAddr,
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
    {
        _fundingTokenAddr = fundingTokenAddr;
        _fundingToken = IERC20(_fundingTokenAddr);
    }

    // `amount` is funding token amount with decimals;
    function fundRaising(uint amount) external {
        uint totalMinted = _totalMinted();
        if (totalMinted >= _maxSupply) {
            revert CampaignEnded();
        }

        if (amount < _price) {
            revert InsufficientAmount(_msgSender(), amount);
        }

        uint tokenAmount = (amount * 10 ** 18) / _price;
        if (tokenAmount + totalMinted > _maxSupply) {
            revert ExcessiveAmount(_msgSender(), amount, totalMinted);
        }

        // Check to make sure caller has approved this contract to transfer funding token (to this contract)
        uint256 allowance = _fundingToken.allowance(
            _msgSender(),
            address(this)
        );
        if (allowance < amount) {
            revert PaymentNotApproved(_msgSender(), allowance, amount);
        }

        _fundingToken.transferFrom(_msgSender(), address(this), amount);

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

        uint256 balance = _fundingToken.balanceOf(address(this));
        if (balance <= 0) {
            revert ZeroBalance();
        }

        bool isSuccess = _fundingToken.transfer(_beneficiary, balance);
        if (!isSuccess) {
            revert WithdrawalFailed();
        }
    }
}
