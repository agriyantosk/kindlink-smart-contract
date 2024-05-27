// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {Foundation} from "./Foundation.sol";

interface FoundationInterface {
    function withdraw() external;

    function requestWithdrawal() external;

    function approve() external;

    function isRequestWithdrawal() external returns (bool);
}

contract Kindlink {
    struct FoundationCandidate {
        address foundationOwnerAddress;
        address foundationCoOwnerAddress;
        uint256 endVotingTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 createdAt;
    }

    struct VotedFoundation {
        address foundationOwnerAddress;
        bool isVoted;
    }

    struct FoundationCandidateWithVote {
        address foundationOwnerAddress;
        address foundationCoOwnerAddress;
        uint256 endVotingTime;
        uint256 createdAt;
        uint256 yesVotes;
        uint256 noVotes;
        bool hasVoted;
    }

    struct ListedFoundation {
        address contractAddress;
        address foundationOwnerAddress;
        address foundationCoOwnerAddress;
        uint256 totalInvolvedParticipants;
        uint256 endVotingTime;
    }

    address private kindlinkAddress;
    mapping(address => FoundationCandidate) public candidates;
    // address is foundationAddress
    mapping(address => ListedFoundation) public foundations;
    // address is contractAddress
    mapping(address => bool) private isRegisteredAddress;
    mapping(address => mapping(address => VotedFoundation)) public isVoted;
    // first address is EOA, second address is foundationOwnerAddress
    mapping(address => uint256) public totalUsersDonations;

    event AddCandidates(
        address indexed from,
        address indexed foundationOwnerAddress
    );
    event Vote(
        address indexed from,
        address indexed candidateOwnerAddress,
        bool vote
    );
    event WithdrawalRequest(
        address indexed from,
        address indexed contractAddress
    );
    event WinsVote(address indexed contractAddress);
    event LoseVote(address indexed foundationOwnerAddress);
    event Donate(
        address indexed from,
        address indexed contractAddress,
        uint256 value
    );
    event Withdrawal(
        address indexed from,
        address indexed contractAddress,
        uint256 value
    );
    event ApproveWithdrawal(
        address indexed from,
        address indexed contractAddress
    );

    constructor(
        address listedFoundationContractAddress,
        address listedFoundationOwnerAddress,
        address listedFoundationCoOwnerAddress,
        address candidateFoundationOwnerAddress,
        address candidateFoundationCoOwnerAddress
    ) {
        kindlinkAddress = msg.sender;
        candidates[candidateFoundationOwnerAddress] = FoundationCandidate(
            candidateFoundationOwnerAddress,
            candidateFoundationCoOwnerAddress,
            block.timestamp + 3 days,
            0,
            0,
            block.timestamp
        );
        foundations[listedFoundationContractAddress] = ListedFoundation(
            listedFoundationContractAddress,
            listedFoundationOwnerAddress,
            listedFoundationCoOwnerAddress,
            8,
            block.timestamp - 3 days
        );
    }

    // KINDLINK FUNCTIONS
    function addCandidates(
        address foundationOwnerAddress,
        address foundationCoOwnerAddress
    ) external onlyOwner {
        require(
            foundationOwnerAddress != address(0),
            "Not allowing users to send ether to 0 address"
        );
        require(
            foundationCoOwnerAddress != address(0),
            "Not allowing users to send ether to 0 address"
        );
        require(
            foundationOwnerAddress != foundationCoOwnerAddress,
            "Cannot submit the same address"
        );
        require(
            !isRegisteredAddress[foundationOwnerAddress] &&
                !isRegisteredAddress[foundationCoOwnerAddress],
            "This address has already been registered"
        );
        candidates[foundationOwnerAddress] = FoundationCandidate(
            foundationOwnerAddress,
            foundationCoOwnerAddress,
            block.timestamp + 3 days,
            0,
            0,
            block.timestamp
        );

        isRegisteredAddress[foundationOwnerAddress] = true;
        isRegisteredAddress[foundationCoOwnerAddress] = true;
        emit AddCandidates(msg.sender, foundationOwnerAddress);
    }

    function vote(bool inputVote, address foundationOwnerAddress) external {
        FoundationCandidate storage candidate = candidates[
            foundationOwnerAddress
        ];
        require(
            candidate.endVotingTime > block.timestamp,
            "Voting period has ended"
        );
        require(
            totalUsersDonations[msg.sender] >= 1 ether,
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        require(
            !isVoted[msg.sender][foundationOwnerAddress].isVoted,
            "You have already voted for this Foundation"
        );

        if (inputVote) {
            candidate.yesVotes++;
        } else {
            candidate.noVotes++;
        }

        isVoted[msg.sender][foundationOwnerAddress] = VotedFoundation(
            foundationOwnerAddress,
            true
        );

        emit Vote(msg.sender, foundationOwnerAddress, inputVote);
    }

    function approveCandidate(
        address foundationOwnerAddress
    )
        external
        checkFoundationCandidate(foundationOwnerAddress)
        onlyOwner
        returns (address)
    {
        if (countVote(foundationOwnerAddress)) {
            Foundation newFoundation = new Foundation(
                foundationOwnerAddress,
                candidates[foundationOwnerAddress].foundationCoOwnerAddress
            );

            foundations[address(newFoundation)] = ListedFoundation(
                address(newFoundation),
                candidates[foundationOwnerAddress].foundationOwnerAddress,
                candidates[foundationOwnerAddress].foundationCoOwnerAddress,
                candidates[foundationOwnerAddress].yesVotes +
                    candidates[foundationOwnerAddress].noVotes,
                candidates[foundationOwnerAddress].endVotingTime
            );

            delete candidates[foundationOwnerAddress];

            emit WinsVote(address(newFoundation));

            return address(newFoundation);
        } else {
            delete isRegisteredAddress[
                candidates[foundationOwnerAddress].foundationOwnerAddress
            ];
            delete isRegisteredAddress[
                candidates[foundationOwnerAddress].foundationCoOwnerAddress
            ];
            delete candidates[foundationOwnerAddress];
            emit LoseVote(foundationOwnerAddress);
        }
    }

    function donate(address contractAddress) external payable {
        ListedFoundation storage foundation = foundations[contractAddress];
        require(
            foundation.foundationOwnerAddress != address(0),
            "Foundation has not been registered"
        );
        (bool sent, ) = contractAddress.call{value: msg.value}("");
        require(sent, "Donation Failed");
        totalUsersDonations[msg.sender] += msg.value;

        emit Donate(msg.sender, foundation.contractAddress, msg.value);
    }

    // KINDLINK MODIFIER FUNCTION
    function countVote(address withdrawalAddress) private view returns (bool) {
        FoundationCandidate storage candidate = candidates[withdrawalAddress];
        uint256 yesCount = candidate.yesVotes;
        uint256 noCount = candidate.noVotes;

        if (yesCount > noCount) {
            return true;
        } else {
            return false;
        }
    }

    function candidateExists(
        address foundationOwnerAddress
    ) internal view returns (bool) {
        return
            candidates[foundationOwnerAddress].foundationOwnerAddress !=
            address(0);
    }

    // KINDLINK GETTER FUNCTION
    function getAllCandidatesWithVotes(
        address userAddress,
        address[] calldata contractAddresses
    ) external view returns (FoundationCandidateWithVote[] memory) {
        uint256 numCandidates = contractAddresses.length;
        FoundationCandidateWithVote[]
            memory result = new FoundationCandidateWithVote[](numCandidates);

        for (uint256 i = 0; i < numCandidates; i++) {
            address candidateAddress = contractAddresses[i];

            require(
                candidateExists(candidateAddress),
                "Candidate does not exist"
            );

            bool hasVoted = isVoted[userAddress][candidateAddress].isVoted;

            result[i] = FoundationCandidateWithVote(
                candidates[candidateAddress].foundationOwnerAddress,
                candidates[candidateAddress].foundationCoOwnerAddress,
                candidates[candidateAddress].endVotingTime,
                candidates[candidateAddress].createdAt,
                candidates[candidateAddress].yesVotes,
                candidates[candidateAddress].noVotes,
                hasVoted
            );
        }

        return result;
    }

    function getAllFoundationEndVoteTime(
        address[] calldata contractAddresses
    ) external view returns (ListedFoundation[] memory) {
        uint256 numFoundations = contractAddresses.length;
        ListedFoundation[] memory result = new ListedFoundation[](
            numFoundations
        );

        for (uint256 i = 0; i < numFoundations; i++) {
            address contractAddress = contractAddresses[i];

            result[i] = ListedFoundation(
                contractAddress,
                foundations[contractAddress].foundationOwnerAddress,
                foundations[contractAddress].foundationCoOwnerAddress,
                foundations[contractAddress].totalInvolvedParticipants,
                foundations[contractAddress].endVotingTime
            );
        }

        return result;
    }

    // KINDLINK DELEGATE FUNCTION TO FOUNDATION
    function delegateWithdrawalRequest(address contractAddress) external {
        ListedFoundation storage foundation = foundations[contractAddress];
        require(
            foundation.foundationOwnerAddress != address(0),
            "Foundation is not registered!"
        );
        FoundationInterface FoundationContract = FoundationInterface(
            contractAddress
        );
        require(
            msg.sender == foundation.foundationOwnerAddress,
            "Function was not called by dedicated withdrawal address"
        );

        FoundationContract.requestWithdrawal();

        emit WithdrawalRequest(msg.sender, contractAddress);
    }

    function delegateWithdrawal(address contractAddress) external {
        ListedFoundation storage foundation = foundations[contractAddress];
        require(
            foundation.foundationOwnerAddress != address(0),
            "Foundation is not registered!"
        );
        FoundationInterface FoundationContract = FoundationInterface(
            contractAddress
        );
        require(
            msg.sender == foundation.foundationOwnerAddress,
            "Function was not called by dedicated withdrawal address"
        );

        FoundationContract.withdraw();

        emit Withdrawal(msg.sender, contractAddress, contractAddress.balance);
    }

    function delegateApprove(address contractAddress) external {
        ListedFoundation storage foundation = foundations[contractAddress];
        require(
            foundation.foundationOwnerAddress != address(0),
            "Foundation is not registered!"
        );
        FoundationInterface FoundationContract = FoundationInterface(
            contractAddress
        );
        require(
            msg.sender == foundation.foundationOwnerAddress ||
                msg.sender == foundation.foundationCoOwnerAddress ||
                msg.sender == kindlinkAddress,
            "Only foundation stakeholders can approve withdrawal reqeusts."
        );

        FoundationContract.approve();

        emit ApproveWithdrawal(msg.sender, foundation.foundationOwnerAddress);
    }

    modifier onlyOwner() {
        require(
            msg.sender == kindlinkAddress,
            "Only owner can call this function"
        );
        _;
    }

    modifier checkFoundationCandidate(address foundationOwnerAddress) {
        FoundationCandidate storage candidate = candidates[
            foundationOwnerAddress
        ];
        require(
            candidate.foundationOwnerAddress == foundationOwnerAddress,
            "Foundation Candidate not found"
        );
        _;
    }
}
