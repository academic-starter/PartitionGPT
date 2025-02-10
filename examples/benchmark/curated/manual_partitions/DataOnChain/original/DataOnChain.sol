// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DataOnChain {

    uint64 private clearValue;
    uint64 private ctUserSomeEncryptedValue;
    uint64 private ctUserSomeEncryptedValueEncryptedInput;
    uint64 private ctNetworkSomeEncryptedValue;
    uint64 private ctNetworkSomeEncryptedValueEncryptedInput;
    uint64 private ctUserArithmeticResult;

    constructor () {
        clearValue = 5;
    }

    event UserEncryptedValue(address indexed _from, uint64 ctUserSomeEncryptedValue);

    function getNetworkSomeEncryptedValue() external view returns (uint64 ctSomeEncryptedValue) {
        return ctNetworkSomeEncryptedValue;
    }

    function setNetworkSomeEncryptedValue(uint64 networkEncrypted) external {
        ctNetworkSomeEncryptedValue = networkEncrypted;
    }

    function getNetworkSomeEncryptedValueEncryptedInput() external view returns (uint64 ctSomeEncryptedValue) {
        return ctNetworkSomeEncryptedValueEncryptedInput;
    }

    function getUserSomeEncryptedValue() external view returns (uint64 ctSomeEncryptedValue) {
        return ctUserSomeEncryptedValue;
    }

    function getUserSomeEncryptedValueEncryptedInput() external view returns (uint64 ctSomeEncryptedValue) {
        return ctUserSomeEncryptedValueEncryptedInput;
    }

    function setSomeEncryptedValue(uint64 _value) external {
        ctNetworkSomeEncryptedValue = _value;
    }

    function setSomeEncryptedValueEncryptedInput(uint64 gtNetworkSomeEncryptedValue) external {
        ctNetworkSomeEncryptedValueEncryptedInput = gtNetworkSomeEncryptedValue; // saves it as cipher text (by network aes key)
    }

    function setUserSomeEncryptedValue() external {
        ctUserSomeEncryptedValue = ctNetworkSomeEncryptedValue;
        emit UserEncryptedValue(msg.sender, ctUserSomeEncryptedValue);
    }

    function setUserSomeEncryptedValueEncryptedInput() external {
        ctUserSomeEncryptedValueEncryptedInput = ctNetworkSomeEncryptedValueEncryptedInput;
        emit UserEncryptedValue(msg.sender, ctUserSomeEncryptedValueEncryptedInput);
    }

    function getSomeValue() external view returns (uint64 value) {
        return clearValue;
    }

    function add() external {
        uint64 a = ctNetworkSomeEncryptedValue ;
        uint64 b = ctNetworkSomeEncryptedValueEncryptedInput;
        uint64 result = a + b; 
        ctUserArithmeticResult = result;
    }

    function getUserArithmeticResult() external view returns (uint64 value){
        return ctUserArithmeticResult;
    }
}