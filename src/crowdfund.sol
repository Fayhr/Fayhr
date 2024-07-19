// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Fayhr is ReentrancyGuard {
    address payable private admin;
    uint256 public nextCrowdfundId;
    bool public isActive;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => CrowdfundType) public crowdfundTypes;
    mapping(uint256 => mapping(address => uint256)) public contributions;

    enum Authorization {
        inactive,
        active,
        cancel
    }

    struct CrowdfundType {
        uint256 id;
        string name;
        uint256 requiredYesVotes;
        uint256 availableYesVotes;
        uint256 slot;
        uint256 startTime;
        uint256 endTime;
        uint256 softCap;
        uint256 hardCap;
        uint256 totalContributed;
        Authorization authorization;
        bool closed;
        bool pollClosed;
    }

    event PollCreated(uint256 id, string name);
    event CrowdfundAndPollDeleted(uint256 id);
    event CrowdfundStarted(
        uint256 id, uint256 slot, uint256 startTime, uint256 endTime, uint256 softCap, uint256 hardCap
    );
    event CrowdfundCreated(
        uint256 id, uint256 slot, uint256 startTime, uint256 endTime, uint256 softCap, uint256 hardCap
    );
    event EthDelegated(uint256 id, uint256 amount, uint256 slotUnit);
    event EthClaimed(uint256 id, uint256 amount);
    event CrowdfundCanceled(uint256 id);
    event CrowdfundWithdrawn(uint256 id, uint256 amount);
    event NonFunctionDeposit(address sender, uint256 amount);
    event ContractDeactivatedBy(address deactivator);
    event VotePlaced(address voter, bool vote);
    event DebugLog(string message, uint256 value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can use this function");
        _;
    }

    modifier onlyWhenActive() {
        require(isActive == true, "contract is inactive");
        _;
    }

    constructor(address _admin) {
        admin = payable(_admin);
        isActive = true;
    }

    function createPoll(uint256 crowdfundId, string memory _name, uint256 _requiredYesVotes, bool verdict)
        external
        onlyAdmin
        onlyWhenActive
    {
        require(crowdfundId > 0, "Invalid Crowdfund ID!");
        require(crowdfundTypes[crowdfundId].id == 0, "Crowdfund ID already exists!");
        uint256 newCrowdfundId = 0;
        if (crowdfundId == 1) {
            nextCrowdfundId = 1;
            newCrowdfundId = nextCrowdfundId;
            nextCrowdfundId++;
        } else if (crowdfundId > 0) {
            newCrowdfundId = nextCrowdfundId;
            nextCrowdfundId++;
        }

        CrowdfundType storage newCrowdfundType = crowdfundTypes[crowdfundId];
        newCrowdfundType.id = newCrowdfundId;
        newCrowdfundType.name = _name;
        newCrowdfundType.requiredYesVotes = _requiredYesVotes;
        newCrowdfundType.availableYesVotes = 0;
        newCrowdfundType.slot = 0;
        newCrowdfundType.startTime = 0;
        newCrowdfundType.endTime = 0;
        newCrowdfundType.softCap = 0;
        newCrowdfundType.hardCap = 0;
        newCrowdfundType.totalContributed = 0;
        newCrowdfundType.authorization = Authorization.inactive;
        newCrowdfundType.closed = verdict;
        newCrowdfundType.pollClosed = verdict;

        emit PollCreated(newCrowdfundId, _name);
    }

    function vote(uint256 crowdfundId, bool choice) external onlyWhenActive {
        require(crowdfundTypes[crowdfundId].pollClosed != true, "Poll Closed");
        require(crowdfundTypes[crowdfundId].id != 0, "Crowdfund Doesn't Exist!");
        require(!hasVoted[crowdfundId][msg.sender], "Already Voted");
        hasVoted[crowdfundId][msg.sender] = true;
        if (choice) {
            crowdfundTypes[crowdfundId].availableYesVotes++;
        }
        if (crowdfundTypes[crowdfundId].availableYesVotes == crowdfundTypes[crowdfundId].requiredYesVotes) {
            crowdfundTypes[crowdfundId].authorization = Authorization.active;
            crowdfundTypes[crowdfundId].closed = choice;
            crowdfundTypes[crowdfundId].pollClosed = choice;
            emit CrowdfundCreated(
                crowdfundId,
                crowdfundTypes[crowdfundId].slot,
                crowdfundTypes[crowdfundId].startTime,
                crowdfundTypes[crowdfundId].endTime,
                crowdfundTypes[crowdfundId].softCap,
                crowdfundTypes[crowdfundId].hardCap
            );
        } else {
            emit VotePlaced(msg.sender, choice);
        }
    }

    function deleteCrowdfundAndPoll(uint256 crowdfundId) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].id != 0, "Poll/Crowdfund Doesn't Exist");
        delete crowdfundTypes[crowdfundId];
        emit CrowdfundAndPollDeleted(crowdfundId);
    }

    function startCrowdfund(
        uint256 crowdfundId,
        uint256 _slot,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        bool verdict
    ) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].id != 0, "Crowdfund Doesn't Exist");
        require(_endTime > _startTime, "Endtime not > Starttime");
        require(crowdfundTypes[crowdfundId].authorization == Authorization.active, "Crowdfund Not Activated");
        crowdfundTypes[crowdfundId].slot = _slot;
        crowdfundTypes[crowdfundId].startTime = block.timestamp + _startTime;
        crowdfundTypes[crowdfundId].endTime = block.timestamp + _endTime;
        crowdfundTypes[crowdfundId].softCap = _softCap;
        crowdfundTypes[crowdfundId].hardCap = _hardCap;
        crowdfundTypes[crowdfundId].totalContributed = 0;
        crowdfundTypes[crowdfundId].closed = verdict; // verdict must be false
        emit CrowdfundStarted(crowdfundId, _slot, _startTime, _endTime, _softCap, _hardCap);
    }

    function delegateEth(uint256 crowdfundId, uint256 _slotUnit) external payable onlyWhenActive {
        require(
            crowdfundTypes[crowdfundId].authorization == Authorization.active && !crowdfundTypes[crowdfundId].closed,
            "Crowdfund not Active / Closed"
        );
        require(
            block.timestamp > crowdfundTypes[crowdfundId].startTime
                && block.timestamp < crowdfundTypes[crowdfundId].endTime,
            "Delegation Time Ended"
        );
        uint256 delegateAmount = crowdfundTypes[crowdfundId].slot * _slotUnit;
        require(delegateAmount % crowdfundTypes[crowdfundId].slot == 0, "Inappropriate Slot Unit");
        require(msg.value >= delegateAmount, "Incorrect ETH amount sent");
        crowdfundTypes[crowdfundId].totalContributed += delegateAmount;
        contributions[crowdfundId][msg.sender] += delegateAmount;
        if (crowdfundTypes[crowdfundId].totalContributed == crowdfundTypes[crowdfundId].hardCap) {
            bool verdict = true;
            crowdfundTypes[crowdfundId].closed = verdict;
        } else if (
            crowdfundTypes[crowdfundId].totalContributed > crowdfundTypes[crowdfundId].softCap
                && block.timestamp > crowdfundTypes[crowdfundId].endTime
        ) {
            bool verdict = true;
            crowdfundTypes[crowdfundId].closed = verdict;
        }
        emit EthDelegated(crowdfundId, delegateAmount, _slotUnit);
    }

    function claimEth(uint256 crowdfundId) external onlyWhenActive nonReentrant {
        if (
            crowdfundTypes[crowdfundId].totalContributed <= crowdfundTypes[crowdfundId].softCap
                && block.timestamp > crowdfundTypes[crowdfundId].endTime
        ) {
            crowdfundTypes[crowdfundId].closed = true;
        }
        require(crowdfundTypes[crowdfundId].closed, "Crowdfund Is Not Closed");
        require(
            crowdfundTypes[crowdfundId].totalContributed < crowdfundTypes[crowdfundId].softCap
                || crowdfundTypes[crowdfundId].authorization == Authorization.cancel,
            "Softcap Reached / Crowdfund Not Canceled"
        );
        uint256 claimAmount = contributions[crowdfundId][msg.sender];
        require(claimAmount != 0, "No Funds To Claim");
        contributions[crowdfundId][msg.sender] = 0;
        require(address(this).balance >= claimAmount, "No Funds Available");

        emit DebugLog("Claim Amount", claimAmount);
        emit DebugLog("Contract Balance", address(this).balance);

        address payable collector = payable(msg.sender);
        (bool success,) = collector.call{value: claimAmount}("");
        require(success, "Transfer Failed");

        emit EthClaimed(crowdfundId, claimAmount);
    }

    function cancelCrowdfund(uint256 crowdfundId) external onlyAdmin onlyWhenActive {
        bool verdict = true;
        crowdfundTypes[crowdfundId].closed = verdict;
        crowdfundTypes[crowdfundId].authorization = Authorization.cancel;
        emit CrowdfundCanceled(crowdfundId);
    }

    function restartCrowdfund(
        uint256 crowdfundId,
        uint256 _slot,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        bool verdict
    ) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].id != 0, "Crowdfund Doesn't Exist");
        require(crowdfundTypes[crowdfundId].totalContributed == 0, "Funds Not Claimed, Wait or Create New Entry");
        require(_endTime > _startTime, "Endtime not > Starttime");
        crowdfundTypes[crowdfundId].slot = _slot;
        crowdfundTypes[crowdfundId].startTime = block.timestamp + _startTime;
        crowdfundTypes[crowdfundId].endTime = block.timestamp + _endTime;
        crowdfundTypes[crowdfundId].softCap = _softCap;
        crowdfundTypes[crowdfundId].hardCap = _hardCap;
        crowdfundTypes[crowdfundId].closed = verdict; // verdict should be false
        emit CrowdfundStarted(crowdfundId, _slot, _startTime, _endTime, _softCap, _hardCap);
    }

    function restartCanceledCrowdfund(
        uint256 crowdfundId,
        uint256 _slot,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        bool verdict
    ) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].id != 0, "Crowdfund Doesn't Exist");
        require(crowdfundTypes[crowdfundId].totalContributed == 0, "Funds Not Claimed, Wait or Create New Entry");
        require(_endTime > _startTime, "Endtime not > Starttime");
        crowdfundTypes[crowdfundId].authorization = Authorization.active;
        crowdfundTypes[crowdfundId].slot = _slot;
        crowdfundTypes[crowdfundId].startTime = block.timestamp + _startTime;
        crowdfundTypes[crowdfundId].endTime = block.timestamp + _endTime;
        crowdfundTypes[crowdfundId].softCap = _softCap;
        crowdfundTypes[crowdfundId].hardCap = _hardCap;
        crowdfundTypes[crowdfundId].closed = verdict; // verdict should be false
        emit CrowdfundStarted(crowdfundId, _slot, _startTime, _endTime, _softCap, _hardCap);
    }

    function withdrawCrowdfund(uint256 crowdfundId) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].closed, "Crowdfund Not Closed");
        require(crowdfundTypes[crowdfundId].authorization == Authorization.active, "Crowdfund Already Canceled");
        require(
            crowdfundTypes[crowdfundId].totalContributed > crowdfundTypes[crowdfundId].softCap
                || crowdfundTypes[crowdfundId].totalContributed == crowdfundTypes[crowdfundId].hardCap,
            "Delegate Caps Not Reached"
        );
        uint256 withdrawalAmount = crowdfundTypes[crowdfundId].totalContributed;
        crowdfundTypes[crowdfundId].totalContributed = 0;
        payable(msg.sender).transfer(withdrawalAmount);
        emit CrowdfundWithdrawn(crowdfundId, withdrawalAmount);
    }

    function deleteContract() external onlyAdmin onlyWhenActive {
        isActive = false;
        payable(admin).transfer(address(this).balance);
        emit ContractDeactivatedBy(msg.sender);
    }

    // Getter functions
    function getCrowdfund(uint256 crowdfundId) public view returns (CrowdfundType memory) {
        return crowdfundTypes[crowdfundId];
    }

    function getContribution(uint256 crowdfundId, address contributor) public view returns (uint256) {
        return contributions[crowdfundId][contributor];
    }

    function hasUserVoted(uint256 crowdfundId, address user) public view returns (bool) {
        return hasVoted[crowdfundId][user];
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    receive() external payable {
        emit NonFunctionDeposit(msg.sender, msg.value);
    }
}
