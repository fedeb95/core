const RoyaltyLedger = artifacts.require("RoyaltyLedger");
const Market = artifacts.require("Market");

module.exports = async function (deployer) {
  await deployer.deploy(RoyaltyLedger);
  const ledgerContract = await RoyaltyLedger.deployed();
  await deployer.deploy(Market, ledgerContract.address);
};
