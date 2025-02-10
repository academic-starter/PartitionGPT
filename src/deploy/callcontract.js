const common = require('./common.js');
const AUTH_DIR = __dirname + '/../../cloak-tee/build/workspace/sandbox_common';
const COMPILE_DIR = './contracts'
const fs = require('fs');
const path = require('path');
const Web3 = require('web3');


const contractPath = path.resolve(__dirname, 'contracts', 'MyContract2.json');
const contractJSON = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

const blindAuction_pri_path = path.resolve(__dirname, 'contracts', 'BlindAuction_pri.json');
const blindAuction_pri = JSON.parse(fs.readFileSync(blindAuction_pri_path, 'utf8'));

const blindAuction_pub_path = path.resolve(__dirname, 'contracts', 'BlindAuction_pub.json');
const blindAuction_pub = JSON.parse(fs.readFileSync(blindAuction_pub_path, 'utf8'));

async function transaction() {

    const [cloak_web3, eth_web3] = await common.register_service(AUTH_DIR)
    const cloakService = await common.getCloakService(eth_web3, cloak_web3.cloakInfo.cloak_service, __dirname + '/../../service-contract/build/contracts/CloakService.json');
    
    const accounts = await common.generateAccounts(eth_web3, cloakService)

    const contract = new eth_web3.eth.Contract(blindAuction_pub.abi, '0x3047392360B3e691C8c5Fe4DAFa1A81BF723B6B9');


    const setDTx = contract.methods.bid(1000).encodeABI();

    const tx = {
        to: contract._address,
        data: setDTx,
        gas: 200000,
        gasPrice: eth_web3.utils.toWei('20', 'gwei'),
    };


    let hex = await eth_web3.eth.accounts.signTransaction(tx, '0x9c85933a52d305f6636a2dc8e39c1e0e31dab60ebf98a761021fbc38559fa42c');
    let receipt = await eth_web3.eth.sendSignedTransaction(hex.rawTransaction);
    console.log("----------------------------",receipt);

}

transaction().catch(console.error);