// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Student {
    uint16 id;
    uint8 age;
    string name;
}

contract UniversityGroup {
    address owner;
    Student[] public students;
    string[] public groups;
    mapping(uint16 => string) public studentToGroup;
    uint16 nextID = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
       require(msg.sender == owner);
       _;
    }

    function randomGroupNumber() public view returns (uint random) {
        random = uint(keccak256(abi.encodePacked(block.timestamp))) % groups.length;
    }

    function add(string calldata name, uint8 age) external {
        require(groups.length > 0, "No groups yet.");
        require(age >= 16, "Too young.");
        require(age < 100, "Too old.");
        Student memory student = Student(nextID, age, name);
        students.push(student);
        studentToGroup[nextID] = groups[randomGroupNumber()];
        nextID++;
    }

    function addGroup(string calldata name) external onlyOwner{
        groups.push(name);
    }
}