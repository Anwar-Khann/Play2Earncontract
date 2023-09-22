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
    uint256 public partcipationFee = 200000000000000000 wei;
    uint256 public rewardPerSecondPercent = 1;
    uint256 internal potId;
    // uint256[4] internal feePercentages = [55, 20, 20, 5];

    struct participant {
        address payable userAddress;
        uint256 gameStart;
        uint256 beingLastPlayer;
        uint256 earnedReward;
    }
    struct Pot {
        address creator;
        uint256 potBalance;
        participant[] participants;
        address[] lastPlayers;
    }

    mapping(uint256 => Pot) public createdPots;

    function createPot() public payable {
        require(msg.value == potFee, "pay fee to create Pot");
        Pot storage pot = createdPots[potId];
        pot.creator = msg.sender;
        pot.potBalance += msg.value;
        //now we will also make the organizer as a first player
        pot.participants.push(
            participant({
                userAddress: payable(msg.sender),
                gameStart: block.timestamp, // You can set the game start time to the current block timestamp
                beingLastPlayer: 0, // Initialize other values as needed
                earnedReward: 0
            })
        );
        pot.lastPlayers.push(msg.sender);
        potId++; //this line make sure that each pot has unique id
    }

    // i have to check it also from the perspective of when some one join's i have to update the timing 's of player's respectively
    function joinPot(uint256 _potId, uint256 _fee) public payable {
        require(msg.value == partcipationFee, "pay exact fee to join Pot");
        _fee = msg.value; //this variable will be used for calculation's
        //length ka local variable b bnana hai q k use ziada hai to hum usko optimize kar sakain.
        uint256 localFee = partcipationFee;
        Pot storage pot = createdPots[_potId];
        uint256 lengthToCompare = pot.participants.length; //help to trak and update last player's
        participant storage p = pot.participants[lengthToCompare - 1];
        p.beingLastPlayer = block.timestamp; //when new player will join the previous player's playing duration will also be calculate
        p.earnedReward = (p.beingLastPlayer - p.gameStart); //update the second's that player played the game last player
        pot.participants.push(
            participant({
                userAddress: payable(msg.sender),
                gameStart: block.timestamp, // You can set the game start time to the current block timestamp
                beingLastPlayer: 0, // Initialize other values as needed
                earnedReward: 0
            })
        );

        //now we will begin fee distribution for the fee that has been paid by the user;
        //pot owner participant and development fee distribution is implemented
        uint256 percentToParticipants = (localFee * 20) / 100;
        uint256 didvideAmongParticipant = percentToParticipants /
            lengthToCompare;
        for (uint256 i; i < lengthToCompare; i++) {
            payable(pot.participants[i].userAddress).transfer(
                didvideAmongParticipant
            );
        }
        localFee -= percentToParticipants;
        uint256 ownersCut = (localFee * 55) / 100;
        localFee -= ownersCut;
        payable(pot.creator).transfer(ownersCut);
        uint256 teamPercent = (localFee * 5) / 100;
        payable(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB).transfer(
            teamPercent
        );
        localFee -= teamPercent;
        //will test the flow of this below statement
        pot.potBalance += localFee; //left percentAge will be added to the potBalance
        //now remiaining part is of last players reward distribution
        //calute the reward of player and distribution of it among last 5 user's
        if (pot.participants.length > 5) {
            participant storage lastPlayerIndex = pot.participants[
                lengthToCompare - 5
            ]; //THE FIRST PLAYER IN LAST 5
            uint256 rewardOfLastPlayer = lastPlayerIndex.earnedReward; //HIS ALL SECOND'S THAT HE REMAINED PLAYER
            uint256 toBeDistributed; //CARRIES THE WHOLE EARNED REWARD FOR PER SECOND
            for (uint256 i; i < rewardOfLastPlayer; i++) {
                uint256 nowThis = (pot.potBalance * rewardPerSecondPercent) /10000; // 10000 scaling factor for 0.001%
                pot.potBalance -= nowThis; //exclude the calculated percentage for a second from potBalance and update the BALANCE OF POT
                toBeDistributed += nowThis;
                //AFTER CALCULATING THE WHOLE PERCENTAGE HERE THEN OUTSIDE OF LOOP WE WILL BEGIN DISTRIBUTING THE REWARD
            }
           
            //now we will handle reward distribution
        }

        // }
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

    function getPotParticipants(uint256 _potId)
        external
        view
        returns (participant[] memory)
    {
        Pot storage pot = createdPots[_potId];
        return pot.participants;
    }
}
