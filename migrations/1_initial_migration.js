const RoylatyLedger = artifacts.require("RoyaltyLedger");
const Market = artifacts.require("Market");

module.exports = function (deployer) {
  const ledgerContract = await deployer.deploy(RoyaltyLedger);
  deployer.deploy(Market, ledgerContract.address);
};
