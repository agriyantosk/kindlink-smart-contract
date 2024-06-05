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

    function requestWithdrawal() external onlyOwner {
        isRequestWithdrawal = true;
    }

    function approve(address callerAddress) external {
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

    function withdraw() external onlyOwner {
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
        approval = 0;
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

    modifier onlyOwner() {
        require(
            msg.sender == foundationOwnerAddress,
            "Function was not called by dedicated withdrawal address"
        );
        _;
    }

    receive() external payable {}
}
