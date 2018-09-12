const KeyHolderLibrary = artifacts.require("./KeyHolderLibrary.sol");
const ClaimHolderLibrary = artifacts.require("./ClaimHolderLibrary.sol");
const CommonwealthIdentity = artifacts.require("./CommonwealthIdentity.sol");

module.exports = function(deployer) {
  deployer.deploy(KeyHolderLibrary);  
  deployer.link(KeyHolderLibrary, ClaimHolderLibrary);
  deployer.deploy(ClaimHolderLibrary);
  
  deployer.link(KeyHolderLibrary, CommonwealthIdentity);
  deployer.link(ClaimHolderLibrary, CommonwealthIdentity);

  deployer.deploy(CommonwealthIdentity);
};
