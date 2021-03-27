const Inscribe = artifacts.require("Inscribe");
const ERC721Mock = artifacts.require("ERC721Mock");

module.exports = function(deployer) {
  deployer.deploy(Inscribe);
  deployer.deploy(ERC721Mock, "Inscribe", "ISC");
};
