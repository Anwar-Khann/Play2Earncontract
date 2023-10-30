// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract PotFighter is Ownable {
    // uint256 public potFee = 100000000000000 wei;
    uint256 public potFee = 1 ether;

    uint256 public rewardPerSecondPercent = 3;
    uint256 internal potId = 1; //RESPONSIBLE FOR ASSIGNING UNIQUE IDENTIFIER TO THE POT
    address public reserveWallet;
    uint8[5] distribution = [40, 31, 18, 8, 3];

    event PotCreated(address from, uint256 fee, uint256 atTime);
    event PotJoined(address joiner, uint256 againstAmount, uint256 atTime);

    modifier potFreezed(uint256 _potId) {
        require(freezedPot[_potId] == false, "pot is freezed");
        _;
    }
    modifier userBlackListed() {
        require(
            blackListedUser[msg.sender] == false,
            "you are blackListed User"
        );
        _;
    }

    struct participant {
        address payable userAddress;
        uint256 startedAt; //THE TIME PLAYER ENTERD THE POT
        uint256 endedAt; //THE TIME PLAYER IS REPLACED AS A LAST PLAYER
        uint256 durationPlayed; //TOTAL TIME DURATION IN SECOND'S THAT THE PLAYER HAD PLAYED
        uint256 reward; //REWARD EARNED PER 0.001 OF POT BALANCE PER SECOND
        bool rewardCollected; //MONITOR TO WHETHER USER HAS GET HIS REWARD YET OR NOT
    }
    struct Pot {
        address creator; //POT OWNER
        uint256 potBalance; //POT BALANCE OF ALL TIME
        participant[] participants; //PLAYER'S IN THE POT
        bool claimingActive; //REWARD CLAIMING WHEN POT BALNCE RUNS OUT
        uint256 participationFeee;
        uint256 begining;
        uint256 lifeTime; //DURATION OF THE POT
    }

    mapping(uint256 => Pot) public createdPots; //POTS CREATED OF ALL TIME BY ID
    mapping(uint256 => bool) public freezedPot; //POT FREEZING MONITOR
    mapping(address => bool) public blackListedUser; //RESTRICED

    constructor(address _reserveWallet) {
        reserveWallet = _reserveWallet;
    }

    function readParticipationFee(uint8 _potId) public view returns (uint256) {
        return createdPots[_potId].participationFeee;
    }

    function isClaimingActive(uint8 _potId) public view returns (bool) {
        return createdPots[_potId].claimingActive;
    }

    function createPot() external payable userBlackListed {
        Pot storage pot = createdPots[potId];
        // potFee = msg.value;
        // require(msg.sender.balance>= potFee);

        require(msg.value == potFee, "pay fee to create Pot");
        

        pot.creator = msg.sender;
        pot.potBalance += msg.value; //ADD THE AMOUNT TO POT
        pot.begining = block.timestamp;
        pot.participationFeee = 20000000000000000;
        //ORGANIZER IS ALSO SET AS A FIRST PLAYER
        pot.participants.push(
            participant({
                userAddress: payable(msg.sender),
                startedAt: block.number, // THE CURRENT TIME AT WHICH GAME IS STARTED
                endedAt: 0, // OTHER VALUES WILL BE PASSED AS OF DEFAULT FOR NOW
                durationPlayed: 0,
                reward: 0,
                rewardCollected: false
            })
        );
        // uint256 toLife =
        pot.lifeTime = (block.timestamp + 21600);
        // pot.lastPlayers.push(msg.sender);
        potId++; //this line make sure that each pot has unique id
        emit PotCreated(msg.sender, msg.value, block.timestamp);
        emit PotJoined(msg.sender, msg.value, block.timestamp);
    }

    function getAllPots() public view returns (Pot[] memory) {
        // Initialize the length of the result array with potId - 1
        Pot[] memory allPots = new Pot[](potId > 0 ? potId - 1 : 0);
        for (uint i = 1; i < potId; i++) {
            allPots[i - 1] = createdPots[i];
        }
        return allPots;
    }

    function joinPot(
        uint256 _potId
    ) external payable potFreezed(_potId) userBlackListed {
        Pot storage pot = createdPots[_potId];
        require(block.timestamp <= pot.lifeTime,"life ended activate claiming");
        require(_potId != 0 && _potId <= potId, "Invalid Pot Id");
        require(
         
            pot.potBalance >= 0.001 ether,
            "Pot balance isn't valid to play further"
        );
        pot.participationFeee = msg.value;
        require(
            msg.value == pot.participationFeee,
            "Pay the fee to join the pot"
        );

            uint256 currentSize = pot.participants.length;
            participant storage p = pot.participants[currentSize - 1];
            p.endedAt = block.number;
            uint256 blocksElapsed = p.endedAt - p.startedAt;
            p.durationPlayed += blocksElapsed;
            bool rewardMonitor;

            for (uint256 i = 0; i < blocksElapsed; i++) {
                uint256 percentPerSecond = (pot.potBalance *
                    rewardPerSecondPercent) / 10000;

                // Check if the reward calculation exceeds the pot balance
                if (percentPerSecond > pot.potBalance) {
                    rewardMonitor = true;
                    break;
                }

                // Calculate reward for the current second
                p.reward += percentPerSecond;
                pot.potBalance -= percentPerSecond;
            }

            if (rewardMonitor) {
                payable(msg.sender).transfer(msg.value);
                pot.claimingActive = true;
                console.log("Claiming is activated");
            } else {
                // Distribute the fees and adjust the pot balance
                distributeFees(pot, currentSize, msg.value);
                //below distribution for reward

                uint256 startIndex;
                uint256 lastIndex;

                if (currentSize > 5) {
                    startIndex = currentSize - 5;
                    lastIndex = currentSize;
                    console.log("reward when greater than 5");
                    uint256 playerReward = pot.participants[startIndex].reward;
                    console.log(
                        "strting in there from",
                        pot.participants[startIndex].userAddress
                    );
                    for (uint256 i = startIndex; i < lastIndex; i++) {
                        uint256 toSend = (playerReward *
                            distribution[i - startIndex]) / 100; // Changed this line

                        console.log(
                            "sending to",
                            pot.participants[i].userAddress
                        );
                        payable(pot.participants[i].userAddress).transfer(
                            toSend
                        );
                        console.log("the reward will be", toSend);
                    }
                    pot.participants[startIndex].rewardCollected = true;
                } else if (currentSize == 5) {
                    startIndex = 0;
                    lastIndex = currentSize;
                    console.log("reward when max 5");
                    uint256 playerRewardFor = pot
                        .participants[startIndex]
                        .reward;
                    for (uint256 i = startIndex; i < lastIndex; i++) {
                        // payable(pot.participants[i].userAddress).transfer(playerRewardFor*distribution[i]/100);
                        payable(pot.participants[i].userAddress).transfer(
                            (playerRewardFor * distribution[i - startIndex]) /
                                100
                        ); // Changed this line
                        playerRewardFor -=
                            (playerRewardFor * distribution[i]) /
                            100;
                    }
                    pot.participants[startIndex].rewardCollected = true;
                }

                // Create a new participant
                pot.participants.push(
                    participant({
                        userAddress: payable(msg.sender),
                        startedAt: block.number,
                        endedAt: 0,
                        durationPlayed: 0,
                        reward: 0,
                        rewardCollected: false
                    })
                );
                uint256 increaseInFee = feePercent(pot);
                pot.participationFeee += increaseInFee;
                pot.lifeTime += 60;
                emit PotJoined(msg.sender, msg.value, block.timestamp);
            }
        
    }


    function distributeFees(
        Pot storage pot,
        uint256 currentSize,
        uint256 totalFees
    ) internal {
        uint256 ownerCut = (totalFees * 50) / 100;
        uint256 partnerCut = (totalFees * 5) / 100;
        uint256 teamCut = (totalFees * 5) / 100;
        uint256 previousPlayers = (totalFees * 20) / 100;
        uint256 potBalanceSubmit = (totalFees * 20) / 100;

        payable(pot.creator).transfer(ownerCut);
        payable(reserveWallet).transfer(partnerCut);
        payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2).transfer(teamCut);

        if (currentSize == 1) {
            payable(pot.participants[0].userAddress).transfer(previousPlayers);
        } else if (currentSize > 1) {
            uint256 divideAmong = previousPlayers / currentSize;
            for (uint256 i = 0; i < currentSize; i++) {
                payable(pot.participants[i].userAddress).transfer(divideAmong);
            }
        }

        pot.potBalance += potBalanceSubmit;
    }

    //FUNCTION TO ACTIVATE CLAIMING
    function activateClamining(uint256 _potId)public{
         Pot memory pot = createdPots[_potId];
        require(block.timestamp > pot.lifeTime,"pot isn't ended yet");
        require(msg.sender == pot.creator,"only pot owner can activate claiming");
        require(_potId != 0 && _potId <= potId, "invalid Pot Id");
        
         participant memory lastPlayer = pot.participants[pot.participants.length - 1];
         uint256 lastBlock = estimateBlockNumber(pot.lifeTime);
         lastPlayer.endedAt = lastBlock;
          uint256 blocksElapsed = lastPlayer.endedAt - lastPlayer.startedAt;
         lastPlayer.durationPlayed = blocksElapsed;
           for (uint256 k = 0; k <= lastPlayer.durationPlayed; k++) {
                uint256 percentPerSecond = (pot.potBalance *
                    rewardPerSecondPercent) / 10000;

                // Check if the reward calculation exceeds the pot balance
                if (percentPerSecond > pot.potBalance) {
                    break;
                }

                // Calculate reward for the current second
                lastPlayer.reward += percentPerSecond;
                pot.potBalance -= percentPerSecond;
            }
            uint256 leftBalance = pot.potBalance;
             if (leftBalance > 0) {
                payable(pot.creator).transfer(leftBalance);
            }
            pot.claimingActive = true;
            console.log("Claiming is activated");

    }

    //FUNCTION TO INCREASE THE PARTICIPATION FEE

    function feePercent(Pot storage pot) internal view returns (uint256) {
        uint256 percent = (pot.participationFeee * 1) / 100;
        return percent;
    }

    //FUNCTION TO CLAIM REWARD
    function claimReward(uint256 _potId) public {
        Pot storage pot = createdPots[_potId];
        require(pot.claimingActive, "claiming isn't active");
        require(_potId != 0 && _potId <= potId, "invalid Pot Id");
        uint256 size = pot.participants.length;
        for (uint256 i = 0; i < size; i++) {
            if (pot.participants[i].userAddress == msg.sender) {
                if (pot.participants[i].rewardCollected) {
                    continue;
                } else {
                    payable(msg.sender).transfer(pot.participants[i].reward);
                    pot.participants[i].reward = 0;
                    pot.participants[i].rewardCollected = true;
                    break;
                }
            }
        }
    }

    //FUNCTION TO SET RESERVE WALLET
    function setReserveWallet(address _partner) public onlyOwner {
        reserveWallet = _partner;
    }

    //FUNCTION TO BLACKLIST USER
    function blackListUser(address _user) public onlyOwner {
        require(!blackListedUser[_user], "user already blackListed");
        blackListedUser[_user] = true;
    }

    //FUNCTION TO WHITELIST USER
    function UnBlackListUser(address _user) public onlyOwner {
        require(blackListedUser[_user], "user isn't blackListed");
        blackListedUser[_user] = false;
    }

    //FUNCTION TO FREEZE POT
    function freezePot(uint256 _potId) public onlyOwner {
        require(_potId < potId, "invalid potId");
        require(!freezedPot[_potId], "pot already freezed");
        freezedPot[_potId] = true;
    }

    //FUNCTION TO UNFREEZE POT;
    function unFreezePot(uint256 _potId) public onlyOwner {
        require(_potId < potId, "invalid potId");
        require(freezedPot[_potId], "pot isn't freezed");
        freezedPot[_potId] = false;
    }

    function getPotParticipants(
        uint256 _potId
    ) external view returns (participant[] memory) {
        Pot storage pot = createdPots[_potId];
        return pot.participants;
    }

    function getPotBalance(uint256 _potId) public view returns (uint256) {
        Pot storage pot = createdPots[_potId];
        uint256 balance = pot.potBalance;
        return balance;
    }

    function userReward(
        uint256 potIdd,
        uint256 userIndex
    ) public view returns (uint256) {
        Pot memory pot = createdPots[potIdd];
        participant memory participantt = pot.participants[userIndex];
        return participantt.reward;
    }

    //PROFITABILITY MATRICS

    function getPlayerEarnings(
        uint256 _potId
    ) external view returns (uint256[6] memory) {
        Pot storage pot = createdPots[_potId];
        uint256 currentSize = pot.participants.length;

        require(_potId > 0 && _potId <= potId, "Invalid Pot Id");
        require(currentSize > 0, "No participants in the pot");

        uint256[6] memory earnings; // Array to store the earnings

        // Calculate the earnings for the last 5 players
        uint256 startIndex;
        uint256 lastIndex;

        if (currentSize > 5) {
            startIndex = currentSize - 5;
            lastIndex = currentSize;

            for (uint256 i = startIndex; i < lastIndex; i++) {
                earnings[i - startIndex] = pot.participants[i].reward;
            }
        } else {
            startIndex = 0;
            lastIndex = currentSize;

            for (uint256 i = startIndex; i < lastIndex; i++) {
                earnings[i] = pot.participants[i].reward;
            }
        }

        // Calculate the earnings for the caller (the player who executes the function)
        for (uint256 i = 0; i < currentSize; i++) {
            if (pot.participants[i].userAddress == msg.sender) {
                earnings[5] = pot.participants[i].reward;
                break;
            }
        }

        return earnings;
    }

    //ROUND STATISTICS

    function getPotInfo(
        uint256 _potId
    )
        external
        view
        returns (uint256 players, uint256 startTime, uint256 endTime)
    {
        Pot storage pot = createdPots[_potId];

        require(_potId > 0 && _potId <= potId, "Invalid Pot Id");
        require(pot.participants.length > 0, "No participants in the pot");

        // Retrieve player addresses
        players = pot.participants.length;

        // Return the starting and ending times from events
        startTime = pot.begining; // Starting time of the first player
        endTime = pot.lifeTime; // Ending time based on the pot's lifetime

        return (players, startTime, endTime);
    }

    function pushValue(
        uint256[] memory array,
        uint256 value
    ) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = value;
        return newArray;
    }

     function estimateBlockNumber(uint256 timestamp) internal  view returns (uint256) {
        // The block time in Ethereum is approximately 15 seconds
        uint256 blockTime = 3;  // Adjust this if necessary
        uint256 currentBlock = block.number;
        uint256 currentTimestamp = block.timestamp;

        // Calculate the difference in timestamps and estimate the block number
        uint256 timestampDifference = currentTimestamp - timestamp;
        uint256 blockNumber = currentBlock - (timestampDifference / blockTime);
        return blockNumber;
    }
}
