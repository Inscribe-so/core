pragma experimental ABIEncoderV2;
pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

interface InscribeInterface {

    struct NFTLocation {
        address nftAddress;
        uint256 tokenId;
        uint256 chainId;
    }

    struct InscriptionData {
        address inscriber;
        bytes32 contentHash;
        string inscriptionURI;
    }

    struct Inscription {
        NFTLocation location;
        InscriptionData data;
    }

    // Emitted when an inscription is added to an NFT at 'nftAddress' with 'tokenId'
    event InscriptionAdded(bytes32 indexed inscriptionId, 
                            address indexed nftAddress,
                            uint256 tokenId, 
                            uint256 chainId, 
                            address indexed inscriber, 
                            bytes32 contentHash,
                            string inscriptionURI);

    // Emitted when a user adjusts their white list permissions
    event WhitelistAdjusted(bytes32 inscriptionId, bool permission);
    
    /**
     * @dev Fetches the permission for if an owner has allowed the inscription at inscriptionId
     * If this value is false, front end must not display the inscription.
     */ 
    function getPermission(bytes32 inscriptionId, address owner) external view returns (bool);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getNFTLocation(bytes32 inscriptionId) external view returns (address nftAddress, uint256 tokenId, uint256 chainId);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getInscriptionData(bytes32 inscriptionId) external view returns (address inscriber, bytes32 contentHash, string memory inscriptionURI);

    
     /**
     * @dev Fetches the inscriptionURI at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */  
    function getInscriptionURI(bytes32 inscriptionId) external view returns (string memory inscriptionURI);
    
    function setPermissions(bytes32[] memory inscriptionIds, bool[] memory permissions) external;

    /**
     * @dev Adds an inscription on-chain to the specified nft
     * @param location          The nft contract address
     * @param data              The tokenId of the NFT that is being signed
     * @param addWhiteList      The inscription meta data ID associated with the inscription
     * @param sig               An optional URI, to not set this, pass the empty string ""
     * 
     * Requirements:
     *
     * - `tokenId` The user calling this method must own the `tokenId` at `nftAddress` or has been approved
     * - `URIId` URIId must exist
     * 
     */
    function addInscription(
        NFTLocation memory location,
        InscriptionData memory data,
        bool addWhiteList,
        bytes memory sig
    ) external;

    
    function getNextInscriptionId(NFTLocation memory location) external view returns (bytes32);
}
