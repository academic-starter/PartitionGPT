// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Leaderboard {

    struct Player {
        address user;
        uint32 score;
    }

    mapping(address => Player) public players;

    uint32 private highestScore = 0;

    // Function to add a player to the leaderboard
    function addPlayer(address _user, uint32 encryptedScore) public {
        uint32 score = encryptedScore;
        bool isAbove = highestScore <= score;
        if (isAbove){
            highestScore = score;
        }
        
        // add player to leaderboard
        players[_user] = Player(_user, score);

    }

    // Function to get a player's score
    function getPlayerScore(address _user) public view returns (uint32) {
        require(msg.sender == _user, "Player score not registered");
        return players[_user].score;
    }

    // function to get the player's score in relation to the highest score
    function getScoreRelativeToHighestScore() public view returns (uint) {
        uint32 score = players[msg.sender].score;
        uint32 highest = highestScore;
        uint32 a = score * 100;
        uint32 b = highest * 100;
        uint32 times = a / b;
        return times;
    }
}