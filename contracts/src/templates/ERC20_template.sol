// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20_template is ERC20 {
    error InvalidCaller(address caller);

    address internal _admin;
    uint internal _price;
    address internal _beneficiary;
    bool internal _isSuspended;
    uint internal _gracePeriod = 31 days;
    uint internal _endTime;

    /*
     * `totalSupply` is token amount without decimals.
     *
     * `decimals()` is 18, defined in ERC20.sol.
     */
    constructor(
        address admin,
        string memory tokenName,
        string memory tokenSymbol,
        uint totalSupply,
        uint price,
        address beneficiary
    ) ERC20(tokenName, tokenSymbol) {
        _admin = admin;
        _mint(address(this), totalSupply * 10 ** decimals());
        _price = price;
        _beneficiary = beneficiary;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Admin functions reserved for special senarios.
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    modifier onlyAdmin() {
        if (_msgSender() != _admin) {
            revert InvalidCaller(_msgSender());
        }
        _;
    }

    // Admin could set suspend status in special occasion.
    function flipSuspensionStatus() external onlyAdmin {
        _isSuspended = !_isSuspended;
    }

    // Admin could update beneficiary in special occasion.
    function updateBeneficiary(address newBeneficiary) external onlyAdmin {
        _beneficiary = newBeneficiary;
    }

    // Admin could update grace period in special occasion.
    // `newGracePeriod` is in format of seconds.
    function updateGracePeriod(uint newGracePeriod) external onlyAdmin {
        _gracePeriod = newGracePeriod;
    }

    // Admin could end fund raising if the tokens are not sold out after a long time.
    function earlyTermination() external onlyAdmin {
        _endTime = block.timestamp;
    }
}
