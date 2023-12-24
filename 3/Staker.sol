// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

enum Tier {
    TIER1,
    TIER2,
    TIER3
}

contract NFTPrizes is ERC721 {
    address owner;

    uint lastTokenId = 0;

    mapping(uint => Tier) public tokenTiers;

    constructor() ERC721("Staker", "STK") {
        owner = msg.sender;
    }

    function mint(Tier tier, address to) public {
        require(msg.sender == owner, "Not allowed");
        _safeMint(to, lastTokenId);
        tokenTiers[lastTokenId] = tier;
        lastTokenId++;
    }
}

contract Staker {
    mapping(address => uint) public balances;
    address[] stakers;
    uint collected = 0;

    uint deadline;
    uint threshold;

    address payable externalContract;

    bool isOpen = true;
    bool isSuccessful = false;

    NFTPrizes public prizes;

    constructor(
        uint _threshold,
        address payable _externalContract,
        uint _deadline
    ) {
        threshold = _threshold;
        externalContract = _externalContract;
        deadline = _deadline;
        prizes = new NFTPrizes();
    }

    function stake() external payable {
        require(
            !shouldBeClosed(),
            "Contract will be closed soon, cannot stake."
        );
        require(isOpen, "Contract is closed.");
        require(msg.value > 0, "0 money.");

        if (balances[msg.sender] == 0) {
            stakers.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
        collected += msg.value;
    }

    function withdraw() external {
        require(!isOpen && !isSuccessful, "Cannot withdraw money.");

        uint balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function sendToExternal() external {
        require(
            !shouldBeClosed(),
            "Contract will be closed soon, cannot send."
        );
        require(isOpen, "Contract is closed.");
        require(collected >= threshold, "Not enough money collected.");

        complete(true);
        externalContract.transfer(collected);
        sendPrizes();
    }

    function closeContractUnsuccessfully() public {
        if (shouldBeClosed()) complete(false);
    }

    function shouldBeClosed() public view returns (bool) {
        return deadline < block.timestamp && collected < threshold;
    }

    function complete(bool success) private {
        isOpen = false;
        isSuccessful = success;
    }

    function sendPrizes() private {
        for (uint i = 0; i < stakers.length; i++) {
            if (balances[stakers[i]] > threshold / 10) {
                prizes.mint(Tier.TIER1, stakers[i]);
            } else if (balances[stakers[i]] > threshold / 100) {
                prizes.mint(Tier.TIER2, stakers[i]);
            } else {
                prizes.mint(Tier.TIER3, stakers[i]);
            }
        }
    }
}
