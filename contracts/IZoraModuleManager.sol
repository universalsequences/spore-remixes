//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IZoraModuleManager {
    function setApprovalForModule(address _module, bool _approved) external;
}