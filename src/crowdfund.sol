// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Fayhr {
    IERC20 public token;
    address payable private admin;
    uint256 public nextCrowdfundId;
    bool public isActive;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => CrowdfundType) public crowdfundTypes;

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
        mapping(address => uint256) contributions;
    }

    event PollCreated(uint256 id, string name);
    event CrowdfundAndPollDeleted(uint256 id);
    event CrowdfundStarted(
        uint256 id, uint256 slot, uint256 startTime, uint256 endTime, uint256 softCap, uint256 hardCap
    );
    event CrowdfundCreated(
        uint256 id, uint256 slot, uint256 startTime, uint256 endTime, uint256 softCap, uint256 hardCap
    );
    event TokenDelegated(uint256 id, uint256 amount, uint256 slotUnit);
    event TokenClaimed(uint256 id, uint256 amount);
    event CrowdfundCanceled(uint256 id);
    event CrowdfundWithdrawn(uint256 id, uint256 amount);
    event nonFunctionDeposit(address sender, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can use this function");
        _;
    }

    modifier onlyWhenActive() {
        require(isActive == true, "contract is inactive");
        _;
    }

    constructor(address _admin, address tokenAddress) {
        admin = payable(_admin);
        token = IERC20(tokenAddress);
        isActive = true;
    }

    function createPoll(uint256 crowdfundId, string memory _name, uint256 _requiredYesVotes)
        external
        onlyAdmin
        onlyWhenActive
    {
        require(crowdfundTypes[crowdfundId].id == 0, "Crowdfund ID already exists!");
        uint256 newCrowdfundId = 0;
        if (crowdfundId == 1) {
            nextCrowdfundId = 1;
            newCrowdfundId = nextCrowdfundId;
            nextCrowdfundId++;
        } else if (crowdfundId > 1) {
            newCrowdfundId = nextCrowdfundId;
            nextCrowdfundId++;
        }
        CrowdfundType storage newCrowdfundType = crowdfundTypes[newCrowdfundId];
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
        newCrowdfundType.closed = false;
        newCrowdfundType.pollClosed = false;

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
        createCrowdfund(crowdfundId);
    }

    function createCrowdfund(uint256 crowdfundId) internal {
        if (crowdfundTypes[crowdfundId].availableYesVotes >= crowdfundTypes[crowdfundId].requiredYesVotes) {
            crowdfundTypes[crowdfundId].authorization = Authorization.active;
            crowdfundTypes[crowdfundId].closed = true;
            crowdfundTypes[crowdfundId].pollClosed = true;
            emit CrowdfundCreated(
                crowdfundId,
                crowdfundTypes[crowdfundId].slot,
                crowdfundTypes[crowdfundId].startTime,
                crowdfundTypes[crowdfundId].endTime,
                crowdfundTypes[crowdfundId].softCap,
                crowdfundTypes[crowdfundId].hardCap
            );
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
        uint256 _hardCap
    ) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].id != 0, "Crowdfund Doesn't Exist");
        require(_endTime > _startTime, "Endtime Must be Greater Than Starttime");
        require(crowdfundTypes[crowdfundId].authorization == Authorization.active, "Crowdfund Not Activated");
        crowdfundTypes[crowdfundId].slot = _slot;
        crowdfundTypes[crowdfundId].startTime = block.timestamp + _startTime;
        crowdfundTypes[crowdfundId].endTime = block.timestamp + _endTime;
        crowdfundTypes[crowdfundId].softCap = _softCap;
        crowdfundTypes[crowdfundId].hardCap = _hardCap;
        crowdfundTypes[crowdfundId].totalContributed = 0;
        crowdfundTypes[crowdfundId].closed = false;
        emit CrowdfundStarted(
            crowdfundId,
            _slot,
            crowdfundTypes[crowdfundId].startTime,
            crowdfundTypes[crowdfundId].endTime,
            _softCap,
            _hardCap
        );
    }

    function approveToken() external onlyWhenActive {
        require(token.approve(address(this), 1e15), "Token Approval Unsuccessful");
    }

    function deapproveToken() external onlyWhenActive {
        require(token.approve(address(this), 0), "Token Deapproval Unsuccessful");
    }

    function delegateToken(uint256 crowdfundId, uint256 _slotUnit) external onlyWhenActive {
        require(
            crowdfundTypes[crowdfundId].authorization == Authorization.active && !crowdfundTypes[crowdfundId].closed,
            "Crowdfund not Active or is Closed"
        );
        require(
            block.timestamp >= crowdfundTypes[crowdfundId].startTime
                && block.timestamp <= crowdfundTypes[crowdfundId].endTime,
            "Contribution Is Not Within the Allowed Timeframe"
        );
        uint256 delegateAmount = crowdfundTypes[crowdfundId].slot * _slotUnit;
        require(delegateAmount % crowdfundTypes[crowdfundId].slot == 0, "Inappropriate Slot Unit");
        require(token.balanceOf(msg.sender) >= delegateAmount, "Insufficient Token Balance");
        require(token.transferFrom(address(msg.sender), address(this), delegateAmount), "Contribution Failed");
        crowdfundTypes[crowdfundId].totalContributed += delegateAmount;
        crowdfundTypes[crowdfundId].contributions[msg.sender] += delegateAmount;
        if (crowdfundTypes[crowdfundId].totalContributed >= crowdfundTypes[crowdfundId].hardCap) {
            crowdfundTypes[crowdfundId].closed = true;
        } else if (
            crowdfundTypes[crowdfundId].totalContributed >= crowdfundTypes[crowdfundId].softCap
                && block.timestamp > crowdfundTypes[crowdfundId].endTime
        ) {
            crowdfundTypes[crowdfundId].closed = true;
        }
        emit TokenDelegated(crowdfundId, delegateAmount, _slotUnit);
    }

    function claimToken(uint256 crowdfundId) external onlyWhenActive {
        if (
            crowdfundTypes[crowdfundId].totalContributed < crowdfundTypes[crowdfundId].softCap
                && block.timestamp > crowdfundTypes[crowdfundId].endTime
        ) {
            crowdfundTypes[crowdfundId].closed = true;
        }
        require(crowdfundTypes[crowdfundId].closed, "Crowdfund Is Not Closed");
        require(
            crowdfundTypes[crowdfundId].totalContributed < crowdfundTypes[crowdfundId].softCap
                || crowdfundTypes[crowdfundId].authorization == Authorization.cancel,
            "Softcap Reached or Admin Hasn't Canceled Crowdfund"
        );
        uint256 claimAmount = crowdfundTypes[crowdfundId].contributions[msg.sender];
        require(claimAmount > 0, "No Contribution To Claim");
        crowdfundTypes[crowdfundId].contributions[msg.sender] = 0;
        require(token.transfer(address(msg.sender), claimAmount), "Claim Failed");
        emit TokenClaimed(crowdfundId, claimAmount);
    }

    function cancelCrowdfund(uint256 crowdfundId) external onlyAdmin onlyWhenActive {
        crowdfundTypes[crowdfundId].closed = true;
        crowdfundTypes[crowdfundId].authorization = Authorization.cancel;
        emit CrowdfundCanceled(crowdfundId);
    }

    function restartCanceledCrowdfund(
        uint256 crowdfundId,
        uint256 _slot,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap
    ) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].id != 0, "Crowdfund Doesn't Exist");
        require(
            crowdfundTypes[crowdfundId].totalContributed == 0,
            "Funds in this Crowdfund Have Not Been Fully Claimed Yet, Wait or Create Another Crowdfund"
        );
        require(_endTime > _startTime, "Endtime Must be Greater Than Starttime");
        crowdfundTypes[crowdfundId].authorization = Authorization.active;
        crowdfundTypes[crowdfundId].slot = _slot;
        crowdfundTypes[crowdfundId].startTime = block.timestamp + _startTime;
        crowdfundTypes[crowdfundId].endTime = block.timestamp + _endTime;
        crowdfundTypes[crowdfundId].softCap = _softCap;
        crowdfundTypes[crowdfundId].hardCap = _hardCap;
        crowdfundTypes[crowdfundId].closed = false;
        emit CrowdfundStarted(
            crowdfundId,
            _slot,
            crowdfundTypes[crowdfundId].startTime,
            crowdfundTypes[crowdfundId].endTime,
            _softCap,
            _hardCap
        );
    }

    function withdrawCrowdfund(uint256 crowdfundId) external onlyAdmin onlyWhenActive {
        require(crowdfundTypes[crowdfundId].closed, "Crowdfund Is Not Closed");
        require(
            crowdfundTypes[crowdfundId].authorization == Authorization.active, "Admin Already Canceled This Crowdfund"
        );
        require(
            crowdfundTypes[crowdfundId].totalContributed >= crowdfundTypes[crowdfundId].softCap
                || crowdfundTypes[crowdfundId].totalContributed >= crowdfundTypes[crowdfundId].hardCap,
            "None Of The Caps Have Been Reached"
        );
        uint256 withdrawalAmount = crowdfundTypes[crowdfundId].totalContributed;
        crowdfundTypes[crowdfundId].totalContributed = 0;
        require(token.transfer(address(msg.sender), withdrawalAmount), "Withdrawal Failed");
        emit CrowdfundWithdrawn(crowdfundId, withdrawalAmount);
    }

    receive() external payable {
        emit nonFunctionDeposit(msg.sender, msg.value);
    }

    function deleteContract() external onlyAdmin onlyWhenActive {
        isActive = false;
        require(token.transfer(address(msg.sender), token.balanceOf(address(this))), "Delete Withdrawal Unsuccessful");
        admin.transfer(address(this).balance);
    }
}
