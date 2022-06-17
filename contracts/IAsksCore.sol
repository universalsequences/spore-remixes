//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IAsksCore {
    function createAsk(
         address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) external;
}