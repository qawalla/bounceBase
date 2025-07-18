# 🗳️ BounceVote Smart Contract

BounceVote is a lightweight, flexible, and secure on-chain voting system built on the Base Network, powered by the QWLA token. This smart contract allows verified wallet holders to create polls, vote using their QWLA balance, and manage governance activities in a decentralized and transparent manner.

## 🚀 Features

- ✅ Token-gated voting (requires holding QWLA)
- 🗳️ Poll creation with 1–5 custom options
- ➕ Dynamic option addition post-creation
- 🔒 One-vote-per-wallet enforcement
- ⚙️ Whitelisted admin control for poll creation
- 📊 Transparent vote tracking
- 📡 On-chain results and event emissions

## 🔧 Requirements

- Solidity ^0.8.0
- Deployed on Base (or EVM-compatible) network
- QWLA Token Contract Address

## 📄 Contract Overview

### `createPoll(string name, string[5] options, uint optionCount, uint minQWLAHeld)`

Creates a new poll.  
- `name`: The title of the poll.  
- `options`: Text values for each option (up to 5).  
- `optionCount`: Must be between 1 and 5.  
- `minQWLAHeld`: Minimum QWLA tokens required to vote.

### `addOption(uint pollId, string option)`

Adds a new text option to an existing poll.  
- Only allowed if current `optionCount < 5`.

### `vote(uint pollId, uint option)`

Casts a vote for a given option index.  
- One vote per wallet per poll.  
- QWLA balance must meet or exceed `minQWLAHeld`.

### `closePoll(uint pollId)`

Closes a poll and locks voting.  
- Can only be called by the poll creator or a whitelisted address.

### `addToWhitelist(address user)`

Adds an address to the list of whitelisted poll creators.

## 📦 Events

- `PollCreated(uint pollId, address creator, string name)`
- `OptionAdded(uint pollId, string option)`
- `Voted(uint pollId, address voter, uint option)`
- `PollClosed(uint pollId, uint result)`

## 🔐 Access Control

- **Contract Owner**: Can whitelist users
- **Whitelisted Users**: Can create polls
- **Poll Creators**: Can add options and close their polls

## 🧪 Example Usage

```solidity
// Create a poll with 2 options
string[5] memory options = ["Yes", "No"];
createPoll("Should we list a new token?", options, 2, 1);

// Add an option later
addOption(0, "Abstain");

// Vote for option 1
vote(0, 1);
