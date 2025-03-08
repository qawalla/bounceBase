// SPDX-License-Identifier: MIT


// ________  __      __.____       _____   
// \_____  \/  \    /  \    |     /  _  \  
//  /  / \  \   \/\/   /    |    /  /_\  \ 
// /   \_/.  \        /|    |___/    |    \
// \_____\ \_/\__/\  / |_______ \____|__  /
//        \__>     \/          \/       \/ v3


pragma solidity ^0.8.0;

// Interface to interact with the QWLA token contract
interface IQWLAToken {
    function balanceOf(address owner) external view returns (uint);
}

// BounceVote contract for creating and managing polls with dynamic option capabilities
contract BounceVote {
    IQWLAToken public qawlaToken;  // Token interface instance
    address public owner;          // Owner of the contract
    mapping(address => bool) public whitelist;  // Whitelisted addresses allowed to create polls
    mapping(uint => mapping(address => bool)) public hasVoted;  // Tracks whether an address has voted in a poll
    mapping(uint => Poll) public polls;  // Mapping of poll IDs to Poll structs
    uint public pollCount;  // Counter for polls to generate unique poll IDs

    // Structure to hold poll data
    struct Poll {
        uint id;
        string name;
        address creator;
        string[] options;  // Dynamic array for poll options
        uint minQWLAHeld;
        uint voteCount;
        bool isOpen;
        mapping(uint => uint) votes;  // Mapping from option index to vote count
    }

    // Events for logging actions on the blockchain
    event PollCreated(uint pollId, address creator, string name);
    event Voted(uint pollId, address voter, uint option);
    event PollClosed(uint pollId, uint result);

    // Constructor to set the QWLA token address and contract owner
    constructor(address tokenAddress) {
        qawlaToken = IQWLAToken(tokenAddress);
        owner = msg.sender;
        whitelist[owner] = true;  // Automatically whitelist the contract owner
    }

    // Modifier to restrict functions to whitelisted addresses
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    // Modifier to restrict functions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Function to add addresses to the whitelist
    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
    }

    // Function to create a new poll with initial options
    function createPoll(string memory name, string[] memory initialOptions, uint minQWLAHeld) public onlyWhitelisted returns (uint) {
        require(initialOptions.length >= 1 && initialOptions.length <= 5, "Option count must be between 1 and 5");
        uint pollId = pollCount++;
        Poll storage newPoll = polls[pollId];
        newPoll.id = pollId;
        newPoll.name = name;
        newPoll.creator = msg.sender;
        newPoll.minQWLAHeld = minQWLAHeld > 0 ? minQWLAHeld : 1;
        newPoll.isOpen = true;
        newPoll.options = initialOptions;
        emit PollCreated(pollId, msg.sender, name);
        return pollId;
    }

    // Function to add additional options to an existing poll
    function addOption(uint pollId, string memory option) public {
        require(msg.sender == polls[pollId].creator, "Only creator can add options");
        require(polls[pollId].options.length < 5, "Cannot add more than 5 options");
        polls[pollId].options.push(option);
    }

    // Function for voting on an option in a poll
    function vote(uint pollId, uint option) public {
        require(polls[pollId].isOpen, "Poll is closed");
        require(!hasVoted[pollId][msg.sender], "Already voted");
        require(qawlaToken.balanceOf(msg.sender) >= polls[pollId].minQWLAHeld, "Not enough QWLA tokens");
        require(option < polls[pollId].options.length, "Invalid option");
        hasVoted[pollId][msg.sender] = true;
        polls[pollId].votes[option]++;
        emit Voted(pollId, msg.sender, option);
    }

    // Function to close a poll and finalize the results
    function closePoll(uint pollId) public {
        require(msg.sender == polls[pollId].creator || whitelist[msg.sender], "Unauthorized");
        polls[pollId].isOpen = false;
        emit PollClosed(pollId, polls[pollId].voteCount);
    }
}
