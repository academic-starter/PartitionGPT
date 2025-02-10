// SPDX-License-Identifier: UNLICENSED
// https://github.com/omurovec/fhe-darkpools/blob/master/src/DarkPool.sol
pragma solidity ^0.8.13;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract DarkPool{
    // Buy or Sell base token for quote token
    enum OrderType {
        Buy,
        Sell
    }

    struct Order {
        uint32 amount; // Amount of base to buy/sell
        uint32 price; // Price of base asset to buy/sell at (e.g 2000 USDC/ETH)
    }

    // [ base, quote ] (e.g. [ ETH, USDC ])
    IERC20[] public tokens;
    uint8 public constant BASE_INDEX = 0;
    uint8 public constant QUOTE_INDEX = 1;

    // user => token => balance
    mapping(address => mapping(uint8 => uint32)) public balances;
    // user => buy/sell => sellorder
    mapping(address => mapping(OrderType => Order)) public orders;

    event OrderCreated(address indexed user, uint8 orderType, uint32 amount, uint32 price);

    event OrderUpdated(address indexed user, uint8 orderType, uint32 amount, uint32 price);

    event OrderDeleted(address indexed user, uint8 orderType);

    constructor(IERC20[] memory _tokens) {
        tokens = _tokens;
    }

    function deposit(uint8 tokenId, uint32 amount) public {
        tokens[tokenId].transferFrom(msg.sender, address(this), amount);

        deposit_priv(msg.sender, tokenId, amount);
    }

    function deposit_priv(address sender, uint8 tokenId, uint32 amount) internal {
        uint32 prevBalance = balances[sender][tokenId];
        balances[sender][tokenId] = prevBalance + amount;
    }


    function _createOrder(OrderType orderType, uint32 amount, uint32 price) internal {
        // ensure there is no existing order
        require(orders[msg.sender][orderType].amount != 0);

        if (orderType == OrderType.Buy) {
            // ensure amount * price <= quote balance
            require(amount * price <= balances[msg.sender][QUOTE_INDEX]);
        } else {
            // ensure amount <= base balance
            require(amount <= balances[msg.sender][BASE_INDEX]);
        }
        // create sell order
        orders[msg.sender][orderType] = Order(amount, price);
        emit OrderCreated(msg.sender, uint8(orderType), amount, price);
    }

    function createOrder(OrderType orderType, uint32 amount, uint32 price) public {
        createOrder_priv(orderType, amount, price);
    }

    function createOrder_priv(OrderType orderType, uint32 amount, uint32 price) public {
        _createOrder(orderType, amount, price);
    }


    function fillOrder(address buyer, address seller) public {
        fillOrder_priv(buyer, seller);
    }

    function fillOrder_priv(address buyer, address seller) internal {
        Order memory buyOrder = orders[buyer][OrderType.Buy];
        Order memory sellOrder = orders[seller][OrderType.Sell];

        
        // ensure neither order is empty
        require(buyOrder.amount != 0);
        require(sellOrder.amount != 0);

        // ensure prices are the same
        require(buyOrder.price == sellOrder.price);

        // Check which order is larger
        bool buyOrderLarger = sellOrder.amount <= buyOrder.amount;

        // Get the amount being traded
        uint32 baseAmount = buyOrderLarger? sellOrder.amount : buyOrder.amount;
        uint32 quoteAmount = baseAmount * sellOrder.price;

        /* Adjust order amounts */
        // Subtract amount filled from each order
        orders[buyer][OrderType.Buy].amount = buyOrder.amount - baseAmount;
        orders[seller][OrderType.Sell].amount = sellOrder.amount - baseAmount;

        // Adjust base balances
        balances[seller][BASE_INDEX] = balances[seller][BASE_INDEX] - baseAmount;
        balances[buyer][BASE_INDEX] = balances[buyer][BASE_INDEX] + baseAmount;

        // Adjust quote balances
        balances[seller][QUOTE_INDEX] = balances[seller][QUOTE_INDEX] + quoteAmount;
        balances[buyer][QUOTE_INDEX] = balances[buyer][QUOTE_INDEX] - quoteAmount;

        // Remove price of filled orders
        orders[buyer][OrderType.Buy].price = buyOrder.amount <= 0? 0: buyOrder.price;
        orders[seller][OrderType.Sell].price = sellOrder.amount <= 0? 0: sellOrder.price;

        emit OrderUpdated(
            buyer, uint8(OrderType.Buy), orders[buyer][OrderType.Buy].amount, orders[buyer][OrderType.Buy].price
        );
        emit OrderUpdated(
            seller, uint8(OrderType.Sell), orders[seller][OrderType.Sell].amount, orders[seller][OrderType.Sell].price
        );
    }

    // Since we don't have control flow with TFHE,
    // we require users or market makers to delete their
    // orders once they have been filled
    function deleteOrder(address user, OrderType orderType) public {
        deleteOrder_priv(user, orderType);
    }

    function deleteOrder_priv(address user, OrderType orderType) public {
        Order memory order = orders[user][orderType];

        // ensure order exists
        // require(TFHE.isInitialized(order.amount), "Order does not exist");

        // ensure order is empty
        require(order.amount == 0);

        // delete order
        delete orders[user][orderType];

        emit OrderDeleted(user, uint8(orderType));
    }


    function retractOrder(OrderType orderType) public {
        retractOrder_priv(msg.sender, orderType);
    }

    function retractOrder_priv(address user, OrderType orderType) internal {
        delete orders[user][orderType];
        emit OrderDeleted(user, uint8(orderType));
    }

    function getBalance(uint8 tokenId) public view returns (uint32) {
        uint32 balance = getBalance_priv(msg.sender, tokenId);
        return getBalance_callback(balance);
    }

    function getBalance_priv(address user, uint8 tokenId) public view returns (uint32) {
        return balances[user][tokenId];
    }
    function getBalance_callback(uint32 balance) internal pure returns (uint32) {
        return balance;
    }

    function withdraw(uint8 tokenId, uint32 amount) public {
        withdraw_priv(msg.sender, tokenId, amount);
    }

    function withdraw_priv(address user, uint8 tokenId, uint32 amount) internal {
        if (tokenId == BASE_INDEX) {
            // ensure the user doesn't have an open sell order
              require(
                orders[user][OrderType.Sell].amount == 0,
                "Close sell order before withdrawing base"
            );
        } else {
            // ensure the user doesn't have an open buy order
            require(
                orders[user][OrderType.Buy].amount == 0,
                "Close buy order before withdrawing quote"
            );
        }

        // ensure user has enough balance
        require(balances[user][tokenId] >= amount);
        // transfer tokens
        tokens[tokenId].transfer(user, amount);
        // update balance
        balances[user][tokenId] = balances[user][tokenId] - amount;
    }
}