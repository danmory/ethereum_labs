// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Crowdsale {
    address payable public owner;

    uint256 public deadline;
    ERC20 reward;
    uint256 weiPerToken = 1000;
    uint256 hardcap = 0.1 ether;

    mapping(address => uint256) public participantPayment;

    uint256 public mintedDuringSale;
    address[] teamMembers;

    constructor(uint256 _duration, address _rewardTokenAddress, address[] memory _members) {
        deadline = block.timestamp + _duration;
        owner = payable(msg.sender);
        reward = ERC20(_rewardTokenAddress);
        teamMembers = _members;
    }

    modifier isActive() {
        require(block.timestamp < deadline, "crowdsale finished");
        _;
    }

    receive() external payable isActive {
        require(participantPayment[msg.sender] + msg.value <= hardcap, "cannot deposit more than 0.1 ether");
        participantPayment[msg.sender] += msg.value;

        owner.transfer(msg.value);

        uint256 rewardValue = msg.value / weiPerToken;
        mintedDuringSale += rewardValue;
        reward.mint(msg.sender, rewardValue);
    }

    function rewardTeam() external {
        require(mintedDuringSale > 0, "no tokens left");
        require(block.timestamp > deadline, "too early");

        uint256 memberReward = (mintedDuringSale / 10) / teamMembers.length;
        mintedDuringSale = 0;
        for (uint256 i = 0; i < teamMembers.length; i++){
            reward.mint(teamMembers[i], memberReward);
        }
    }
}
