const Inscribe = artifacts.require("Inscribe");
const InscribeNFTFactory = artifacts.require("ERC721Mock");
const truffleAssert = require('truffle-assertions');
const ethSigUtil = require('eth-sig-util');

contract('Inscribe', (accounts) => {

  let inscribe;
  let nftFactory;

  beforeEach(async () => {
    inscribe = await Inscribe.new();
    nftFactory = await InscribeNFTFactory.new("Inscribe", "ISC");
  });

  it('should inscribe on an NFT already owned by owner', async () => {
    await nftFactory.mint(accounts[0], 1);

    await inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json");
    let inscription = await inscribe.getInscription(1)
    assert.equal(inscription[0], nftFactory.address);
  });

  it('should remove an inscription on an NFT', async () => {
    await nftFactory.mint(accounts[0], 1);

    await inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json");

    await inscribe.removeInscription(1);
    
    await truffleAssert.reverts(
      inscribe.getInscription(1),
      "Inscription does not exist"
    );
  });

  it('should prohibit users from removing an inscription on an NFT they do not own', async () => {
    await nftFactory.mint(accounts[0], 1);

    await inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json");
    
    await truffleAssert.reverts(
      inscribe.removeInscription(1, {from: accounts[1]}),
      "Caller does not own inscription or is not approved."
    );
  });

  it('should prohibit users from inscribing onto an nft they do not own', async () => {
    await nftFactory.mint(accounts[0], 1);

    await truffleAssert.reverts(
      inscribe.addInscription(nftFactory.address, 1, 1, "https://optionalUri.com/1.json", {from: accounts[1]}),
      "Caller does not own inscription or is not approved."
    );
  });
});
