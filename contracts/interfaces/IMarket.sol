// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "../Decimal.sol";

/**
 * @title Interface for Zora Protocol's Market
 */
interface IMarket {
    struct Bid {
        // Amount of the currency being bid
        uint256 amount;
        // Address to the ERC20 token being used to bid
        address currency;
        // Address of the bidder
        address bidder;
        // Address of the recipient
        address recipient;
        // % of the next sale to award the current owner
        Decimal.D256 sellOnShare;
    }

    struct Ask {
        // Amount of the currency being asked
        uint256 amount;
        // Address to the ERC20 token being asked
        address currency;
    }

    struct BidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        Decimal.D256 prevOwner;
        // % of sale value that goes to the original creator of the nft
        Decimal.D256 creator;
        // % of sale value that goes to the seller (current owner) of the nft
        Decimal.D256 owner;
    }

    event BidCreated(address indexed contractAddress, uint256 indexed tokenId, Bid bid);
    event BidRemoved(address indexed contractAddress, uint256 indexed tokenId, Bid bid);
    event BidFinalized(address indexed contractAddress, uint256 indexed tokenId, Bid bid);
    event AskCreated(address indexed contractAddress, uint256 indexed tokenId, Ask ask);
    event AskRemoved(address indexed contractAddress, uint256 indexed tokenId, Ask ask);

    function bidForTokenBidder(address contractAddress, uint256 tokenId, address bidder)
        external
        view
        returns (Bid memory);

    function currentAskForToken(address contractAddress, uint256 tokenId)
        external
        view
        returns (Ask memory);

    function bidSharesForToken(uint256 tokenId)
        external
        view
        returns (BidShares memory);

    function isValidBid(address contractAddress, uint256 tokenId, uint256 bidAmount)
        external
        view
        returns (bool);

    function isValidBidShares(BidShares calldata bidShares)
        external
        pure
        returns (bool);

    function splitShare(Decimal.D256 calldata sharePercentage, uint256 amount)
        external
        pure
        returns (uint256);

    function configure(address mediaContractAddress) external;

    function setBidShares(uint256 tokenId, BidShares calldata bidShares)
        external;

    function setAsk(address contractAddress, uint256 tokenId, Ask calldata ask) external;

    function removeAsk(address contractAddress, uint256 tokenId) external;

    function setBid(
        address contractAddress,
        uint256 tokenId,
        Bid calldata bid,
        address spender
    ) external;

    function removeBid(address contractAddress, uint256 tokenId, address bidder) external;

    function acceptBid(address contractAddress, uint256 tokenId, Bid calldata expectedBid) external;
}
