const Inscribe = artifacts.require("Inscribe");
const InscribeMetaData = artifacts.require("InscribeMetaData");
const InscribeNFTFactory = artifacts.require("ERC721Mock");
const truffleAssert = require('truffle-assertions');
const ethSigUtil = require('eth-sig-util');
const Wallet = require('ethereumjs-wallet').default;

contract('Inscribe', (accounts) => {

  let inscribe;
  let nftFactory;
  let inscribeMetaData;

  const privateKey = "208065a247edbe5df4d86fbdc0171303f23a76961be9f6013850dd2bdc759bbb"

  beforeEach(async () => {
    inscribe = await Inscribe.new();
    nftFactory = await InscribeNFTFactory.new("Inscribe", "ISC");
    inscribeMetaData = await InscribeMetaData.at(inscribe.address);
  });

  it('should inscribe on an NFT already owned by owner', async () => {
    this.wallet = Wallet.fromPrivateKey(Buffer.from(privateKey, 'hex'));
    await inscribeMetaData.addBaseURI("https://inscribe.so/");

    this.types = {
      EIP712Domain: [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
      ],
      AddInscription: [
        { name: "nftAddress", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "contentHash", type: "bytes32" },
        { name: "nonce", type: "uint256" },
      ],
    };
    this.domain = {
      name: "Inscribe",
      version: "1",
      chainId: await web3.eth.getChainId(),
      verifyingContract: inscribe.address,
    };
    this.req = {
      nftAddress: nftFactory.address,
      tokenId: 1,
      contentHash: "0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45",
      nonce: 1
    };
    console.log(this.req)

    this.sign = ethSigUtil.signTypedMessage(
      this.wallet.getPrivateKey(),
      {
        data: {
          types: this.types,
          domain: this.domain,
          primaryType: 'AddInscription',
          message: this.req,
        },
      },
    );
    
    await nftFactory.mint(this.wallet.getAddressString(), 1);

    await inscribe.addInscriptionWithBaseUriId(nftFactory.address, 
                                              1, 
                                              this.wallet.getAddressString(), 
                                              "0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45", 
                                              1, 
                                              1,
                                              this.sign);
    let inscriber = await inscribe.getInscriber(1)

    assert.equal(web3.utils.toChecksumAddress(inscriber), this.wallet.getChecksumAddressString());
  });

  it('should remove an inscription on an NFT', async () => {

  });

  it('should prohibit users from removing an inscription on an NFT they do not own', async () => {

  });

  it('should prohibit users from inscribing onto an nft they do not own', async () => {

  });

  it('should get the correct inscription URI from an operator', async () => {
    this.wallet = Wallet.fromPrivateKey(Buffer.from(privateKey, 'hex'));

    this.types = {
      EIP712Domain: [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
      ],
      AddInscription: [
        { name: "nftAddress", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "contentHash", type: "bytes32" },
        { name: "nonce", type: "uint256" },
      ],
    };
    this.domain = {
      name: "Inscribe",
      version: "1",
      chainId: await web3.eth.getChainId(),
      verifyingContract: inscribe.address,
    };
    this.req = {
      nftAddress: nftFactory.address,
      tokenId: 1,
      contentHash: "0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45",
      nonce: 1
    };
    console.log(this.req)

    this.sign = ethSigUtil.signTypedMessage(
      this.wallet.getPrivateKey(),
      {
        data: {
          types: this.types,
          domain: this.domain,
          primaryType: 'AddInscription',
          message: this.req,
        },
      },
    );
    
    await nftFactory.mint(this.wallet.getAddressString(), 1);

    await inscribeMetaData.addBaseURI("https://inscribe.so/");
    let uri = await inscribeMetaData.getBaseURI(1);
    console.log(uri);
    await inscribe.addInscriptionWithBaseUriId(nftFactory.address, 
                                              1, 
                                              this.wallet.getAddressString(), 
                                              "0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45", 
                                              1, 
                                              1,
                                              this.sign);
    assert.equal(await inscribe.getInscriptionURI(1), "https://inscribe.so/1");
  });

});
