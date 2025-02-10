// SPDX-License-Identifier: BSD-3-Clause-Clear
// https://github.com/immortal-tofu/cipherbomb/blob/main/contracts/CipherBomb.sol
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CipherBomb is Ownable {
    uint public constant MIN_PLAYERS = 4;
    uint public constant MAX_PLAYERS = 6;

    enum CardType {
        WIRE,
        BOMB,
        NEUTRAL
    }

    bool public gameRunning;
    bool public gameOpen;
    bool public gameRoleDealNeeded;

    uint8 public numberOfPlayers;
    address[6] public players;

    uint8 public turnIndex;
    uint8 public turnMove;
    bool public turnDealNeeded;
    address public turnCurrentPlayer;

    uint8 public remainingWires;

    uint8[6] wirePositions;
    uint8 bombPosition;

    mapping(address => string) public name;
    mapping(address => bool) roles;
    mapping(address => Cards) cards;

    struct Cards {
        uint8 bomb;
        uint8 wires;
        uint8 neutrals;
        uint8 total;
    }

    event PlayerJoined(address player);
    event PlayerLeft(address player);
    event PlayerKicked(address player);
    event PlayerNameChanged(address player, string name);

    event GameOpen();
    event GameStart();
    event Turn(uint8 index);
    event CardPicked(uint8 cardType);

    event GoodGuysWin();
    event BadGuysWin(string reason);

    event GoodDeal();
    event FalseDeal();

    constructor() Ownable(msg.sender) {
        gameRunning = false;
        open();
    }

    function open() public {
        gameOpen = true;
        gameRunning = false;
        turnIndex = 0;
        turnMove = 0;
        turnDealNeeded = true;
        gameRoleDealNeeded = true;
        delete players;
        numberOfPlayers = 0;
        addPlayer(owner());

        emit GameOpen();
    }

    function start() public onlyGameOpen {
        require(numberOfPlayers >= MIN_PLAYERS, "Not enough player to start");
        bool roleDistributed = giveRoles();
        if (roleDistributed) {
            remainingWires = numberOfPlayers;
            turnCurrentPlayer = players[0];
            gameOpen = false;
            gameRunning = true;
            emit GameStart();
        }
    }

    function join() public onlyGameOpen {
        require(numberOfPlayers < MAX_PLAYERS, "The game has enough players (8)");
        addPlayer(msg.sender);
        emit PlayerJoined(msg.sender);
    }

    function addPlayer(address player) internal onlyNewPlayer(player) {
        players[numberOfPlayers] = player;
        numberOfPlayers++;
    }

    function leave() public onlyGameOpen onlyOwner {
        removePlayer(msg.sender);
        emit PlayerLeft(msg.sender);
    }

    function kick(address player) public onlyGameOpen onlyOwner {
        removePlayer(player);
        emit PlayerKicked(player);
    }

    function removePlayer(address player) internal onlyPlayer(player) {
        bool found = false;
        for (uint i = 0; i < players.length; i += 1) {
            if (players[i] == player) {
                delete players[i];
                players[i] = players[i + 1];
                found = true;
            } else if (found) {
                players[i] = players[i + 1];
            }
        }
        numberOfPlayers--;
    }

    function setName(string calldata playername) public {
        name[msg.sender] = playername;
        emit PlayerNameChanged(msg.sender, playername);
    }

    function getRangeBits(uint8 range) internal pure returns (uint8) {
        uint8 rangeBits = 1;
        if (range > 3) {
            rangeBits = 3;
        } else if (range > 1) {
            rangeBits = 2;
        }
        return rangeBits;
    }
    
    function generateNumber(uint8 random8, uint8 range) internal returns (uint8) {
        // currently do not support random number generation 
        // return TFHE.cmux(TFHE.lt(random8, range), random8, TFHE.sub(random8, range));
        return random8;
    }

    function dealCards(uint8 positionsToGenerate, uint8 range) internal returns (uint8[] memory) {
        require(range < 7);
        uint8[] memory positions = new uint8[](positionsToGenerate);

        // euint32 random32 = TFHE.randEuint32();
        uint32 random32 = 0xfe; // we fix a constant value for evaluation, which cannot be used for product version.

        uint8 rangeBits = getRangeBits(range); // number of bits needed at most

        for (uint8 i; i < positionsToGenerate; i++) {
            uint8 random8 = uint8(random32 >> (i * rangeBits));
            uint256 mask = 2 ** rangeBits - 1;
            random8 =  uint8(random8 & mask);
            positions[i] = generateNumber(random8, range);
        }
        return positions;
    }

    function deal() public onlyGameRunning onlyTurnDealNeeded {
        require(turnDealNeeded, "There is no need to deal cards");
        uint8[] memory positions = dealCards(uint8(remainingWires + 1), numberOfPlayers);
        for (uint i; i < positions.length; i++) {
            if (i == positions.length - 1) {
                bombPosition = positions[i];
            } else {
                wirePositions[i] = positions[i];
            }
        }
    }

    function turnCardLimit() internal view returns (uint8) {
        return uint8(5 - turnIndex);
    }

    function checkDeal() public onlyGameRunning onlyTurnDealNeeded {
        bool dealIsCorrect = true;
        for (uint8 i; i < numberOfPlayers; i++) {
            uint8 wires = 0;
            for (uint8 j; j < remainingWires; j++) {
                wires = wires + uint8(wirePositions[j]==i? 1: 0);
            }
            uint8 bomb = bombPosition == i ? 1 : 0;
            uint8 neutrals = turnCardLimit() - (wires + bomb);
            uint8 total = turnCardLimit();
            cards[players[i]] = Cards(bomb, wires, neutrals, total);
            dealIsCorrect = dealIsCorrect && (wires + bomb) <= turnCardLimit();
        }
        turnDealNeeded = !dealIsCorrect;
        if (turnDealNeeded) {
            emit FalseDeal();
        } else {
            emit GoodDeal();
        }
    }

    function giveRoles() internal onlyRoleDealNeeded returns (bool) {
        uint8 badGuys = 2;
        uint8[] memory positions = dealCards(badGuys, numberOfPlayers == 4 ? numberOfPlayers : numberOfPlayers - 1);
        if (numberOfPlayers > 4) {
            bool isCorrect = positions[0] != positions[1];
            if (!isCorrect) {
                return false;
            }
        }
        for (uint8 i; i < numberOfPlayers; i++) {
            bool role = positions[0] != i && positions[1] != i; // If equal, role is bad guy (so = 0)
            roles[players[i]] = role; // 1 = Nice guy / 0 = Bad guy
        }
        gameRoleDealNeeded = false;
        return true;
    }
    

    function getRole()
        public
        view
        onlyGameRunning
        onlyPlayer(msg.sender)
        returns (bool)
    {
        address player = msg.sender;
        return roles[player];
    }

    function getCards() public view onlyGameRunning returns (uint8[] memory) {
        uint8[] memory tableCards = new uint8[](numberOfPlayers);
        for (uint8 i = 0; i < numberOfPlayers; i++) {
            address player = players[i];
            tableCards[i] = cards[player].total;
        }
        return tableCards;
    }

    function getMyCards(
    )
        public
        view
        onlyGameRunning
        onlyPlayer(msg.sender)
        returns (uint8, uint8, uint8)
    {
        address player = msg.sender;
        uint8 wires = cards[player].wires;
        uint8 bomb = cards[player].bomb;
        uint8 neutrals = cards[player].neutrals;
        return (wires, bomb, neutrals);
    }

    function endGame() internal {
        gameRunning = false;
        open();
    }

    function takeCard(address player) public onlyGameRunning onlyTurnRunning onlyCurrentPlayer(msg.sender) {
        require(cards[player].total > 0);
        require(player != msg.sender);
        // uint8 random8 = TFHE.shr(TFHE.randuint8(), 5);
        uint8 random8 = 0xfe;
        uint8 correctedCard = generateNumber(random8, cards[player].total);
        // bool cardIsWire = TFHE.and(TFHE.gt(cards[player].wires, 0), TFHE.lt(correctedCard, cards[player].wires));
        // bool cardIsBomb = TFHE.and(TFHE.eq(cards[player].bomb, 1), TFHE.eq(correctedCard, cards[player].wires));
        bool cardIsWire = cards[player].wires > 0 && correctedCard < cards[player].wires;
        bool cardIsBomb = cards[player].bomb == 1 && correctedCard == cards[player].wires;
        
        if (cardIsWire){
            cards[player].wires = cards[player].wires - 1;
        }
        else if (cardIsBomb){
            cards[player].bomb = cards[player].bomb - 1;
        }
        else{
            cards[player].neutrals = cards[player].neutrals - 1;
        }

        cards[player].total = cards[player].total - 1;

        uint8 cardType = uint8(CardType.NEUTRAL);

        if (cardIsWire){
            cardType = uint8(CardType.WIRE);
        }

        if (cardIsBomb){
            cardType = uint8(CardType.BOMB);
        }

        turnMove++;

        if (cardType == uint8(CardType.BOMB)) {
            emit BadGuysWin("bomb");
            endGame();
            return;
        }

        if (cardType == uint8(CardType.WIRE)) {
            remainingWires--;
            if (remainingWires == 0) {
                emit GoodGuysWin();
                endGame();
                return;
            }
        }

        if (turnMove == numberOfPlayers) {
            turnIndex++;
            if (turnIndex == 4) {
                emit BadGuysWin("cards");
                endGame();
                return;
            }
            emit Turn(turnIndex);
            turnMove = 0;
            turnDealNeeded = true;
        }

        emit CardPicked(cardType);
        turnCurrentPlayer = player;
    }

    modifier onlyPlayer(address player) {
        bool exists = false;
        for (uint8 i; i < numberOfPlayers; i++) {
            if (players[i] == player) exists = true;
        }
        require(exists, "This player doesn't exist");
        _;
    }

    modifier onlyNewPlayer(address player) {
        bool newPlayer = true;
        for (uint8 i; i < numberOfPlayers; i++) {
            if (players[i] == player) newPlayer = false;
        }
        require(newPlayer);
        _;
    }

    modifier onlyGameRunning() {
        require(!gameOpen && gameRunning, "The game is not running");
        _;
    }

    modifier onlyGameOpen() {
        require(gameOpen && !gameRunning, "The game is not open");
        _;
    }

    modifier onlyRoleDealNeeded() {
        require(gameRoleDealNeeded, "No need to deal cards");
        _;
    }

    modifier onlyTurnRunning() {
        require(turnMove < numberOfPlayers && !turnDealNeeded, "Need to deal cards");
        _;
    }

    modifier onlyTurnDealNeeded() {
        require(turnDealNeeded, "No need to deal cards");
        _;
    }

    modifier onlyCurrentPlayer(address player) {
        require(turnCurrentPlayer == player, "It's not your turn!");
        _;
    }
}