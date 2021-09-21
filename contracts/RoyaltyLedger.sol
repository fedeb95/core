// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRoyaltyLedger.sol";

/**
 * @title A royalty ledger for ERC721 tokens.
 * @notice This contract contains all of the royalties logic. An enlisted royalty provider must implement EIP-2981
 */
contract RoyaltyLedger is IRoyaltyLedger {

    struct Royalty{
        address receiver;
        uint256 percentage;
    }

    mapping(address => address) private _ledger;
    mapping(address => mapping(uint256 => Royalty)) public royalties;

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

    function enlisted(address tokenContract) public view override returns(bool){
        return _ledger[tokenContract] != address(0);
    }

    function setRoyaltyInfo(address tokenContract, uint256 tokenId, address receiver, uint256 percentage) external ownsContract(tokenContract) {
        Royalty memory r;
        r.receiver = receiver;
        r.percentage = percentage; 
        royalties[tokenContract][tokenId] = r;
    }

    function royaltyInfo(address tokenContract, uint256 tokenId, uint256 salePrice) 
    external 
    view 
    override 
    returns (address, uint256){
        if(!enlisted(tokenContract)){
            Royalty memory royalty = royalties[tokenContract][tokenId]; 
            require(royalty.receiver != address(0) && royalty.percentage >= 0 &&
                royalty.percentage <= 100);
            return (royalty.receiver, salePrice * royalty.percentage / 100); //TODO better math!
        }
       return IERC2981(_ledger[tokenContract]).royaltyInfo(tokenId, salePrice);
    }

}

