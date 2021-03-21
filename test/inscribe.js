const Inscribe = artifacts.require("Inscribe");
const InscribeNFTFactory = artifacts.require("InscribeNFTFactory");
const truffleAssert = require('truffle-assertions');

const { toEthSignedMessageHash, fixSignature } = require('./helpers/sign');

contract('Inscribe', (accounts) => {

  let inscribe;
  let nftFactory;

  beforeEach(async () => {
    inscribe = await Inscribe.new();
    nftFactory = await InscribeNFTFactory.new();
  });

  it('should set baseURIs on constructor', async () => {
    const defaultBaseURI1 = await inscribe.getBaseURI.call(1);
    const defaultBaseURI2 = await inscribe.getBaseURI.call(2);

    assert.equal(defaultBaseURI1, "", "Default baseURI not set for baseUriId 1");
    assert.equal(defaultBaseURI2, "ipfs://", "Default baseURI not set for baseUriId 2");
  });

  it('should inscribe on an NFT already owned by owner', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json");
    let inscription = await inscribe.getInscription(1)
    assert.equal(inscription[0], nftFactory.address);
  });

  it('should remove an inscription on an NFT', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json");

    await inscribe.removeInscription(1);
    
    await truffleAssert.reverts(
      inscribe.getInscription(1),
      "Inscription does not exist"
    );
  });

  it('should prohibit users from removing an inscription on an NFT they do not own', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json");
    
    await truffleAssert.reverts(
      inscribe.removeInscription(1, {from: accounts[1]}),
      "Caller does not own inscription or is not approved."
    );
  });

  it('should prohibit users from inscribing onto an nft they do not own', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await truffleAssert.reverts(
      inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json", {from: accounts[1]}),
      "Caller does not own inscription or is not approved."
    );
  });

  it('should add a base URI', async () => {
    await inscribe.addBaseURI("https://inscribe.so/", false, false);
    let baseUri = await inscribe.getBaseURI(3)
    assert.equal(baseUri, "https://inscribe.so/");
  });

  it('should return a valid URI', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addBaseURI("https://inscribe.so/", false, false);
    let baseUri = await inscribe.getBaseURI(3)
    assert.equal(baseUri, "https://inscribe.so/");

    await inscribe.addInscription(nftFactory.address, 1, 3, "");
    let uri = await inscribe.getInscriptionURI(1);
    assert.equal(uri, "https://inscribe.so/1");
  });

  it('should add an inscription with optional URI', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addBaseURI("https://inscribe.so/", true, false);
    await inscribe.addInscription(nftFactory.address, 1, 3, "optionalURI");
    let uri = await inscribe.getInscriptionURI(1);

    assert.equal(uri, "https://inscribe.so/optionalURI");
  });

  it('should prohibit users from adding an inscription if `supportsOptionalUri` is true and no optionalURI is passed', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addBaseURI("https://inscribe.so/", true, false);
    await truffleAssert.reverts(
      inscribe.addInscription(nftFactory.address, 1, 3, ""),
      "Optional URI not passed."
    );
  });

  it('should prohibit users from adding an inscription if `supportsOptionalUri` is false and an optionalURI is passed', async () => {
    await nftFactory.batchMint(accounts[0], [1]);

    await inscribe.addBaseURI("https://inscribe.so/", false, false);
    await truffleAssert.reverts(
      inscribe.addInscription(nftFactory.address, 1, 3, "optionalURI"),
      "Optional URI must be empty."
    );
  });
});
