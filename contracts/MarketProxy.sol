// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./interfaces/IMarket.sol";

// TODO set bid vault address so that tokens don't get stuck when swapping implementations!!!
contract MarketProxy is IMarket {
    address private _owner;

    address private _impl;

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function setImpl(address contractAddress) public onlyOwner {
        _impl = contractAddress; 
    }

    function impl() external view returns (address) {
        return _impl;
    }

    function bidForTokenBidder(address contractAddress, uint256 tokenId, address bidder)
        external
        view
        override
        returns (Bid memory)
    {
        return IMarket(_impl).bidForTokenBidder(contractAddress, tokenId, bidder);
    }

    function currentAskForToken(address contractAddress, uint256 tokenId)
        external
        view
        override
        returns (Ask memory)
    {
        return IMarket(_impl).currentAskForToken(contractAddress, tokenId);
    }

    function isValidBid(address contractAddress, uint256 tokenId, uint256 bidAmount)
        public
        view
        override
        returns (bool)
    {
        return IMarket(_impl).isValidBid(contractAddress, tokenId, bidAmount);
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor() {
        _owner = msg.sender;
    }

    function register(address contractAddress) 
        external 
        override 
    {
        return IMarket(_impl).register(contractAddress); 
    }

    function setAsk(address contractAddress, uint256 tokenId, Ask memory ask)
        public
        override
    {
        return IMarket(_impl).setAsk(contractAddress, tokenId, ask);        
    }

    function removeAsk(address contractAddress, uint256 tokenId) 
        external 
        override 
    {
        return IMarket(_impl).removeAsk(contractAddress, tokenId);
    }

    function setBid(
        address contractAddress,
        uint256 tokenId,
        Bid memory bid,
        address spender
    ) 
        public 
        override
    {
        return IMarket(_impl).setBid(contractAddress, tokenId, bid, spender);
    }

    function removeBid(address contractAddress, uint256 tokenId, address bidder)
        public
        override
    {
        return IMarket(_impl).removeBid(contractAddress, tokenId, bidder);
    }

    function acceptBid(address contractAddress, uint256 tokenId, Bid calldata expectedBid)
        external
        override
    {
        return IMarket(_impl).acceptBid(contractAddress, tokenId, expectedBid);
    }
}
