//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IManifold {
    function mintBase(address to, string calldata uri) external  returns(uint256);
}