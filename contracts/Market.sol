// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Decimal.sol";
import "./interfaces/IMarket.sol";

/**
 * @title A Market for pieces of media
 * @notice This contract contains all of the market logic for Media
 */
contract Market is IMarket {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _owner;

    mapping(address => bool) registeredContracts;

    // Mapping from token to mapping from bidder to bid
    mapping(address => mapping(uint256 => mapping(address => Bid))) private _tokenBidders;

    // Mapping from token to the current ask for the token
    mapping(address => mapping(uint256 => Ask)) private _tokenAsks;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyRegistered(address contractAddress){
        require(registeredContracts[contractAddress], "Contract not registered!");
        _;
    }

    modifier ownsContract(address contractAddress){
        Ownable ownableContract = Ownable(contractAddress);
        require(ownableContract.owner() == msg.sender, "Sender must own contract!");
        _;
    }

    modifier ownsToken(address contractAddress, uint256 tokenId){
        IERC721 nftContract = IERC721(contractAddress);
        require(msg.sender == nftContract.ownerOf(tokenId), "Sender doesn't own token!");
        _;
    }

    /* ****************
     * View Functions
     * ****************
     */
    function bidForTokenBidder(address contractAddress, uint256 tokenId, address bidder)
        external
        view
        override
        onlyRegistered(contractAddress)
        returns (Bid memory)
    {
        return _tokenBidders[contractAddress][tokenId][bidder];
    }

    function currentAskForToken(address contractAddress, uint256 tokenId)
        external
        view
        override
        onlyRegistered(contractAddress)
        returns (Ask memory)
    {
        return _tokenAsks[contractAddress][tokenId];
    }

    /**
     * @notice Validates that the bid is valid by ensuring that the bid amount can be split perfectly into all the bid shares.
     *  We do this by comparing the sum of the individual share values with the amount and ensuring they are equal. Because
     *  the splitShare function uses integer division, any inconsistencies with the original and split sums would be due to
     *  a bid splitting that does not perfectly divide the bid amount.
     */
    function isValidBid(address contractAddress, uint256 tokenId, uint256 bidAmount)
        public
        view
        override
        onlyRegistered(contractAddress)
        returns (bool)
    {
        // TODO replace with royalties!
/*
        BidShares memory bidShares = bidSharesForToken(tokenId);
        require(
            isValidBidShares(bidShares),
            "Market: Invalid bid shares for token"
        );
*/
        return true;
/*
            bidAmount != 0 &&
            (bidAmount ==
                splitShare(bidShares.creator, bidAmount)
                    .add(splitShare(bidShares.prevOwner, bidAmount))
                    .add(splitShare(bidShares.owner, bidAmount)));
*/
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor() {
        _owner = msg.sender;
    }

    /**
     * @notice registers a contract in this market. Allows all other function calls
     */
    function register(address contractAddress) 
        external 
        override 
        ownsContract(contractAddress)
    {
        registeredContracts[contractAddress] = true;
    }

    /**
     * @notice Sets the ask on a particular media. If the ask cannot be evenly split into the media's
     * bid shares, this reverts.
     */
    function setAsk(address contractAddress, uint256 tokenId, Ask memory ask)
        public
        override
        onlyRegistered(contractAddress)
        ownsToken(contractAddress, tokenId)
    {
        require(
            isValidBid(contractAddress, tokenId, ask.amount),
            "Market: Ask invalid for share splitting"
        );

        _tokenAsks[contractAddress][tokenId] = ask;
        emit AskCreated(contractAddress, tokenId, ask);
    }

    /**
     * @notice removes an ask for a token and emits an AskRemoved event
     */
    function removeAsk(address contractAddress, uint256 tokenId) 
        external 
        override 
        onlyRegistered(contractAddress)
        ownsToken(contractAddress, tokenId)
    {
        emit AskRemoved(contractAddress, tokenId, _tokenAsks[contractAddress][tokenId]);
        delete _tokenAsks[contractAddress][tokenId];
    }

    /**
     * @notice Sets the bid on a particular media for a bidder. The token being used to bid
     * is transferred from the spender to this contract to be held until removed or accepted.
     * If another bid already exists for the bidder, it is refunded.
     */
    function setBid(
        address contractAddress,
        uint256 tokenId,
        Bid memory bid,
        address spender
    ) 
        public 
        override
        onlyRegistered(contractAddress)
    {
        //BidShares memory bidShares = _bidShares[tokenId];
        // TODO replace with valid royalty split according to ledger
        /*require(
            bidShares.creator.value.add(bid.sellOnShare.value) <=
                uint256(100).mul(Decimal.BASE),
            "Market: Sell on fee invalid for share splitting"
        );
        */
        require(bid.bidder != address(0), "Market: bidder cannot be 0 address");
        require(bid.amount != 0, "Market: cannot bid amount of 0");
        require(
            bid.currency != address(0),
            "Market: bid currency cannot be 0 address"
        );
        require(
            bid.recipient != address(0),
            "Market: bid recipient cannot be 0 address"
        );

        Bid storage existingBid = _tokenBidders[contractAddress][tokenId][bid.bidder];

        // If there is an existing bid, refund it before continuing
        if (existingBid.amount > 0) {
            removeBid(contractAddress, tokenId, bid.bidder);
        }

        IERC20 token = IERC20(bid.currency);

        // We must check the balance that was actually transferred to the market,
        // as some tokens impose a transfer fee and would not actually transfer the
        // full amount to the market, resulting in locked funds for refunds & bid acceptance
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(spender, address(this), bid.amount);
        uint256 afterBalance = token.balanceOf(address(this));
        _tokenBidders[contractAddress][tokenId][bid.bidder] = Bid(
            afterBalance.sub(beforeBalance),
            bid.currency,
            bid.bidder,
            bid.recipient,
            bid.sellOnShare
        );
        emit BidCreated(contractAddress, tokenId, bid);

        // If a bid meets the criteria for an ask, automatically accept the bid.
        // If no ask is set or the bid does not meet the requirements, ignore.
        if (
            _tokenAsks[contractAddress][tokenId].currency != address(0) &&
            bid.currency == _tokenAsks[contractAddress][tokenId].currency &&
            bid.amount >= _tokenAsks[contractAddress][tokenId].amount
        ) {
            // Finalize exchange
            _finalizeNFTTransfer(contractAddress, tokenId, bid.bidder);
        }
    }

    /**
     * @notice Removes the bid on a particular media for a bidder. The bid amount
     * is transferred from this contract to the bidder, if they have a bid placed.
     */
    function removeBid(address contractAddress, uint256 tokenId, address bidder)
        public
        override
        onlyRegistered(contractAddress)
    {
        Bid storage bid = _tokenBidders[contractAddress][tokenId][bidder];
        uint256 bidAmount = bid.amount;
        address bidCurrency = bid.currency;

        require(bid.amount > 0, "Market: cannot remove bid amount of 0");

        IERC20 token = IERC20(bidCurrency);

        emit BidRemoved(contractAddress, tokenId, bid);
        delete _tokenBidders[contractAddress][tokenId][bidder];
        token.safeTransfer(bidder, bidAmount);
    }

    /**
     * @notice Accepts a bid from a particular bidder. Can only be called by the media contract.
     * See {_finalizeNFTTransfer}
     * Provided bid must match a bid in storage. This is to prevent a race condition
     * where a bid may change while the acceptBid call is in transit.
     * A bid cannot be accepted if it cannot be split equally into its shareholders.
     * This should only revert in rare instances (example, a low bid with a zero-decimal token),
     * but is necessary to ensure fairness to all shareholders.
     */
    function acceptBid(address contractAddress, uint256 tokenId, Bid calldata expectedBid)
        external
        override
        onlyRegistered(contractAddress)
        ownsToken(contractAddress, tokenId)
    {
        Bid memory bid = _tokenBidders[contractAddress][tokenId][expectedBid.bidder];
        require(bid.amount > 0, "Market: cannot accept bid of 0");
        require(
            bid.amount == expectedBid.amount &&
                bid.currency == expectedBid.currency &&
                bid.sellOnShare.value == expectedBid.sellOnShare.value &&
                bid.recipient == expectedBid.recipient,
            "Market: Unexpected bid found."
        );
        require(
            isValidBid(contractAddress, tokenId, bid.amount),
            "Market: Bid invalid for share splitting"
        );

        _finalizeNFTTransfer(contractAddress, tokenId, bid.bidder);
    }

    /**
     * @notice Given a token ID and a bidder, this method transfers the value of
     * the bid to the shareholders. It also transfers the ownership of the media
     * to the bid recipient. Finally, it removes the accepted bid and the current ask.
     */
    function _finalizeNFTTransfer(address contractAddress, uint256 tokenId, address bidder) private {
        Bid memory bid = _tokenBidders[contractAddress][tokenId][bidder];
        // TODO replace with call to RoyaltyLedger BidShares storage bidShares = _bidShares[contractAddress][tokenId];

        IERC20 token = IERC20(bid.currency);

        // Transfer bid share to owner of media
        token.safeTransfer(
            IERC721(contractAddress).ownerOf(tokenId),
            bid.amount // TODO replace with roylaties calc splitShare(bidShares.owner, bid.amount)
        );

        // TODO change with royalties, Media creator with owner of contract
        // Transfer bid share to creator of media
        //token.safeTransfer(
        //    Media(mediaContract).tokenCreators(tokenId),
        //    splitShare(bidShares.creator, bid.amount)
        // );

        // Transfer media to bid recipient
        IERC721 nftContract = IERC721(contractAddress);
        //previousTokenOwners[tokenId] = nftContract.ownerOf(tokenId);
        nftContract.safeTransferFrom(nftContract.ownerOf(tokenId), bid.recipient, tokenId);

        // Remove the accepted bid
        delete _tokenBidders[contractAddress][tokenId][bidder];

        //emit BidShareUpdated(tokenId, bidShares);
        emit BidFinalized(contractAddress, tokenId, bid);
    }
}
