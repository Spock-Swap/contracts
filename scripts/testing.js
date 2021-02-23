const hre = require('hardhat')
const { Contract, utils, providers, constants, BigNumber } = require("ethers")

// const BDTAddress = "0xdEfAa167164cb088C3A194cf44AeEdFA36b9736c";
// const BDTLPAddress = "0x9c2aB38Bb34Fa7219Ff586338dC6848cb928Cdc2";
const OwnerAddress = '0xcE329eB69fdc71D43A0865EbF3d72c3a11A752bF' //
const TestingAddress = '0xF739D434F243E56e695aD937ABF70a5C2a0a6AC9'
const TestingAddress2 = '0x6C397b0b585f78D5D981351ab209d02E6559182f'

async function main() {
  await hre.run('compile')

  const RewardToken = await hre.ethers.getContractFactory('RewardToken')
  const rewardToken = await RewardToken.deploy('RewardToken', 'STONK')

  let a = await rewardToken.deployed()
  console.log(a, 'a')

  const StockToken = await hre.ethers.getContractFactory('StockToken')
  const stockToken = await StockToken.deploy('StockToken', 'wGME')

  let b = await stockToken.deployed()
  console.log(b, 'b')

  const WStock = await hre.ethers.getContractFactory('WStock2')
  const wStock = await WStock.deploy(
    rewardToken.address,
    OwnerAddress,
    TestingAddress,
    10,
    5,
    150,
    BigNumber.from("1000000000000000000"),
  )
  let c = await wStock.deployed()
  console.log(c, 'c')

  let d = await wStock.addStock(utils.formatBytes32String("GME"), stockToken.address)
  console.log(d, 'd');

  let e = await rewardToken.addMinter(OwnerAddress)
  console.log(e, 'e');
  
  let f = await rewardToken.addMinter(wStock.address)
  console.log(f, 'f')
  let g = await stockToken.addMinter(wStock.address)
  console.log(g, 'g')
  // let h = await rewardToken.approve(wStock.address, constants.MaxUint256)
  // console.log(h, 'h')
  let i = await stockToken.approve(wStock.address, constants.MaxUint256)
  console.log(i, 'i')

  // console.clear();
  console.log(`const RewardTokenAddress = "${rewardToken.address}";`)
  console.log(`const StockTokenAddress = "${stockToken.address}";`)
  console.log(`const WStockAddress = "${wStock.address}";`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
