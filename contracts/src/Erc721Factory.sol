// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContractFactory} from "./ContractFactory.sol";
import {ERC721_ETH} from "./templates/ERC721_ETH.sol";
import {ERC721_ERC20} from "./templates/ERC721_ERC20.sol";

contract Erc721Factory is ContractFactory {
    /*
     * Once a campaign is initialized, initializer address can deploy the campaign.
     *
     * For funding token, only supports ERC-20 token with 18 decimal places.
     * Does not support ERC-20 token with 6 decimal places, eg. USDC.
     *
     * `totalSupply` is token amount without decimals. It should not be set too small.
     * User's minimum payment will be `(goalAmount * 10 ** 18) / totalSupply` (the same number as `price`).
     */
    function deployCampaign(
        string memory tokenName,
        string memory tokenSymbol,
        uint totalSupply,
        string memory initialUri,
        address beneficiary
    ) external returns (address contractAddress) {
        if (!_isEnabled[_msgSender()]) {
            revert NotAuthorized();
        }

        bool isGasToken = _fundingTokenAddress[_msgSender()] == address(0);
        uint price = (_goalAmount[_msgSender()] * 10 ** 18) / totalSupply;

        if (isGasToken) {
            contractAddress = address(
                new ERC721_ETH(
                    owner(),
                    tokenName,
                    tokenSymbol,
                    totalSupply,
                    price,
                    initialUri,
                    beneficiary
                )
            );
        } else {
            contractAddress = address(
                new ERC721_ERC20(
                    owner(),
                    tokenName,
                    tokenSymbol,
                    totalSupply,
                    _fundingTokenAddress[_msgSender()],
                    price,
                    initialUri,
                    beneficiary
                )
            );
        }

        // Each initializer can only deploy one campaign.
        _isEnabled[_msgSender()] = false;
    }
}
