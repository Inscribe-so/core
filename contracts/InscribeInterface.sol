pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

interface InscribeInterface {

    struct NFTLocation {
        address nftAddress;
        uint256 tokenId;
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

    /**
     * @dev Emitted when an 'owner' gives an 'inscriber' one time approval to add or remove an inscription for
     * the 'tokenId' at 'nftAddress'.
     */
    event Approval(address indexed owner, address indexed inscriber, address indexed nftAddress, uint256 tokenId);
    
    // Emitted when an 'owner' gives or removes an 'operator' approval to add or remove inscriptions to all of their NFTs.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Emitted when an inscription is added to an NFT at 'nftAddress' with 'tokenId'
    event InscriptionAdded(uint256 indexed inscriptionId, 
                            address indexed nftAddress,
                            uint256 tokenId, 
                            address indexed inscriber, 
                            bytes32 contentHash,
                            string inscriptionURI);

    // Emitted when an inscription is removed from an NFT at 'nftAddress' with 'tokenId'
    event InscriptionRemoved(uint256 indexed inscriptionId, 
                            address indexed nftAddress, 
                            uint256 tokenId, 
                            address indexed inscriber, 
                            bytes32 contentHash,
                            string inscriptionURI);

    function getSigNonce(address inscriber) external view returns (uint256);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getNFTLocation(uint256 inscriptionId) external view returns (address nftAddress, uint256 tokenId);

    /**
     * @dev Fetches the inscription location at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */
    function getInscriptionData(uint256 inscriptionId) external view returns (address inscriber, bytes32 contentHash, string memory inscriptionURI);

    /**
     * @dev Gives `inscriber` a one time approval to add or remove an inscription for `tokenId` at `nftAddress`
     */
    function approve(address inscriber, address nftAddress, uint256 tokenId) external;
    
    /**
     * @dev Similar to the ERC721 implementation, Approve or remove `operator` as an operator for the caller.
     * Operators can call {addInscriptionWithSig} or {addInscription} for any nft owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;
    
    /*
    * @dev Returns the `address` approved for the `tokenId` at `nftAddress`
    */
    function getApproved(address nftAddress, uint256 tokenId) external view returns (address);
    
    /**
     * @dev Returns if the `operator` is allowed to inscribe or remove inscriptions for all nfts owned by `owner`
     *
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
     /**
     * @dev Fetches the inscriptionURI at inscriptionID
     * 
     * Requirements:
     *
     * - `inscriptionID` inscriptionID must exist
     * 
     */  
    function getInscriptionURI(uint256 inscriptionId) external view returns (string memory inscriptionURI);
    
    /**
     * @dev Adds an inscription on-chain to the specified nft
     * @param location          The nft contract address
     * @param data              The tokenId of the NFT that is being signed
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
        bytes memory sig
    ) external;
    
    /**
     * @dev Removes inscription on-chain.
     * @param inscriptionId   The ID of the inscription that will be removed
     * 
     * Requirements:
     * 
     * - `inscriptionId` The user calling this method must own the `tokenId` at `nftAddress` of the inscription at `inscriptionId` or has been approved
     */
    function removeInscription(uint256 inscriptionId) external;
}
