// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/CharacterNFT.sol";

contract DeployCharacterNFT is Script {
    function run() external {
        address vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
        address linkToken = 0x01be23585060835e02b77ef475b0cc51aa1e0709;
        bytes32 keyHash = 0x2ed0feb3e9a0ef0c55a16326cbb8ed4f7e8ed9b4be9c7c2ab153a02bf8f8a5e8;
        uint256 fee = 0.1 * 10 ** 18;

        vm.startBroadcast();
        new CharacterNFT(vrfCoordinator, linkToken, keyHash, fee);
        vm.stopBroadcast();
    }
}
