// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
// Just one thing to modify in phase 2 but its impossible for you to do i can also understand :
// Instead of distributing 100% of the pot to only the last player, I would like the distribution to be among the 5 last players based on 70% for the last player, then 56%, 42%, 28%, 14%. When you change ranks with the arrival of other players, the calculations are updated, and winnings are adjusted based on the rank. When you reach the 6th position, you no longer receive the 0.001%, but only your share of fees from the following games. So, winnings will be sent only when you reach the 6th position in the ranking or to all players if the Pot goes down to 0.01 BNB, at which point the game ends.
// I believe it would make the game more appealing.

// Just one thing to modify in phase 2 but its impossible for you to do i can also understand :
// Instead of distributing 100% of the pot to only the last player, I would like the distribution to be among the 5 last players based on 70% for the last player, then 56%, 42%, 28%, 14%. When you change ranks with the arrival of other players, the calculations are updated, and winnings are adjusted based on the rank. When you reach the 6th position, you no longer receive the 0.001%, but only your share of fees from the following games. So, winnings will be sent only when you reach the 6th position in the ranking or to all players if the Pot goes down to 0.01 BNB, at which point the game ends.
// I believe it would make the game more appealing.

//______fee
// Game costs 0.2 BNB, distributed as follows: 55% to the game organiser, 20% added to the prize pot,
//  20% returned to all previous players, and 5% for the development team
contract PotGame {
    uint256 public potFee = 1 ether;
    uint256 public partcipationFee;
    uint256 internal potId;

    struct participant {
        address userAddress;
        uint256 gameStart;
        uint256 beingLastPlayer;
        uint256 earnedReward;
    }
    struct Pot {
        address creator;
        uint256 potBalance;
        participant[] participants;
        address payable[5] lastPlayers;
    }

    mapping(uint256 => Pot) public createdPots;

    function createPot() public payable {
        require(msg.value == potFee, "pay fee to create Pot");
        Pot storage pot = createdPots[potId];
        pot.creator = msg.sender;
        pot.potBalance += msg.value;
        potId++;
    }

    // i have to check it also from the perspective of when some one join's i have to update the timing 's of player's respectively
    function joinPot(uint256 _potId, uint256 _fee) public payable {
        require(msg.value == partcipationFee);
        _fee = msg.value; //this variable will be used for calculation's
        Pot storage pot = createdPots[_potId];
        uint256 lengthToCompare = pot.participants.length;
        if (lengthToCompare == 0) {
            pot.participants.push(
                participant({
                    userAddress: msg.sender,
                    gameStart: block.timestamp, // You can set the game start time to the current block timestamp
                    beingLastPlayer: 0, // Initialize other values as needed
                    earnedReward: 0
                })
            );
        } else if (lengthToCompare > 0) {
            participant storage p = pot.participants[lengthToCompare - 1];
            p.beingLastPlayer = block.timestamp; //when new player will join the previous player's playing duration will also be calculate
            p.earnedReward = (p.beingLastPlayer - p.gameStart); //update the second's that player played the game last player
            pot.participants.push(
                participant({
                    userAddress: msg.sender,
                    gameStart: block.timestamp, // You can set the game start time to the current block timestamp
                    beingLastPlayer: 0, // Initialize other values as needed
                    earnedReward: 0
                })
            );
        }
        // pot.potBalance += partcipationFee; //first handle fee distribution to other factor's also
    }

    function countPlayerDuration(uint256 _potId, uint256 participantIndex)
        public
        view
        returns (uint256)
    {
        Pot storage pot = createdPots[_potId];
        require(
            participantIndex < pot.participants.length,
            "Invalid participant index"
        );

        participant storage p = pot.participants[participantIndex];
        uint256 endTime = p.beingLastPlayer; // Get the current block timestamp as the end time
        uint256 duration = endTime - p.gameStart; // Calculate the duration

        return duration;
    }
}