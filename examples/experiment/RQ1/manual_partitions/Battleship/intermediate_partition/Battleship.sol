// SPDX-License-Identifier: BSD-3-Clause-Clear
// https://github.com/battleship-fhevm/battleship-hardhat/blob/main/contracts/Battleship.sol
pragma solidity >=0.8.13 <0.9.0;

contract Battleship {
    address public player1;
    address public player2;
    address public currentPlayer;
    address public winner;
    bool public gameEnded;
    bool public gameReady;
    bool public player1Ready;
    bool public player2Ready;

    uint8 public constant BOARD_SIZE = 4; // max size is 5
    uint8 public player1ShipsHit;
    uint8 public player2ShipsHit;

    // 0 = empty
    // 1 = ship
    // 2 = attacked
    uint8[4][4] public player1Board;
    uint8[4][4] public player2Board;

    event Attack(uint8 x, uint8 y, address victim, bool hit);
    event GameEnded(address winner);

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "Only players can call this function");
        _;
    }

    constructor(address _player1, address _player2) {
        player1 = _player1;
        player2 = _player2;
        currentPlayer = player1;
    }

    function placeShips(uint32 packedData) public onlyPlayers {
        require(!gameEnded, "Game has ended");
        require(!gameReady, "Boards already set");

        // values are encoded as bits from right to left
        // 0 = empty
        // 1 = ship
        //
        // example input:
        //
        // 0010001011001100
        //
        // results in the following board:
        //
        // 0 0 1 1
        // 0 0 1 1
        // 0 1 0 0
        // 0 1 0 0
        bool isPlayer1;
        if(msg.sender == player1  ){
            isPlayer1 = true;
        } else {
            isPlayer1 = false;
        }

        placeShips_priv(isPlayer1, packedData);
        placeShips_callback(msg.sender);
    }

    function placeShips_priv(bool isPlayer1, uint32 packedData) internal  returns (bool) {
        uint8[BOARD_SIZE][BOARD_SIZE] storage board;
        if(isPlayer1){
            board = player1Board;
        } else {
            board = player2Board;
        }
        uint8 mask = 1;
        uint8 shipCount = 0;

        for (uint256 i = 0; i < BOARD_SIZE * BOARD_SIZE; i++) {
          uint8 value = uint8(packedData & mask);
          board[i / BOARD_SIZE][i % BOARD_SIZE] = value;
          shipCount = shipCount + value;

          packedData = packedData >> 1;
        }

        // Make sure the user created 6 ships
        require(shipCount == 6);
        return true;
    }

    function placeShips_callback(address sender) internal {
        if (sender == player1) {
            player1Ready = true;
        } else {
            player2Ready = true;
        }

        if (player2Ready && player1Ready) {
            gameReady = true;
        }
    }


    function attack(uint8 _x, uint8 _y) public onlyPlayers {
        require(gameReady, "Game not ready");
        require(!gameEnded, "Game has ended");
        require(msg.sender == currentPlayer, "Not your turn");

        bool isPlayer1;
        if(msg.sender == player1  ){
            isPlayer1 = true;
        } else {
            isPlayer1 = false;
        }

        bool my_gameEnded = attack_priv(isPlayer1, _x, _y);
        attack_callback(msg.sender, my_gameEnded);
    }

    function attack_priv(bool isPlayer1, uint8 _x, uint8 _y) internal returns (bool) {
        bool my_gameEnded = false;
        uint8[4][4] storage targetBoard;
        if (isPlayer1) {
            targetBoard = player2Board;
        } else {
            targetBoard = player1Board;
        }

        uint8 target = targetBoard[_x][_y];
        require(target < 2, "Already attacked this cell");

        if (target == 1) {
            if (isPlayer1) {
                player2ShipsHit++;
                emit Attack(_x, _y, player2, true);
            } else {
                player1ShipsHit++;
                emit Attack(_x, _y, player1, true);
            }
            if (player1ShipsHit == 6 || player2ShipsHit == 6) {
                my_gameEnded = true;
            }
        } else {
            if (isPlayer1) {
                emit Attack(_x, _y, player2, false);
            } else {
                emit Attack(_x, _y, player1, false);
            }
        }
        targetBoard[_x][_y] = 2;
        return my_gameEnded;
    }

    function attack_callback(address sender, bool my_gameEnded) internal {
        if (my_gameEnded){
            gameEnded = true;
            winner = sender;
            emit GameEnded(msg.sender);
        }

        if (currentPlayer == player1) {
            currentPlayer = player2;
        } else {
            currentPlayer = player1;
        }
    }
}