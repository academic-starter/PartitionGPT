const common = require('./common.js');
const AUTH_DIR = __dirname + '/../../cloak-tee/build/workspace/sandbox_common';
const COMPILE_DIR = './contracts'
const fs = require('fs');
const path = require('path');
const { c } = require('tar');
const Web3 = require('web3');
const web3 = new Web3('http://localhost:8545');
const ws3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545')); 
const express = require('express');
const app = express();
const bodyParser = require('body-parser');

app.use(bodyParser.json());


let listenerConfig = null;

let publicContract, privateContract;


async function parseLogs(receipt, config) {

    const abi = config.privateAbi;
    
    //console.log('Parsing logs...');
    const logs = receipt.logs;
  
    // 遍历所有日志
    logs.forEach((log) => {
      // 找到事件对应的 ABI 描述符
      const eventAbi = abi.find((item) => item.type === 'event' && log.topics[0] === web3.eth.abi.encodeEventSignature(item));
  
      if (eventAbi) {
        console.log('Event Name:', eventAbi.name);
        // 解析日志
        const decodedLog = web3.eth.abi.decodeLog(eventAbi.inputs, log.data, log.topics.slice(1));
        console.log('Decoded Log:', decodedLog);
        const eventConfig = config.events.find(e => e.eventName === eventAbi.name);//这里的事件名称和公共链上的事件名称一致
        if (eventConfig) {
            if (eventConfig.callback && eventConfig.callback.contract === "public") {
                callContractMethod(web3, config.publicAbi, config.publicContractAddress, eventConfig.callback.method, eventConfig.callback.params.map(param => decodedLog[param]), config.privateKey);
            }
        }
      }
    });
  }
  
  async function callContractMethod(web3Instance, abi, contractAddress, methodName, params, privateKey) {
    try {
        const contract = new web3Instance.eth.Contract(abi, contractAddress);
        const tx = contract.methods[methodName](...params).encodeABI();


        const transactionObject = {
            to: publicContract.options.address,
            data: tx,
            gas: 200000,
        };
        web3.eth.accounts.signTransaction(transactionObject, privateKey)
            .then(signedTx => {
                web3.eth.sendSignedTransaction(signedTx.rawTransaction)
                    .on('receipt', (receipt) => {
                        console.log('bid_callback transaction receipt on public chain:', receipt);
                    })
                    .on('error', (error) => {
                        console.error('Failed to call bid_callback on public chain:', error);
                    });
            })
            .catch(error => {
                console.error('Failed to sign transaction:', error);
            });
    } catch (error) {
        console.error('Failed to call bid_callback on public chain:', error);
    }
}


async function transaction(config) {

    
    const [cloak_web3, eth_web3] =  await common.register_service(AUTH_DIR);
    publicContract = new ws3.eth.Contract(config.publicAbi, config.publicContractAddress);
    privateContract = new cloak_web3.eth.Contract(config.privateAbi, config.privateContractAddress);

    const POLLING_INTERVAL = 3000; // 每次轮询间隔，单位为毫秒

    publicContract.events.allEvents({
        fromBlock: 0
    })
    .on('data', async (event) => {
        console.log('New event:', event);
    
        // 检查事件的名称是否是 BidMessagePassing
        const eventConfig = config.events.find(e => e.eventName === event.event);
        if (eventConfig) {
            // 事件名称匹配，继续执行操作，例如调用私有合约上的方法
            console.log(event.event,' event detected');
            try {

                // 根据配置调用私有合约的方法
                const methodConfig = eventConfig.privateMethod;
                const params = methodConfig.params.map(param => event.returnValues[param]);

                // 假设你有私有合约的实例 privateContract//
                const setDTx = privateContract.methods[methodConfig.name](...params).encodeABI();//修该参数

                const tx = {
                    to: privateContract._address,
                    data: setDTx,
                    gas: 200000,
                    gasPrice: cloak_web3.utils.toWei('20', 'gwei'),
                };

                let hex = await cloak_web3.eth.accounts.signTransaction(tx, config.privateKey);

                cloak_web3.eth.sendSignedTransaction(hex.rawTransaction)
            .on('transactionHash', (hash) => {
                console.log(`Transaction hash: ${hash}`);

            // 使用 setInterval 代替轮询次数限制
                    const intervalId = setInterval(async () => {
                        try {
                            const receipt = await cloak_web3.eth.getTransactionReceipt(hash);
                            if (receipt) {
                                console.log('Transaction receipt:', receipt);
                                parseLogs(receipt, config);
                                clearInterval(intervalId);
                            }
                        } catch (error) {
                            console.error('Error polling transaction receipt:', error);
                        }
                    }, POLLING_INTERVAL);
        })
        .on('error', (error) => {
            console.error('Failed to send private contract transaction:', error);
        });

            } catch (error) {
                console.error('Failed to call private contract:', error);
            }
        }
    })
    .on('error', console.error);



}


// 接收客户端请求并启动监听
app.post('/start-listening', async (req, res) => {
    try {
        listenerConfig = req.body;
        await transaction(listenerConfig);
        res.status(200).send('Listener started successfully.');
    } catch (error) {
        console.error('Failed to start listener:', error);
        res.status(500).send('Failed to start listener.');
    }
});

// 启动服务器
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});