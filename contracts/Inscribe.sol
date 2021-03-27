pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

import "./InscribeInterface.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract Inscribe is InscribeInterface {
    using Strings for uint256;
    using ECDSA for bytes32;
        
    // Storage of inscriptions
    mapping (uint256 => Inscription) private _inscriptions;

    // Mapping from an NFT address to a mapping of a token ID to an approved address
    mapping (address => mapping (uint256 => address)) private _inscriptionApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (address => uint256) private _sigNonces;

    uint256 latestInscriptionId;

    //keccak256("AddInscription(address nftAddress,uint256 tokenId,bytes32 contentHash,string inscriptionURI,uint256 nonce)");
    bytes32 public constant ADD_INSCRIPTION_TYPEHASH = 0x99f09b8ad757cd1f8ab590345da90b17fda97f2efe9ce277cb9e1f20fc830466;

    constructor () {
        latestInscriptionId = 1;
    }

    function getSigNonce(address inscriber) external view override returns (uint256) {
        return _sigNonces[inscriber];
    }

    function getNFTLocation(uint256 inscriptionId) external view override returns (address nftAddress, uint256 tokenId) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        NFTLocation memory location = _inscriptions[inscriptionId].location;
        return (location.nftAddress, location.tokenId);
    }

    function getInscriptionData(uint256 inscriptionId) external view override returns (address inscriber, bytes32 contentHash, string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist.");
        InscriptionData memory data = _inscriptions[inscriptionId].data;
        return (data.inscriber, data.contentHash, data.inscriptionURI);
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(uint256 inscriptionId) external view override returns (string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
        Inscription memory inscription = _inscriptions[inscriptionId];
        return inscription.data.inscriptionURI;
    }

    /**
     * @dev See {InscribeApprovalInterface-approve}.
     */
    function approve(address to, address nftAddress, uint256 tokenId) public override {
        address owner = _ownerOf(nftAddress, tokenId);
        require(owner != address(0), "Nonexistent token ID");

        require(to != owner, "Cannot approve the 'to' address as it belongs to the nft owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller is not owner nor approved for all");

        _approve(to, nftAddress, tokenId);
    }

    /**
     * @dev See {InscribeApprovalInterface-getApproved}.
     */
    function getApproved(address nftAddress, uint256 tokenId) public view override returns (address) {
        return _inscriptionApprovals[nftAddress][tokenId];
    }

    /**
     * @dev See {InscribeApprovalInterface-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != msg.sender, "Operator cannot be the same as the caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);    
    }

    /**
     * @dev See {InscribeApprovalInterface-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscription(
        NFTLocation memory location,
        InscriptionData memory data,
        bytes memory sig
    ) external override {
        require(data.inscriber != address(0));
        require(location.nftAddress != address(0));


        Inscription memory inscription = Inscription(location, data);

        bytes32 digest = _generateAddInscriptionHash(inscription);

        // Verifies the signature
        require(_recoverSigner(digest, sig) == inscription.data.inscriber, "Address does not match signature");

        _addInscription(inscription, latestInscriptionId);

        latestInscriptionId++;
    }

        /**
     * @dev See {InscribeInterface-removeInscription}.
     */
    function removeInscription(uint256 inscriptionId) external override {
        Inscription memory inscription = _inscriptions[inscriptionId];
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        // Verifies that the msg.sender has permissions to remove an inscription
        require(_isApprovedOrOwner(msg.sender, inscription.location.nftAddress, inscription.location.tokenId), "Caller does not own inscription or is not approved");

        _removeInscription(inscription, inscriptionId);
    }

    /**
     * @dev Returns whether the `inscriber` is allowed to add or remove an inscription to `tokenId` at `nftAddress`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address inscriber, address nftAddress, uint256 tokenId) private view returns (bool) {
        address owner = _ownerOf(nftAddress, tokenId);
        require(owner != address(0), "Nonexistent token ID");
        return (inscriber == owner || getApproved(nftAddress, tokenId) == inscriber || isApprovedForAll(owner, inscriber));
    }
    
    /**
     * @dev Adds an approval on chain
     */
    function _approve(address to, address nftAddress, uint256 tokenId) internal {
        _inscriptionApprovals[nftAddress][tokenId] = to;
        emit Approval(_ownerOf(nftAddress, tokenId), to, nftAddress, tokenId);
    }
    
    /**
     * @dev Returns the owner of `tokenId` at `nftAddress`
     */
    function _ownerOf(address nftAddress, uint256 tokenId) internal view returns (address){
        IERC721 nftContractInterface = IERC721(nftAddress);
        return nftContractInterface.ownerOf(tokenId);
    }
    
    /**
     * @dev Removes an inscription on-chain after all requirements were met
     */
    function _removeInscription(Inscription memory inscription, uint256 inscriptionId) private {
        // Clear approvals from the previous inscriber
        _approve(address(0), inscription.location.nftAddress, inscription.location.tokenId);
        
        // Remove Inscription
        delete _inscriptions[inscriptionId];
        
        emit InscriptionRemoved(
            inscriptionId, 
            inscription.location.nftAddress, 
            inscription.location.tokenId, 
            inscription.data.inscriber, 
            inscription.data.contentHash,
            inscription.data.inscriptionURI);
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(Inscription memory inscription, uint256 inscriptionId) private {
                        
        _inscriptions[inscriptionId] = inscription;
        emit InscriptionAdded(
            inscriptionId, 
            inscription.location.nftAddress, 
            inscription.location.tokenId, 
            inscription.data.inscriber, 
            inscription.data.contentHash, 
            inscription.data.inscriptionURI);
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(uint256 inscriptionId) private view returns (bool) {
        return _inscriptions[inscriptionId].data.inscriber != address(0);
    }

    /**
     * @dev Generates the EIP712 hash that was signed
     */ 
    function _generateAddInscriptionHash(
        Inscription memory inscription
    ) private view returns (bytes32) {

        bytes32 domainSeparator = _calculateDomainSeparator();

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        ADD_INSCRIPTION_TYPEHASH,
                        inscription.location.nftAddress,
                        inscription.location.tokenId,
                        inscription.data.contentHash,
                        keccak256(bytes(inscription.data.inscriptionURI)),
                        _sigNonces[inscription.data.inscriber]
                    )
                )
            )
        );
    }
    
    function _recoverSigner(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        address signer = ECDSA.recover(_hash, _sig);
        require(signer != address(0));

        return signer;
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() private view returns (bytes32) {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return
            keccak256(
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
}