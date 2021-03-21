pragma experimental ABIEncoderV2;
pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./InscribeInterface.sol";


contract Inscribe is InscribeInterface {
    using Strings for uint256;
    using ECDSA for bytes32;
        
    mapping (bytes32 => Inscription) private _inscriptions;

    mapping (bytes32 => mapping (address => bool)) private _whiteList;

    // Mapping from a hash of (nftAddress, tokenId, chainId) to a nonce that incrementally goes up
    mapping (bytes32 => uint256) inscriptionNonces;


    bytes32 public DOMAIN_SEPARATOR;
    //keccak256("AddInscription(address nftAddress, uint256 tokenId, uint256 chainId, address inscriber, bytes32 contentHash, string inscriptionURI)");
    bytes32 public constant ADD_INSCRIPTION_TYPEHASH = 0x40627018dea8ab5140a274cea9c0761b60835bc70d6c644f7220c2e5823cd29a;

    constructor () {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Inscribe")),
                keccak256(bytes("1")),
                chainID,
                address(this)
            )
        );
    }

    function getNFTLocation(bytes32 inscriptionId) external view override returns (address nftAddress, uint256 tokenId, uint256 chainId) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        NFTLocation memory location =_inscriptions[inscriptionId].location;
        return (location.nftAddress, location.tokenId, location.chainId);
    }

    function getInscriptionData(bytes32 inscriptionId) external view override returns (address inscriber, bytes32 contentHash, string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        InscriptionData memory data =_inscriptions[inscriptionId].data;
        return (data.inscriber, data.contentHash, data.inscriptionURI);
    }

    function getPermission(bytes32 inscriptionId, address owner) external view override returns (bool) {
        return _whiteList[inscriptionId][owner];
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(bytes32 inscriptionId) external view override returns (string memory inscriptionURI) {
        Inscription memory inscription = _inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
        return inscription.data.inscriptionURI;
    }

    function setPermissions(bytes32[] memory inscriptionIds, bool[] memory permissions) external override {
        require(inscriptionIds.length == permissions.length, "Arrays passed must be of the same size");

        for (uint256 i = 0; i < inscriptionIds.length; i++) {
            _whiteList[inscriptionIds[i]][msg.sender] = permissions[i];
            emit WhitelistAdjusted(inscriptionIds[i], permissions[i]);
        }
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscription(
        NFTLocation memory location,
        InscriptionData memory data,
        bool addWhiteList,
        bytes memory sig
    ) external override {
        require(data.inscriber != address(0));
        require(location.nftAddress != address(0));

        Inscription memory inscription = Inscription(location, data);

        bytes32 inscriptionId = getNextInscriptionId(inscription.location);

        bytes32 digest = _generateAddInscriptionHash(inscription, inscriptionId);

        // Verifies the signature
        require(recoverSigner(digest, sig) == inscription.data.inscriber, "Address does not match signature");

        // Adjust nonce 
        _updateInscriptionNonce(inscription.location);

        // Add whitelist
        if (addWhiteList) {
            _whiteList[inscriptionId];
        }

        _addInscription(inscription, inscriptionId);
    }

    // Deterministic way of fetching the next inscription ID of a given 
    function getNextInscriptionId(NFTLocation memory location) public override view returns (bytes32) {
        bytes32 inscriptionHash = keccak256(abi.encodePacked(location.nftAddress, location.tokenId, location.chainId));

        uint256 inscriptionNonce = inscriptionNonces[inscriptionHash];

        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return keccak256(abi.encodePacked(inscriptionHash, inscriptionNonce, chainID));
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(Inscription memory inscription, bytes32 inscriptionId) private {
                        
        _inscriptions[inscriptionId] = inscription;
        emit InscriptionAdded(
            inscriptionId, 
            inscription.location.nftAddress, 
            inscription.location.tokenId, 
            inscription.location.chainId, 
            inscription.data.inscriber, 
            inscription.data.contentHash, 
            inscription.data.inscriptionURI);
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(bytes32 inscriptionId) private view returns (bool) {
        return _inscriptions[inscriptionId].data.inscriber != address(0);
    }

    function _generateAddInscriptionHash(
        Inscription memory inscription,
        bytes32 inscriptionId
    ) private view returns (bytes32) {

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        ADD_INSCRIPTION_TYPEHASH,
                        inscription.location.nftAddress,
                        inscription.location.tokenId,
                        inscription.location.chainId,
                        inscription.data.contentHash,
                        inscription.data.inscriptionURI,
                        inscriptionId
                    )
                )
            )
        );
    }

    function _updateInscriptionNonce(NFTLocation memory location) internal {
        bytes32 inscriptionHash = keccak256(abi.encodePacked(location.nftAddress, location.tokenId, location.chainId));

        inscriptionNonces[inscriptionHash]++;
    }
    
    function recoverSigner(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        address signer = ECDSA.recover(_hash, _sig);
        require(signer != address(0));

        return signer;
    }
}