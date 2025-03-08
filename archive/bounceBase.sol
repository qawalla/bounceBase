// SPDX-License-Identifier: MIT

// ________  __      __.____       _____   
// \_____  \/  \    /  \    |     /  _  \  
//  /  / \  \   \/\/   /    |    /  /_\  \ 
// /   \_/.  \        /|    |___/    |    \
// \_____\ \_/\__/\  / |_______ \____|__  /
//        \__>     \/          \/       \/ v2



pragma solidity ^0.8.0;

interface IQWLAToken {
    function balanceOf(address owner) external view returns (uint);
}

contract BounceVote {
    IQWLAToken public qawlaToken;
    address public owner;
    mapping(address => bool) public whitelist;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => Poll) public polls;
    uint public pollCount;

    struct Poll {
        uint id;
        string name;
        address creator;
        string[5] options;
        uint optionCount;
        uint minQWLAHeld;
        uint voteCount;
        bool isOpen;
        mapping(uint => uint) votes;
    }

    event PollCreated(uint pollId, address creator, string name);
    event Voted(uint pollId, address voter, uint option);
    event PollClosed(uint pollId, uint result);

    constructor(address tokenAddress) {
        qawlaToken = IQWLAToken(tokenAddress);
        owner = msg.sender;
        whitelist[owner] = true;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    function addToWhitelist(address user) public {
        require(msg.sender == owner, "Only owner can add to whitelist");
        whitelist[user] = true;
    }

    function createPoll(string memory name, string[5] memory options, uint optionCount, uint minQWLAHeld) public onlyWhitelisted returns (uint) {
        require(optionCount >= 2 && optionCount <= 5, "Option count must be between 2 and 5");
        uint pollId = pollCount++;
        Poll storage newPoll = polls[pollId];
        newPoll.id = pollId;
        newPoll.name = name;
        newPoll.creator = msg.sender;
        newPoll.minQWLAHeld = minQWLAHeld > 0 ? minQWLAHeld : 1;
        newPoll.isOpen = true;
        for (uint i = 0; i < optionCount; i++) {
            newPoll.options[i] = options[i];
        }
        newPoll.optionCount = optionCount;
        emit PollCreated(pollId, msg.sender, name);
        return pollId;
    }

    function vote(uint pollId, uint option) public {
        require(polls[pollId].isOpen, "Poll is closed");
        require(!hasVoted[pollId][msg.sender], "Already voted");
        require(qawlaToken.balanceOf(msg.sender) >= polls[pollId].minQWLAHeld, "Not enough QWLA tokens");
        require(option >= 0 && option < polls[pollId].optionCount, "Invalid option");
        hasVoted[pollId][msg.sender] = true;
        polls[pollId].votes[option]++;
        polls[pollId].voteCount++;
        emit Voted(pollId, msg.sender, option);
    }

    function closePoll(uint pollId) public {
        require(msg.sender == polls[pollId].creator || whitelist[msg.sender], "Unauthorized");
        polls[pollId].isOpen = false;
        emit PollClosed(pollId, polls[pollId].voteCount);
    }
}
