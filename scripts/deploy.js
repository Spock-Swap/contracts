const hre = require("hardhat");

const LootAddress = "0x7bce667ef12023dc5f8577d015a2f09d99a5ef58";
const LootLPAddress = "0x2e8b685abe0af1e05949c22227164dc58c133e68";
const OwnerAddress = '0x5A63C3bC618B34590B1d830156886d71a3f48052' // 

async function main() {
  await hre.run("compile");

  // const NFT = await hre.ethers.getContractFactory("NFTLootboxNFT");
  // const nft = await NFT.deploy();
  // const JunkToken = await hre.ethers.getContractFactory("JunkToken");
  // const junkToken = await JunkToken.deploy("NFTLootBox Junk", "JUNK");
  const DCToken = await hre.ethers.getContractFactory("DuelersCredit");
  const dcToken = await DCToken.deploy("Duelers Credits", "DC");

  await dcToken.deployed();

  const SilverToken = await hre.ethers.getContractFactory("ERC20StakingPool");
  const silverToken = await SilverToken.deploy(LootAddress, dcToken.address, OwnerAddress,  "10000000000000000",  "125000000000000000"); // 10000000000000000,  100000000000000000

  const SilverLPToken = await hre.ethers.getContractFactory("ERC20StakingPool");
  const silverLPToken = await SilverLPToken.deploy(LootLPAddress, dcToken.address, OwnerAddress, "10000000000000000", "375000000000000000"); // 10000000000000000, 300000000000000000

  await silverToken.deployed();
  await silverLPToken.deployed();
  
  await dcToken.addMinter(silverToken.address)
  await dcToken.addMinter(silverLPToken.address)
  await dcToken.setIsWhitelistEnabled(true)

  console.clear();
  console.log(`export const BDTAddress = "${LootAddress}";`);
  console.log(`export const BDTLPAddress = "${LootLPAddress}";`);
  console.log(`export const DCAddress = "${dcToken.address}";`);
  console.log(`export const ERC20StakingAddress = "${silverToken.address}";`);
  console.log(`export const LPStakingAddress = "${silverLPToken.address}";`);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
