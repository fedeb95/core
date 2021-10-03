// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/RoyaltyEngineV1.sol";

import "./IRoyaltyLedger.sol";

/**
 * @title A royalty ledger for ERC721 tokens.
 * @notice This contract contains all of the royalties logic. An enlisted royalty provider must implement EIP-2981
 */
contract RoyaltyLedger is RoyaltyEngineV1 {

    struct Royalties{
        address payable[] recipients;
        uint256[] percents; 
        bool enlisted;
    }

    mapping(address => mapping(uint256 => Royalties)) private royalties;

    function setRoyalty(address contractAddress, 
                        uint256 tokenId, 
                        address payable[] memory recipients,
                        uint256[] memory percents) external {
        Royalties memory r;
        r.recipients = recipients;
        r.percents = percents;
        r.enlisted = true;
        royalties[contractAddress][tokenId] = r; 
    }

    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public override 
        returns(address payable[] memory recipients, uint256[] memory amounts) {
        if(royalties[tokenAddress][tokenId].enlisted){
            // TODO calculate amounts
        }
        return super.getRoyalty(tokenAddress, tokenId, value);
    }

    // TODO view
}

