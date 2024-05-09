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
        address foundationOwnerAddress;
    }

    struct ContractAddress {
        address contractAddress;
    }

    address private kindlinkAddress;
    mapping(address => FoundationCandidate) public candidates;
    // address is foundationAddress
    mapping(address => ListedFoundation) public foundations;
    // address is contractAddress
    mapping(address => mapping(address => VotedFoundation)) public isVoted;
    // first address is EOA, second address is foundationOwnerAddress
    mapping(address => uint256) public totalUsersDonations;

    event AddCandidates(
        address indexed sender,
        address indexed foundationAddress
    );
    event Vote(
        address indexed sender,
        address indexed candidateAddress,
        bool vote
    );
    event WithdrawalRequest(
        address indexed sender,
        address indexed foundationAddress
    );
    event ConfirmCandidateApproval(address indexed foundation);
    event ConfirmCandidateDisapproval(address indexed foundation);
    event Donate(
        address indexed sender,
        address indexed foundation,
        uint256 value
    );
    event Withdrawal(
        address indexed sender,
        address indexed foundationAddress,
        uint256 value
    );
    event ApproveWithdrawal(
        address indexed sender,
        address indexed foundationAddress
    );

    constructor() {
        kindlinkAddress = msg.sender;
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
        candidates[foundationOwnerAddress] = FoundationCandidate(
            foundationOwnerAddress,
            foundationCoOwnerAddress,
            block.timestamp + 3 days,
            0,
            0,
            block.timestamp
        );

        emit AddCandidates(msg.sender, foundationOwnerAddress);
    }

    function vote(bool inputVote, address foundationOwnerAddress) external {
        FoundationCandidate storage candidate = candidates[
            foundationOwnerAddress
        ];
        require(
            totalUsersDonations[msg.sender] >= 1 ether,
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        require(
            candidate.endVotingTime < block.timestamp,
            "Voting period has ended"
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

        isVoted[foundationOwnerAddress][msg.sender] = VotedFoundation(
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
                foundationOwnerAddress
            );

            delete candidates[foundationOwnerAddress];

            emit ConfirmCandidateApproval(address(newFoundation));

            return address(newFoundation);
        } else {
            delete candidates[foundationOwnerAddress];
            emit ConfirmCandidateDisapproval(foundationOwnerAddress);
        }
    }

    function donate(address foundationAddress) external payable {
        ListedFoundation storage foundation = foundations[foundationAddress];
        require(
            foundation.foundationOwnerAddress != address(0),
            "Foundation has not been registered"
        );
        (bool sent, ) = foundation.foundationOwnerAddress.call{
            value: msg.value
        }("");
        require(sent, "Donation Failed");
        totalUsersDonations[msg.sender] += msg.value;

        emit Donate(msg.sender, foundation.foundationOwnerAddress, msg.value);
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
        ContractAddress[] calldata contractAddresses
    ) external view returns (FoundationCandidateWithVote[] memory) {
        uint256 numCandidates = contractAddresses.length;
        FoundationCandidateWithVote[]
            memory result = new FoundationCandidateWithVote[](numCandidates);

        for (uint256 i = 0; i < numCandidates; i++) {
            address candidateAddress = contractAddresses[i].contractAddress;

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

    // KINDLINK DELEGATE FUNCTION TO FOUNDATION
    function delegateWithdrawal(address foundationAddress) external {
        ListedFoundation storage foundation = foundations[foundationAddress];
        FoundationInterface FoundationContract = FoundationInterface(
            foundationAddress
        );
        require(
            msg.sender == foundation.foundationOwnerAddress,
            "Function was not called by dedicated withdrawal address"
        );
        require(
            FoundationContract.isRequestWithdrawal(),
            "There is no withdrawal request yet"
        );

        FoundationContract.withdraw();

        emit Withdrawal(
            msg.sender,
            foundationAddress,
            foundationAddress.balance
        );
    }

    function delegateWithdrawalRequest(
        address foundationOwnerAddress
    ) external {
        ListedFoundation storage foundation = foundations[
            foundationOwnerAddress
        ];
        FoundationInterface FoundationContract = FoundationInterface(
            foundationOwnerAddress
        );
        require(
            msg.sender == foundation.foundationOwnerAddress,
            "Function was not called by dedicated withdrawal address"
        );

        FoundationContract.requestWithdrawal();

        emit WithdrawalRequest(msg.sender, foundationOwnerAddress);
    }

    function delegateApprove(address foundationOwnerAddress) external {
        ListedFoundation storage foundation = foundations[
            foundationOwnerAddress
        ];
        FoundationInterface FoundationContract = FoundationInterface(
            foundationOwnerAddress
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
