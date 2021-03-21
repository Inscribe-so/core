const Inscribe = artifacts.require("Inscribe");

module.exports = function(deployer) {
  deployer.deploy(Inscribe);
};
