# PotGame Smart Contract Documentation

## Overview

The PotGame smart contract is a decentralized application that facilitates a game where users can create and join pots by paying fees. The contract distributes rewards among participants and allows for blacklisting users. It is built on the Ethereum blockchain.

## Contract Details

- **Contract Name:** PotGame
- **SPDX-License-Identifier:** UNLICENSED
- **Solidity Version:** 0.8.9

## Structures

### Participant

- `struct participant`
  - `userAddress`: Address of the participant.
  - `gameStart`: Timestamp when the participant joined the game.
  - `beingLastPlayer`: Timestamp when the participant became the last player.
  - `earnedReward`: Accumulated reward earned by the participant.
  - `reward`: Reward per second earned by the participant.

### Pot

- `struct Pot`
  - `creator`: Address of the pot creator.
  - `potBalance`: Total balance of the pot.
  - `participants`: Array of participants in the pot.

## Constructor

### `constructor()`

- **Description:** Initializes the contract, setting the deployer as the owner of the contract.

## Modifiers

### `modifier potFreezed(uint256 _potId)`

- **Description:** Ensures that the specified pot is not frozen.

### `modifier userBlackListed()`

- **Description:** Checks if the user is blacklisted.

## Functions

### `createPot()`

- **Description:** Allows users to create a new pot by paying a fee.
- **Requires:**
  - User is not blacklisted.
  - Sent value is equal to `potFee`.
- **Effects:**
  - Creates a new pot.
  - Adds the sender as the pot creator and a participant.
  - Initializes timestamps and rewards.

### `joinPot(uint256 _potId)`

- **Description:** Allows users to join an existing pot by paying a participation fee.
- **Parameters:**
  - `_potId`: Unique identifier of the pot to join.
- **Requires:**
  - User is not blacklisted.
  - Sent value is equal to `participationFee`.
- **Effects:**
  - Updates pot data.
  - Distributes rewards among participants.
  - Distributes fees to pot owner, participants, and the development team.

### `blackListUser(address _user)`

- **Description:** Blacklists a user, preventing them from participating in pots.
- **Parameters:**
  - `_user`: Address of the user to blacklist.
- **Requires:**
  - Function is called by the contract owner.

### `UnBlackListUser(address _user)`

- **Description:** Whitelists a user, allowing them to participate in pots.
- **Parameters:**
  - `_user`: Address of the user to whitelist.
- **Requires:**
  - Function is called by the contract owner.

### `freezePot(uint256 _potId)`

- **Description:** Freezes a pot, preventing new participants from joining.
- **Parameters:**
  - `_potId`: Unique identifier of the pot to freeze.
- **Requires:**
  - Function is called by the contract owner.

### `unFreezePot(uint256 _potId)`

- **Description:** Unfreezes a previously frozen pot, allowing new participants to join.
- **Parameters:**
  - `_potId`: Unique identifier of the pot to unfreeze.
- **Requires:**
  - Function is called by the contract owner.

### `countPlayerReward(uint256 _potId, uint256 participantIndex)`

- **Description:** Retrieves the accumulated reward of a participant in a pot.
- **Parameters:**
  - `_potId`: Unique identifier of the pot.
  - `participantIndex`: Index of the participant in the pot.
- **Returns:** Accumulated reward of the participant.

### `getPotParticipants(uint256 _potId)`

- **Description:** Retrieves the list of participants in a pot.
- **Parameters:**
  - `_potId`: Unique identifier of the pot.
- **Returns:** Array of participant structures.

### `getPotBalance(uint256 _potId)`

- **Description:** Retrieves the current balance of a pot.
- **Parameters:**
  - `_potId`: Unique identifier of the pot.
- **Returns:** Current balance of the pot.

## Usage

The PotGame smart contract allows users to create and join pots, participate in a reward distribution game, and manage the blacklist of users. It provides transparency and fairness in the distribution of rewards among participants.



For questions or issues, please contact [Your Email].
