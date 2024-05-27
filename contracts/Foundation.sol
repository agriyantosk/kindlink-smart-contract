// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Foundation {
    struct ApprovalState {
        address contractAddress;
        bool isRequestWithdrawal;
        bool kindlinkApproval;
        bool foundationOwnerApproval;
        bool foundationCoOwnerApproval;
    }
    address public kindlinkAddress;
    address public foundationOwnerAddress;
    address public foundationCoOnwerAddress;
    bool public isRequestWithdrawal = false;
    mapping(address => bool) public hasApproved;
    uint256 public approvalRequirement = 3;
    uint256 public approval;

    constructor(
        address _foundationOwnerAddress,
        address _foundationCoOnwerAddress
    ) {
        kindlinkAddress = msg.sender;
        foundationOwnerAddress = _foundationOwnerAddress;
        foundationCoOnwerAddress = _foundationCoOnwerAddress;
        hasApproved[msg.sender] = false;
        hasApproved[_foundationOwnerAddress] = false;
        hasApproved[_foundationCoOnwerAddress] = false;
    }

    function requestWithdrawal() external onlyPlatform {
        isRequestWithdrawal = true;
    }

    function approve(address callerAddress) external onlyPlatform {
        require(
            isRequestWithdrawal,
            "No withdrawal request available to be approve"
        );
        require(
            !hasApproved[callerAddress],
            "You already approved the withdrawal"
        );
        if (
            callerAddress == kindlinkAddress ||
            callerAddress == foundationOwnerAddress ||
            callerAddress == foundationCoOnwerAddress
        ) {
            approval += 1;
        }
        hasApproved[msg.sender] = true;
    }

    function withdraw() external onlyPlatform {
        require(
            approval == approvalRequirement,
            "You haven't met the approval requirements yet"
        );

        uint256 contractBalance = address(this).balance;
        (bool sent, ) = foundationOwnerAddress.call{value: contractBalance}("");
        require(sent, "Withdrawal Failed");
        hasApproved[kindlinkAddress] = false;
        hasApproved[foundationOwnerAddress] = false;
        hasApproved[foundationCoOnwerAddress] = false;
    }

    // FOUNDATION GETTER FUNCTION
    function getApprovalState() external view returns (ApprovalState memory) {
        return
            ApprovalState(
                address(this),
                isRequestWithdrawal,
                hasApproved[kindlinkAddress],
                hasApproved[foundationOwnerAddress],
                hasApproved[foundationCoOnwerAddress]
            );
    }

    modifier onlyPlatform() {
        require(
            msg.sender == kindlinkAddress,
            "Withdrawal must be conducted through Kindlink Platform"
        );
        _;
    }

    receive() external payable {}
}
