//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IZoraModuleManager.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ISplitMain.sol";
import "./IAsksCore.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SporesMinter is ReentrancyGuard, AdminControl, ICreatorExtensionTokenURI {
    // can change by admin
    address private SPORES_DAO_ADDRESS;

    uint32 public constant PERCENTAGE_SCALE = 1e4;
    uint32 public constant DISTRIBUTER_SCALE = 1e2;

    uint32 private _collectorShare = 19*PERCENTAGE_SCALE;
    uint32 private _artistShare = 40*PERCENTAGE_SCALE;
    uint32 private _foundationShare = 21*PERCENTAGE_SCALE;
    uint32 private _remixerShare = 20*PERCENTAGE_SCALE;

    ISplitMain private splitMain;
    address private _sporesRemixManifold;
    address private _foundationAddress;


    IAsksCore private _asksCore;

    mapping(uint256=>string) private _tokenURIs;
    uint32 [4] private _splitAmounts;

    event NewRemixMinted(uint256 tokenId, address artist, address remixer, address splitsAddress);

    constructor() ICreatorExtensionTokenURI() {
        // Load up the various contracts this works w/
        splitMain = ISplitMain(address(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE));
        _sporesRemixManifold = address(0x9efe0C372310E179104AA5F478e20355a2538e43);
        _asksCore = IAsksCore(address(0xA98D3729265C88c5b3f861a0c501622750fF4806));
        _foundationAddress = address(0x3e2e9604AE811e29b8Fa22B12F67f79eb67D17bA);

        // approve the asks module to use this one
        IZoraModuleManager(address(0xa248736d3b73A231D95A5F99965857ebbBD42D85)).setApprovalForModule(
            address(0xA98D3729265C88c5b3f861a0c501622750fF4806), // zora asks module address
            true);
    }

    function mintSongTest(
        address[] calldata recipients,
        uint32[] calldata amounts,
        uint32 distributer_fee
        ) 
    public  returns (address)  {
        return ISplitMain(address(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE)).createSplit(
            recipients, amounts, distributer_fee, address(0));
    }

    function mintSong(
        address sourceTokenContract, // address of contract containing the NFT being remixed
        uint256 sourceTokenId, // the tokenId of the NFT being remixed
        address remixerAddress, // wallet address of person who remixed the track
        string calldata remixTokenURI, // the tokenURI containing the remixed track
        uint32 DISTRIBUTER_FEE,
        uint256 askPrice, // price to be sold for
        uint16 findersFeeBps,
        bool createAsk
//      
        ) 
    public  returns (address)  {
        address collectorAddress = IERC721(sourceTokenContract).ownerOf(sourceTokenId);

        // the recipients array needs to be ordered by ADDRESS.
        // the splitAmounts array needs to reflect the ordering seen in "recipients"
        // the three variables are collectorAddress, msg.sender, remixerAddress
        // one constant is _foundationAddress
        // todo: handle case where remixerAddress == collector
        // todo: handle case where remixerAddress == collector==msg.sender
        address[] memory recipients;
        uint32[] memory splitAmounts;
        if (msg.sender == collectorAddress) {
            recipients = new address[](3);
            recipients[0] = collectorAddress;
            recipients[1] = remixerAddress;
            recipients[2] = _foundationAddress;
            splitAmounts = new uint32[](3); 
            splitAmounts[0] = _collectorShare + _artistShare;
            splitAmounts[1] = _remixerShare;
            splitAmounts[2] = _foundationShare;
        } else {
            recipients = new address[](4);
            recipients[0] = collectorAddress;
            recipients[1] = remixerAddress;
            recipients[2] = _foundationAddress;
            recipients[3] = msg.sender; // the artist 

            splitAmounts = new uint32[](4); 
            splitAmounts[0] = _collectorShare;
            splitAmounts[1] = _remixerShare;
            splitAmounts[2] = _foundationShare;
            splitAmounts[3] = _artistShare;
        }

        sortSplitArrays(recipients, splitAmounts);

        address songSplitsAddress = splitMain.createSplit(
            recipients, splitAmounts, 0, address(0));

        // mint to manifold
        uint256 tokenId = IERC721CreatorCore(_sporesRemixManifold).mintExtension(msg.sender, "");

        // store the
        setTokenURI(tokenId, remixTokenURI);
        
        // In order for this createAsk to work, we need to do a few approvals (outside of this contract)
        // 1. This contract must be an approved operator for the manifold remix contract.
        // 2. Need to approve the zora asks module for moving tokens
        if (createAsk) {
            _asksCore.createAsk(
                _sporesRemixManifold,
                tokenId,
                askPrice,
                address(0), // currency address is 0 (eth)
                songSplitsAddress, // generated split ddress
                findersFeeBps // finders fee
            );  

            emit NewRemixMinted(tokenId, msg.sender, remixerAddress, songSplitsAddress);
        }

        // Thought/notes/todos: set royalties on manifold using the splits address
        // sidenote: since the minter doesn't have admin access to manifold contract, there needs to be a way
        // to adjust "their" royalties % later on. Probably need a function for that
        // though note that the royalty percentage they specify will take out the split from ther
        // 
        
        return songSplitsAddress;
    }

    function sortSplitArrays(address[] memory recipients, uint32[] memory amounts) public   {
       quickSort(recipients, amounts, int(0), int(recipients.length - 1));
    }

    function quickSort(address[] memory arr, uint32[] memory arr2,  int left, int right) internal {
        int i = left;
        int j = right;
        if(i==j) return;
        address pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                (arr2[uint(i)], arr2[uint(j)]) = (arr2[uint(j)], arr2[uint(i)]);

                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, arr2, left, j);
        if (i < right)
            quickSort(arr, arr2, i, right);
    }
    
    function setSplitAmounts(
        uint32 daoAmount,
        uint32 collectorAmount, 
        uint32 remixerAmount, 
        uint32 artistAmount) onlyOwner public   {
        _foundationShare = daoAmount*PERCENTAGE_SCALE;
        _collectorShare = collectorAmount*PERCENTAGE_SCALE;
        _remixerShare = remixerAmount*PERCENTAGE_SCALE;
        _artistShare = artistAmount*PERCENTAGE_SCALE;
    }
 

    function setSporesDAOAddress(address spores) onlyOwner public {
        SPORES_DAO_ADDRESS = spores;
    }
    

    function tokenURI(address creator, uint256 tokenId)  external view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setTokenURI( uint256 tokenId, string calldata remixTokenURI) public  {
        _tokenURIs[tokenId] = remixTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC721CreatorCore).interfaceId || 
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId || 
            AdminControl.supportsInterface(interfaceId) || 
            super.supportsInterface(interfaceId);
    }
}
