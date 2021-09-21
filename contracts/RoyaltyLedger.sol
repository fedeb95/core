// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRoyaltyLedger.sol";

/**
 * @title A Market for pieces of media
 * @notice This contract contains all of the market logic for Media
 */
contract RoyaltyLedger is IRoyaltyLedger {

    mapping(address => address) private _ledger;

    modifier onlyEnlisted(address contractAddress){
        require(_ledger[contractAddress] != address(0), "Royalties not enlisted for contract!");
        _;
    }

    modifier ownsContract(address contractAddress){
        Ownable ownableContract = Ownable(contractAddress);
        require(ownableContract.owner() == msg.sender, "Sender must own contract!");
        _;
    }


    function enlist(address tokenContract, address royaltyContract) external override ownsContract(tokenContract) {
        _ledger[tokenContract] = royaltyContract;
    }

    function delist(address tokenContract) external override ownsContract(tokenContract) {
        delete _ledger[tokenContract];
    }

    function royaltyInfo(address tokenContract, uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount){
       return IERC2981(_ledger[tokenContract]).royaltyInfo(tokenId, salePrice);
    }

}

