const common = require('./common.js');
const AUTH_DIR = __dirname + '/../../cloak-tee/build/workspace/sandbox_common';
const COMPILE_DIR = './contracts'
const fs = require('fs');
const path = require('path');
const Web3 = require('web3');
const axios = require('axios');



async function deployAndStartListening() {
    const [cloak_web3, eth_web3] = await common.register_service(AUTH_DIR)
    const cloakService = await common.getCloakService(eth_web3, cloak_web3.cloakInfo.cloak_service, __dirname + '/../../service-contract/build/contracts/CloakService.json');
    const accounts = await common.generateAccounts(eth_web3, cloakService)

    const blindAuction_pri_path = path.resolve(__dirname, 'contracts', 'BlindAuction_pri.json');
    const blindAuction_pri = JSON.parse(fs.readFileSync(blindAuction_pri_path, 'utf8'));

    const blindAuction_pub_path = path.resolve(__dirname, 'contracts', 'BlindAuction_pub.json');
    const blindAuction_pub = JSON.parse(fs.readFileSync(blindAuction_pub_path, 'utf8'));

    const beneficiaryAddress = accounts[1].address; // 受益人地址
    const biddingTime = 36000; // 1小时的竞标时间
    const isStoppable = true; 

    const publicContract = await common.deployPublicContract(eth_web3,cloakService, accounts[0],blindAuction_pub,[beneficiaryAddress, biddingTime, isStoppable]);
    
    //console.log("----------------------accounts[0]",accounts[0]);//
    


    const privateContract = await common.deployPublicContract(cloak_web3,cloakService, accounts[0],blindAuction_pri,[beneficiaryAddress, biddingTime, isStoppable]);

    //console.log("----------------------accounts[1]",accounts[1])
    //console.log("----------------------pri",publicContract._address);
    //console.log("----------------------pubcon",publicContract._address);//


    // 将部署信息发送到监听模块
    const listenerConfig = {
        publicContractAddress: publicContract._address,
        privateContractAddress: privateContract._address,
        publicAbi: blindAuction_pub.abi,
        privateAbi: blindAuction_pri.abi,
        privateKey: accounts[0].privateKey,
        events: [
            {
                eventName: "BidMessagePassing",
                privateMethod: {
                    name: "bid",
                    params: ["to", "value"] // 参数从事件的 returnValues 获取
                },
                callback: {
                    contract: "public", // 指定是哪个合约，public 或 private
                    method: "bid_callback",
                    params: ["increment"] // 参数从私有合约事件的 returnValues 获取
                }
            }
        ]
    };

    try {
        await axios.post('http://localhost:3000/start-listening', listenerConfig);
        console.log('Listener started successfully.');
    } catch (error) {
        console.error('Failed to start listener:', error);
    }
}

deployAndStartListening().catch(console.error);