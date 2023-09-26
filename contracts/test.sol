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
    uint256 internal potId;//CAN USE THIS TO GET ALL POTS
    // uint256[4] internal feePercentages = [55, 20, 20, 5];

    struct participant {
        address payable userAddress;
        uint256 gameStart;
        uint256 beingLastPlayer;
        uint256 earnedReward;
        uint256 reward;
    }
    struct Pot {
        address creator;
        uint256 potBalance;
        participant[] participants;
        // address[] lastPlayers;
    }

    mapping(uint256 => Pot) public createdPots;

    function createPot() public payable {
        require(msg.value == potFee, "pay fee to create Pot");
        Pot storage pot = createdPots[potId];
        pot.creator = msg.sender;
        pot.potBalance += msg.value;
        //ORGANIZER IS ALSO SET AS A FIRST PLAYER
        pot.participants.push(
            participant({
                userAddress: payable(msg.sender),
                gameStart: block.timestamp, // THE CURRENT TIME AT WHICH GAME IS STARTED 
                beingLastPlayer: 0, // OTHER VALUES WILL BE PASSED AS OF DEFAULT FOR NOW
                earnedReward: 0,
                reward:0
            })
        );
        // pot.lastPlayers.push(msg.sender);
        potId++; //this line make sure that each pot has unique id
    }

    // i have to check it also from the perspective of when some one join's i have to update the timing 's of player's respectively
    function joinPot(uint256 _potId, uint256 _fee) public payable {
        require(msg.value == partcipationFee, "pay exact fee to join Pot");
        _fee = msg.value; //THIS WILL BE USED FOR CALCULATIONS
        //length ka local variable b bnana hai q k use ziada hai to hum usko optimize kar sakain.
        uint256 localFee = partcipationFee;
        Pot storage pot = createdPots[_potId];
        uint256 lengthToCompare = pot.participants.length; //HELP TO TRACK & UPDATE LAST PLAYER
        participant storage p = pot.participants[lengthToCompare - 1];
        p.beingLastPlayer = block.timestamp;
         //WHEN NEW PLAYER WILL JOIN THE PREVIOUS PLAYER'S PLAYING DURATION WILL ALSO BE CALCULATED
        // i should also calculate the price of previous player right at the time he is removed from the last position
        p.earnedReward = (p.beingLastPlayer - p.gameStart); //UPDATE THE TOTAL SECOND'S OF PLAYER AS A LAST PLAYER
        for(uint256 i;i<p.earnedReward;i++){
          uint256 percentPerSecond = (pot.potBalance * rewardPerSecondPercent) /10000;
          p.reward += percentPerSecond;//PER SECOND REWARD ADDED TO THE LAST USER REWARD
          pot.potBalance -= percentPerSecond;//POT BALANCE IS ALSO UPDATED BY EXCLUDING THE REWARD AMOUNT OF PLAYER;
        }
        pot.participants.push(
            participant({
                userAddress: payable(msg.sender),
                gameStart: block.timestamp, // THE GAME START WILL BE SET AS CURRENT BLOCK.TIMESTAMP
                beingLastPlayer: 0, // OTHER VALUES WILL BE PASSED AS OF DEFAULT FOR NOW
                earnedReward: 0,
                reward:0
            })
        );

        //NOW FEE DISTRIBUTION BEGIN'S THE FEE WHICH IS PAID BY NEW PLAYER TO JOIN THE POT;
        //pot owner participant and development fee distribution is implemented
        //FEE FOR FOLLOWING DISTRIBUTION IMPLEMENTED
        // 1.POT OWNER
        // 2.PARTICIPANT'S
        // 3.POT BALANCE
        // 4.DEVELOPMENT TEAM
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
        pot.potBalance += localFee; //REMAINING PERCENTAGE ADDED TO THE POT BALANCE
        //FEE DISTRIBUTION ENDS HERE

        //NOW THE PART WHERE LAST PLAYERS REWARD DISTRIUTION IS HAPPENING WILL BE IMPLEMENTED BELOW
        //WE WILL CALCULATE THE REWARD OF LAST PLAYER AND DISTRIBUTE IT AMONG LAST 5 PLAYER'S
        if (pot.participants.length > 5) {
             uint256 startIndex = pot.participants.length - 5; // Calculate the starting index for the last 5 players
             uint256 endIndex = pot.participants.length - 1; 
             uint256 lengthToOperate = pot.participants.length;
             participant storage PotForReward = pot.participants[lengthToOperate -startIndex];
             uint256 collectedReward = PotForReward.reward;
            uint8[5] memory distribution = [40, 31, 18, 8, 3];//PERCENTAGE AMONG LAST 5 PLAYER'S

             for(uint256 i = startIndex; i <=endIndex; i--){
                 //Pot distribution : 40% for the last player, then 31%, 18%, 8%, 3% 
            // address payable recipient = payable(pot.participants[i].userAddress);

                 payable(pot.participants[i].userAddress).transfer(collectedReward*distribution[i]/100);
                 collectedReward -= distribution[i];
                
             }
            // participant storage lastPlayerIndex = pot.participants[
            //     lengthToCompare - 5
            // ]; //THE FIRST PLAYER IN LAST 5
            // uint256 rewardOfLastPlayer = lastPlayerIndex.earnedReward; //HIS ALL SECOND'S THAT HE REMAINED PLAYER
            // uint256 toBeDistributed; //CARRIES THE WHOLE EARNED REWARD FOR PER SECOND
            // for (uint256 i; i < rewardOfLastPlayer; i++) {
            //     uint256 nowThis = (pot.potBalance * rewardPerSecondPercent) /10000; // 10000 SCALING FACTOR FOR 0.001%
            //     pot.potBalance -= nowThis; //EXLUDE THE CALCULATED REWARD AGAINST THE SECOND'S OF PLAYER AND THE UPDATE
            //     // THE BALANCE OF POT
            //     toBeDistributed += nowThis;
            //     //AFTER CALCULATING THE WHOLE PERCENTAGE HERE THEN OUTSIDE OF LOOP WE WILL BEGIN DISTRIBUTING THE REWARD
            // }
           
           
            //now we will handle reward distribution
        }

        // }
        // pot.potBalance += partcipationFee; //first handle fee distribution to other factor's also
    }

    function countPlayerReward(uint256 _potId, uint256 participantIndex)
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
           // Calculate the duration

        return p.reward;
    }

    function getPotParticipants(uint256 _potId)
        external
        view
        returns (participant[] memory)
    {
        Pot storage pot = createdPots[_potId];
        return pot.participants;
    }

    function getPotBalance(uint256 _potId)public view returns(uint256){
        Pot storage pot = createdPots[_potId];
        uint256 balance = pot.potBalance;
        return balance;
    } 

    
}
