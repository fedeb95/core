// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

/**
 * @title Interface for a NFT royalty ledger
 */
interface IRoyaltyLedger {

    function enlist(address tokenContract, address royaltyContract) external;

    function delist(address tokenContract) external;

    function enlisted(address tokenContract) external view returns(bool);

    function royaltyInfo(address tokenContract, uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}
