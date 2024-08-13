// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";

contract ERC721_template is ERC721A, Ownable {
    error InvalidCaller(address caller);

    address internal _admin;
    uint internal _maxSupply;
    uint internal _price;
    string internal _uri;
    address internal _beneficiary;
    bool internal _isSuspended;
    uint internal _gracePeriod = 31 days;
    uint internal _endTime;

    // `totalSupply` is token amount without decimals.
    constructor(
        address admin,
        string memory tokenName,
        string memory tokenSymbol,
        uint totalSupply,
        uint price,
        string memory initialUri,
        address beneficiary
    ) ERC721A(tokenName, tokenSymbol) Ownable(_msgSender()) {
        _admin = admin;
        _maxSupply = totalSupply;
        _price = price;
        _uri = initialUri;
        _beneficiary = beneficiary;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function updateBaseUri(string calldata newBaseUri) external onlyOwner {
        _uri = newBaseUri;
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
