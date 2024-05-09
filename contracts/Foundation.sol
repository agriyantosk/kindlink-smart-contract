// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Foundation {
    address public kindlinkAddress;
    address public foundationOwnerAddress;
    address public foundationCoOnwerWithdrawalAddress;
    bool public isRequestWithdrawal = false;
    mapping(address => bool) public hasApproved;
    uint256 public approvalRequirement = 3;
    uint256 public approval;

    constructor(
        address _foundationOwnerAddress,
        address _foundationCoOnwerWithdrawalAddress
    ) {
        kindlinkAddress = msg.sender;
        foundationOwnerAddress = _foundationOwnerAddress;
        foundationCoOnwerWithdrawalAddress = _foundationCoOnwerWithdrawalAddress;
        hasApproved[msg.sender] = false;
        hasApproved[_foundationOwnerAddress] = false;
        hasApproved[_foundationCoOnwerWithdrawalAddress] = false;
    }

    function requestWithdrawal() external onlyFoundationOwner {
        require(
            msg.sender == foundationOwnerAddress,
            "Only Foundation Withdrawal Address Can Request for Withdrawal"
        );
        isRequestWithdrawal = true;
    }

    function approve() external {
        require(
            isRequestWithdrawal,
            "No withdrawal request available to be approve"
        );
        require(
            !hasApproved[msg.sender],
            "You already approved the withdrawal"
        );
        if (
            msg.sender == kindlinkAddress ||
            msg.sender == foundationOwnerAddress ||
            msg.sender == foundationCoOnwerWithdrawalAddress
        ) {
            approval += 1;
        }
        hasApproved[msg.sender] = true;
    }

    function withdraw() external onlyFoundationOwner {
        require(
            approval == approvalRequirement,
            "You haven't met the approval requirements yet"
        );
        require(
            msg.sender == foundationOwnerAddress,
            "Invalid withdrawal address"
        );
        uint256 contractBalance = address(this).balance;
        (bool sent, ) = foundationOwnerAddress.call{value: contractBalance}("");
        require(sent, "Withdrawal Failed");
        hasApproved[kindlinkAddress] = false;
        hasApproved[foundationOwnerAddress] = false;
        hasApproved[foundationCoOnwerWithdrawalAddress] = false;
    }

    modifier onlyFoundationOwner() {
        require(
            msg.sender == foundationOwnerAddress,
            "Only foundation owner can call this function"
        );
        _;
    }

    receive() external payable {}
}
