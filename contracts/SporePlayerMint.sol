//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.12;
import "./Base64.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SporePlayerMinter is ReentrancyGuard, AdminControl, ICreatorExtensionTokenURI {
    // manifold core creator contract (where the actual tokens go)
    address private _core;

    mapping(uint256=>uint32) private _tokenColors;
    mapping(uint256=>uint32) private _tokenSkins;
    mapping(uint256=>uint32) private _tokenSwirls;
    mapping(uint256=>uint32) private _tokenSmokes;
    mapping(uint256=>string) private _tokenImages;

    // for images
    string private _ipfsGateway = "https://zequencer.mypinata.cloud/ipfs/";

    // location of the player (the configuration of the player goes in the query params)
    string private _baseTokenURI;
    string private _description = "This is the description";

    uint256 private _mintPrice = 1e16; // 0.01 ETH
    address private _recipientAddress;

    constructor(string memory baseTokenURI) ICreatorExtensionTokenURI() {
        _core = address(0x9efe0C372310E179104AA5F478e20355a2538e43);
        setBaseTokenURI(baseTokenURI);
        _recipientAddress = msg.sender;
    }

    // can be used to set an 0xSplits as where the funds go upon withdrawing
    function setRecipientAddress(address recipientAddress) public adminRequired {
        _recipientAddress = recipientAddress;
    }

     // can be used to set an 0xSplits as where the funds go upon withdrawing
    function setDescription(string calldata description) public adminRequired {
        _description = description;
    }

    // drain the contract of funds and send to recipient
    function withdraw() public adminRequired {
        payable(_recipientAddress).transfer(address(this).balance);
    }

    // if we update the player, we just need to call this once and it will update for all
    // tokens
    function setBaseTokenURI(string memory baseTokenURI) public adminRequired {
        _baseTokenURI = baseTokenURI;
    }

    // set the IPFS gateway used for image
    function setIPFSGateway(string memory gateway) public  adminRequired {
        _ipfsGateway = gateway;
    }

    // †he actual mint function to be called when minting
    // costs _mintPrice amount in gwei to mint
    function mint(
        uint32 color,
        uint32 skin,
        uint32 swirl,
        uint32 smoke,
        string calldata imageCID // the image for the player screenshotted on the users machine
        ) 
    public payable returns (uint256)  {
        require(msg.value >= _mintPrice, "Must be at least mint price");
        uint256 tokenId = IERC721CreatorCore(_core).mintExtension(msg.sender, "");

        // store the token's "appearance" settings
        _tokenColors[tokenId] = color;
        _tokenSkins[tokenId] = skin;
        _tokenSwirls[tokenId] = swirl;
        _tokenSmokes[tokenId] = smoke;
        _tokenImages[tokenId] = imageCID;
        return tokenId;
    }

    // when calling tokenURI in the core manifold ERC721 contract, it will really use this
    // to calculate the tokenURI
    function tokenURI(address core, uint256 tokenId)  external view override returns (string memory) {
        require(core == _core, "Invalid token");
        string memory url = string.concat(
            _baseTokenURI,
            "?tokenId=",
            uint2str(tokenId),
            "&color=",
            uint2str(_tokenColors[tokenId]),
            "&skin=",
            uint2str(_tokenSkins[tokenId]),
            "&smoke=",
            uint2str(_tokenSmokes[tokenId]),
            "&swirl=",
            uint2str(_tokenSwirls[tokenId])
        );
        return string(abi.encodePacked('data:application/json;base64,',
            Base64.encode(bytes(
                    abi.encodePacked(
                        '{"name": "SPX-', uint2str(tokenId), '", "description": "', _description, '",',
                        '"image": "', _ipfsGateway, _tokenImages[tokenId], '", ',
                        '"image_url": "', _ipfsGateway, _tokenImages[tokenId], '", ',
                        '"animation_url": "', url, '"'
                        '}')))));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC721CreatorCore).interfaceId || 
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId || 
            AdminControl.supportsInterface(interfaceId) || 
            super.supportsInterface(interfaceId);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
