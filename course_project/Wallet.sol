// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IERC1271.sol";

contract Wallet is Ownable, IERC1271, IERC721Receiver {
    mapping(address => bool) private trustedParties;
    uint256 private recoveryCounter;
    mapping(address => bool) private votedForRecovery;
    uint256 private constant recoveryThreshold = 2;

    event RecoveryInitiated();
    event TrustedPartyAdded(address indexed party);
    event TrustedPartyRemoved(address indexed party);
    event WeiSent(address indexed to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    modifier onlyTrustedParty() {
        require(trustedParties[msg.sender], "Not a trusted party");
        _;
    }

    function addTrustedParty(address _party) external onlyOwner {
        trustedParties[_party] = true;
        emit TrustedPartyAdded(_party);
    }

    function removeTrustedParty(address _party) external onlyOwner {
        trustedParties[_party] = false;
        emit TrustedPartyRemoved(_party);
    }

    function initiateRecovery() external onlyTrustedParty {
        require(recoveryCounter == 0, "Already initiated");

        votedForRecovery[msg.sender] = true;
        recoveryCounter = 1;

        emit RecoveryInitiated();
    }

    function approveRecovery() external onlyTrustedParty {
        require(recoveryCounter > 0, "Not started yet");
        require(!votedForRecovery[msg.sender], "Already voted");

        votedForRecovery[msg.sender] = true;

        recoveryCounter++;
    }

    function changeOwner(address _newOwner) external onlyTrustedParty {
        require(recoveryCounter >= recoveryThreshold, "Not enough votes");

        _transferOwnership(_newOwner);
        recoveryCounter = 0;
    }

    function sendWei(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit WeiSent(to, amount);
    }

    receive() external payable {}

    fallback() external payable {}

    function receiveTokens(
        address _tokenAddress,
        address _from,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_tokenAddress).transferFrom(_from, address(this), _amount);
    }

    function sendTokens(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function getTokenBalance(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function transferNFT(address _erc721Contract, address _to, uint256 _tokenId) external onlyOwner {
        IERC721(_erc721Contract).safeTransferFrom(address(this), _to, _tokenId);
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        external
        view
        override
        returns (bytes4)
    {
        if (ECDSA.recover(_hash, _signature) == owner()) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }
}
