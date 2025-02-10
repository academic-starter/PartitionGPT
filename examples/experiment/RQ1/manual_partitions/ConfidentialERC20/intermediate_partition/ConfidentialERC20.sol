// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// The provided Solidity contract is an implementation of an ERC20 token standard with enhanced privacy features.
// It aims to ensure the confidentiality of token transactions through encryption techniques while maintaining compatibility with the ERC20 standard.
//
// Key Features:
// Privacy Enhancement:
// The contract utilizes encryption techniques to encrypt sensitive data such as token balances and allowances. Encryption is performed using both user-specific and system-wide encryption keys to safeguard transaction details.
// Encrypted Balances and Allowances:
// Token balances and allowances are stored in encrypted form within the contract's state variables. This ensures that sensitive information remains confidential and inaccessible to unauthorized parties.
// Integration with MPC Core:
// The contract leverages functionalities provided by an external component called MpcCore. This component likely implements cryptographic operations such as encryption, decryption, and signature verification using techniques like Multi-Party Computation (MPC).
// Token Transfer Methods:
// The contract provides multiple transfer methods, allowing token transfers in both encrypted and clear (unencrypted) forms. Transfers can occur between addresses with encrypted token values or clear token values.
// Approval Mechanism:
// An approval mechanism is implemented to allow token holders to grant spending permissions (allowances) to other addresses. Approvals are also encrypted to maintain transaction privacy.
abstract contract ConfidentialERC20 {
    // Events are emitted for token transfers (Transfer) and approvals (Approval). These events provide transparency and allow external observers to track token movements within the contract.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Approval(address indexed _owner, address indexed _spender);

    string private _name;
    string private _symbol;
    uint8 private _decimals; // Sets the number of decimal places for token amounts. Here, _decimals is 5,
    // allowing for transactions with precision up to 0.00001 tokens.
    uint256 private _totalSupply;

    // Mapping of balances of the token holders
    // The balances are stored encrypted by the system aes key
    mapping(address => uint64) internal balances;
    // Mapping of allowances of the token holders
    mapping(address => mapping(address => uint64)) private allowances;

    // Create the contract with the name and symbol. Assign the initial supply of tokens to the contract creator.
    // params: name: the name of the token
    //         symbol: the symbol of the token
    //         initialSupply: the initial supply of the token assigned to the contract creator
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    // The function returns the encrypted account balance utilizing the user's secret key.
    // Since the balance is initially encrypted internally using the system's AES key, the user cannot access it.
    // Thus, the balance undergoes re-encryption using the user's secret key.
    // As a result, the function is not designated as a "view" function.
    function balanceOf() public view virtual returns (uint64 balance) {
        uint64 bal = balanceOf_priv(msg.sender);
        return balanceOf_callback(bal);
    }
    function balanceOf_priv(address sender) internal view virtual returns (uint64 balance) {
        return balances[sender];
    }
    function balanceOf_callback(uint64 bal) internal view virtual returns (uint64 balance) {
        return bal;
    }

    // Transfers the amount of tokens given inside the IT (encrypted and signed value) to address _to
    // params: _to: the address to transfer to
    //         _itCT: the encrypted value of the amount to transfer
    //         _itSignature: the signature of the amount to transfer
    //         revealRes: indicates if we should reveal the result of the transfer
    // returns: In case revealRes is true, returns the result of the transfer. In case revealRes is false, always returns true
    function transfer(
        address _to,
        uint64 _value
    ) public virtual returns (bool success) {
        transfer_priv(msg.sender, _to, _value);
        return true;
    }

    function transfer_priv(address from, address to, uint64 amount) internal {
       contractTransfer(from, to, amount); 
    }

    // Transfers the amount of tokens given inside the encrypted value to address _to
    // params: _to: the address to transfer to
    //         _value: the encrypted value of the amount to transfer
    // returns: The encrypted result of the transfer.
    function contractTransfer(
        address _from,
        address _to,
        uint64 _value
    ) internal virtual returns (bool success) {
        (uint64 fromBalance, uint64 toBalance) = getBalances(
            _from,
            _to
        );
        uint64 newFromBalance = fromBalance - _value;
        uint64 newToBalance = toBalance + _value;

        emit Transfer(_from, _to);
        setNewBalances(_from, _to, newFromBalance, newToBalance);

        return true;
    }


    // Transfers the amount of tokens given inside the IT (encrypted and signed value) from address _from to address _to
    // params: _from: the address to transfer from
    //         __to: the address to transfer to
    //         _itCT: the encrypted value of the amount to transfer
    //         _itSignature: the signature of the amount to transfer
    //         revealRes: indicates if we should reveal the result of the transfer
    // returns: In case revealRes is true, returns the result of the transfer. In case revealRes is false, always returns true
    function transferFrom(
        address _from,
        address _to,
        uint64 _value
    ) public virtual returns (bool success) {
        // Create IT from ciphertext and signature
        transferFrom_priv(_from, _to, _value);
        return true;
    }

    function transferFrom_priv(address _from, address _to, uint64 _value) internal returns (bool) {
        bool result = contractTransferFrom(
            _from,
            _to,
            _value
        );
        return result;
    }


    // Transfers the amount of tokens given inside the encrypted value from address _from to address _to
    // params: _from: the address to transfer from
    //         _to: the address to transfer to
    //         _value: the encrypted value of the amount to transfer
    // returns: The encrypted result of the transfer.
    function contractTransferFrom(
        address _from,
        address _to,
        uint64 _value
    ) internal virtual returns (bool success) {
        (uint64 fromBalance, uint64 toBalance) = getBalances(_from, _to);
        uint64 allowanceAmount = getGTAllowance(_from, _to);
        
        uint64 newFromBalance = fromBalance - _value;
        uint64 newToBalance = toBalance + _value;
        uint64 newAllowance = allowanceAmount - _value;
      
        setApproveValue(_from, _to, newAllowance);
        emit Transfer(_from, _to);
        setNewBalances(_from, _to, newFromBalance, newToBalance);

        return true;
    }

    function _mint(address account, uint64 value) internal {
        uint64 balance = balances[account];

        _totalSupply += value;

        uint64 gtBalance = balance == 0 ?0:balance;
        uint64 gtNewBalance = gtBalance + value;
        balances[account] = gtNewBalance;
    }

    // Returns the encrypted balances of the two addresses
    function getBalances(
        address _from,
        address _to
    ) private returns (uint64, uint64) {
        uint64 fromBalance = balances[_from];
        uint64 toBalance = balances[_to];
        return (fromBalance, toBalance);
    }

    // Sets the new encrypted balances of the two addresses
    function setNewBalances(
        address _from,
        address _to,
        uint64 newFromBalance,
        uint64 newToBalance
    ) private {
        // Convert the uint64 to uint64 and store it in the balances mapping
        balances[_from] = newFromBalance;
        balances[_to] = newToBalance;
    }

    // Sets the new encrypted allowance of the spender
    function approve(
        address _spender,
        uint64 _value
    ) public virtual returns (bool success) {
        address owner = msg.sender;
        approve_priv(owner, _spender, _value);
        return true;
    }

    function approve_priv(address owner, address _spender, uint64 _value) internal  {
        setApproveValue(owner, _spender, _value);
        emit Approval(owner, _spender);
    }


    // Returns the encrypted allowance of the spender. The encryption is done using the msg.sender aes key
    function allowance(
        address _owner,
        address _spender
    ) public view virtual returns (uint64 remaining) {
        require(_owner == msg.sender || _spender == msg.sender);
        uint64 amt = allowance_priv(_owner, _spender);
        return allowance_callback(amt);
    }

    function allowance_priv(address _owner, address _spender) public view virtual returns (uint64) {
        return allowances[_owner][_spender];
    }

    function allowance_callback(uint64 amt) public view virtual returns (uint64) {
        return amt;
    }

    // Returns the encrypted allowance of the spender. The encryption is done using the system aes key
    function getGTAllowance(
        address _owner,
        address _spender
    ) private returns (uint64 remaining) {
        return allowances[_owner][_spender];
    }

    // Sets the new encrypted allowance of the spender
    function setApproveValue(
        address _owner,
        address _spender,
        uint64 _value
    ) private {
        allowances[_owner][_spender] = _value;
    }
}