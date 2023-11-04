# PotFighter Smart Contract Documentation

## Overview

The PotFighter smart contract is a decentralized application built on the Ethereum blockchain that enables users to create and join pots by paying participation fees. The contract manages the distribution of rewards among participants and includes features like user blacklisting and freezing pots. This documentation provides a comprehensive understanding of the contract's structure, functions, and usage.

- **Contract Name:** PotFighter
- **SPDX-License-Identifier:** MIT
- **Solidity Version:** 0.8.9

## Structures

### Participant

- **struct participant**
  - `userAddress`: The Ethereum address of the participant.
  - `startedAt`: The timestamp when the participant joined the pot.
  - `endedAt`: The timestamp when the participant left the pot.
  - `durationPlayed`: The total duration (in seconds) the participant played in the pot.
  - `reward`: The accumulated reward earned per 0.001 of the pot balance per second.
  - `rewardCollected`: A flag to monitor whether the user has collected their reward.

### Pot

- **struct Pot**
  - `creator`: The Ethereum address of the pot creator.
  - `potBalance`: The total balance of the pot.
  - `participants`: An array of participants in the pot.
  - `claimingActive`: A flag to determine if reward claiming is active.
  - `isEnded`: A flag indicating the status of the pot (running or ended).
  - `participationFee`: The participation fee required to join the pot.
  - `beginning`: The timestamp when the pot was created.
  - `lifeTime`: The duration of the pot in seconds.

## Constructor

### `constructor()`

- **Description:** Initializes the contract and sets the contract deployer as the owner.

## Modifiers

### `modifier potFreezed(uint256 _potId)`

- **Description:** Ensures that the specified pot is not frozen, allowing participation.

### `modifier userBlackListed()`

- **Description:** Checks if the user executing the function is not blacklisted.

## Functions

### `createPot()`

- **Description:** Allows users to create a new pot by paying a participation fee.
- **Requires:**
  - User is not blacklisted.
  - Sent value equals `potFee`.
- **Effects:**
  - Creates a new pot.
  - Adds the sender as the pot creator and a participant.
  - Initializes timestamps and rewards.

### `joinPot(uint256 _potId)`

- **Description:** Allows users to join an existing pot by paying a participation fee.
- **Parameters:**
  - `_potId`: The unique identifier of the pot to join.
- **Requires:**
  - User is not blacklisted.
  - Sent value equals `participationFee`.
- **Effects:**
  - Updates pot data.
  - Distributes rewards among participants.
  - Distributes fees to the pot owner, participants, and the development team.

<!-- Continue this Markdown structure for other functions -->

## Usage

The PotFighter smart contract provides a platform for creating and participating in pots, allowing users to engage in a reward distribution game. It offers a fair and transparent system for distributing rewards among participants. Users can also manage blacklisted users and freeze/unfreeze pots to control participation.

For questions or issues, please contact [anwardev69@gmail.com].

Please note that this documentation is for educational purposes, and you should conduct a thorough code review and testing before deploying the contract in a production environment.
