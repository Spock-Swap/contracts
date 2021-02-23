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

  const StockToken1 = await hre.ethers.getContractFactory('StockToken')
  const stockToken1 = await StockToken1.deploy('StockToken', 'wGME')

  let b = await stockToken1.deployed()
  console.log(b, 'b')

  const StockToken2 = await hre.ethers.getContractFactory('StockToken')
  const stockToken2 = await StockToken2.deploy('StockToken', 'wTSLA')

  let c = await stockToken2.deployed()
  console.log(c, 'c')

  const StockToken3 = await hre.ethers.getContractFactory('StockToken')
  const stockToken3 = await StockToken3.deploy('StockToken', 'wAAPL')

  let d = await stockToken3.deployed()
  console.log(d, 'd')

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
  let e = await wStock.deployed()
  console.log(e, 'e')

  let f = await wStock.addStock(utils.formatBytes32String("GME"), stockToken1.address)
  console.log(f, 'f');

  let g = await wStock.addStock(utils.formatBytes32String("TSLA"), stockToken2.address)
  console.log(g, 'g');

  let h = await wStock.addStock(utils.formatBytes32String("AAPL"), stockToken3.address)
  console.log(h, 'h');

  let i = await rewardToken.addMinter(OwnerAddress)
  console.log(i, 'i');
  
  let j = await rewardToken.addMinter(wStock.address)
  console.log(j, 'j')
  let k = await stockToken1.addMinter(wStock.address)
  console.log(k, 'k')
  let l = await stockToken2.addMinter(wStock.address)
  console.log(l, 'l')
  let m = await stockToken3.addMinter(wStock.address)
  console.log(m, 'm')

  let n = await rewardToken.approve(wStock.address, constants.MaxUint256)
  console.log(n, 'n')

  let o = await stockToken1.approve(wStock.address, constants.MaxUint256)
  console.log(o, 'o')
  let p = await stockToken2.approve(wStock.address, constants.MaxUint256)
  console.log(p, 'p')
  let q = await stockToken3.approve(wStock.address, constants.MaxUint256)
  console.log(q, 'q')

  // console.clear();
  console.log(`const RewardTokenAddress = "${rewardToken.address}";`)
  console.log(`const GMETokenAddress = "${stockToken1.address}";`)
  console.log(`const TSLATokenAddress = "${stockToken2.address}";`)
  console.log(`const AAPLTokenAddress = "${stockToken3.address}";`)
  console.log(`const WStockAddress = "${wStock.address}";`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
