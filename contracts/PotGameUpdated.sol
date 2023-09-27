// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
contract PotGame is Ownable{
    uint256 public potFee = 1 ether;
    uint256 public partcipationFee = 200000000000000000 wei;
    uint256 public rewardPerSecondPercent = 1;
    uint256 internal potId; //RESPONSIBLE FOR ASSIGNING UNIQUE IDENTIFIER TO THE POT

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
    mapping(uint256 => bool) public freezedPot;
    mapping(address => bool) public blackListedUser;

    event PotCreated(address from,uint256 fee,uint256 atTime);
    event PotJoined(address joiner,uint256 againstAmount,uint256 atTime);

    modifier potFreezed(uint256 _potId){
        require(freezedPot[_potId] == false,"pot is freezed");
        _;
    }
    modifier userBlackListed(){
        require(blackListedUser[msg.sender] == false,"you are blackListed User");
        _;
    }

    function createPot() public payable userBlackListed {
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
                reward: 0
            })
        );
        // pot.lastPlayers.push(msg.sender);
        potId++; //this line make sure that each pot has unique id
        emit PotCreated(msg.sender,msg.value,block.timestamp);
    }

    // i have to check it also from the perspective of when some one join's i have to update the timing 's of player's respectively
    function joinPot(uint256 _potId) public payable potFreezed(_potId) userBlackListed {
        require(msg.value == partcipationFee, "pay exact fee to join Pot");

        uint256 localFee = partcipationFee; //LOCAL INSTANCE OF PARTICIPATION FEE TO OPTIMIZE GAS CONSUMPTION OF CONTRACT
        Pot storage pot = createdPots[_potId];
        //___________________________
        uint256 lengthToCompare = pot.participants.length;
        //IF THERE ARE MORE THEN 5 PLAYER'S THEN REWARD DISTRIBUTION WILL BE DONE ALSO
        if (lengthToCompare > 5) {
            uint256 startIndex = pot.participants.length - 5; // Calculate the starting index for the last 5 players
            uint256 endIndex = pot.participants.length - 1;
            uint256 lengthToOperate = pot.participants.length;
            participant storage PotForReward = pot.participants[lengthToOperate - startIndex];
            uint256 collectedReward = PotForReward.reward;
            uint8[5] memory distribution = [40, 31, 18, 8, 3]; //PERCENTAGE AMONG LAST 5 PLAYER'S

            for (uint256 i = startIndex; i <= endIndex; i--) {

                payable(pot.participants[i].userAddress).transfer(
                    (collectedReward * distribution[i]) / 100
                );
                // collectedReward -= distribution[i];
            }
        }
        //____________________
        //HELP TO TRACK & UPDATE LAST PLAYER
        participant storage p = pot.participants[lengthToCompare - 1];
        p.beingLastPlayer = block.timestamp;
        //WHEN NEW PLAYER WILL JOIN THE PREVIOUS PLAYER'S PLAYING DURATION WILL ALSO BE CALCULATED
        // i should also calculate the price of previous player right at the time he is removed from the last position
        p.earnedReward = (p.beingLastPlayer - p.gameStart); //UPDATE THE TOTAL SECOND'S OF PLAYER AS A LAST PLAYER
        for (uint256 i; i < p.earnedReward; i++) {
            uint256 percentPerSecond = (pot.potBalance *
                rewardPerSecondPercent) / 10000;
            p.reward += percentPerSecond; //PER SECOND REWARD ADDED TO THE LAST USER REWARD
            pot.potBalance -= percentPerSecond; //POT BALANCE IS ALSO UPDATED BY EXCLUDING THE REWARD AMOUNT OF PLAYER SO CALCULATION IS RIGHT;
        }
        pot.participants.push(
            participant({
                userAddress: payable(msg.sender),
                gameStart: block.timestamp, // THE GAME START WILL BE SET AS CURRENT BLOCK.TIMESTAMP
                beingLastPlayer: 0, // OTHER VALUES WILL BE PASSED AS OF DEFAULT FOR NOW
                earnedReward: 0,
                reward: 0
            })
        );

        //NOW FEE DISTRIBUTION BEGIN'S THE FEE WHICH IS PAID BY NEW PLAYER TO JOIN THE POT;
        //pot owner participant and development fee distribution is implemented
        //FEE FOR FOLLOWING DISTRIBUTION IMPLEMENTED
        // 1.POT OWNER
        // 2.PARTICIPANT'S
        // 3.POT BALANCE
        // 4.DEVELOPMENT TEAM
        uint256 percentToParticipants = (localFee * 20) / 100; //PERCENTAGE OF POT TO THE PARTICIPANT
        uint256 didvideAmongParticipant = percentToParticipants /
            lengthToCompare; //DIVIDING PERCENT FOR PREVIOUS PLAYER EQUALLY

        //BELOW LOOP WILL DISTRIBUTE THE 20% OF FEE AMONG ALL LAST PLAYER'S EQUALLY
        for (uint256 i; i < lengthToCompare; i++) {
            payable(pot.participants[i].userAddress).transfer(
                didvideAmongParticipant
            );
        }
        // localFee -= percentToParticipants;//EXCLUDED THE PERCENTAGE OF PARTICPANT FROM FEE SO OTHER CALCULATION'S WON'T MESS UP
        uint256 ownersCut = (localFee * 55) / 100;//
        // localFee -= ownersCut;
        payable(pot.creator).transfer(ownersCut);
        uint256 teamPercent = (localFee * 5) / 100;
        payable(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB).transfer(
            teamPercent
        );
        // localFee -= teamPercent;
        //will test the flow of this below statement
        pot.potBalance += localFee; //REMAINING PERCENTAGE ADDED TO THE POT BALANCE
        //FEE DISTRIBUTION ENDS HERE
    }

    //FUNCTION TO BLACKLIST USER
    function blackListUser(address _user)public onlyOwner{
        require(!blackListedUser[_user],"user already blackListed");
        blackListedUser[_user] = true;
    }

    //FUNCTION TO WHITELIST USER
    function UnBlackListUser(address _user)public onlyOwner {
        require(blackListedUser[_user],"user isn't blackListed");
        blackListedUser[_user] = false;
    }

    //FUNCTION TO FREEZE POT
    function freezePot(uint256 _potId)public onlyOwner{
        require(_potId < potId,"invalid potId");
        require(!freezedPot[_potId],"pot already freezed");
        freezedPot[_potId] = true;
    }

    //FUNCTION TO UNFREEZE POT;
    function unFreezePot(uint256 _potId)public onlyOwner{
        require(_potId < potId,"invalid potId");
        require(freezedPot[_potId],"pot isn't freezed");
        freezedPot[_potId] = false;
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

    function getPotBalance(uint256 _potId) public view returns (uint256) {
        Pot storage pot = createdPots[_potId];
        uint256 balance = pot.potBalance;
        return balance;
    }
}
