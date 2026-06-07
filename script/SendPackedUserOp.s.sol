// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

using MessageHashUtils for bytes32;

contract SendPackedUserOp is Script {

    function run() public {

    }

    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config) view public returns(PackedUserOperation memory) {
        // 1. generate the unsigned data
        uint256 nonce = vm.getNonce(config.account);
        PackedUserOperation memory UserOp = _generateUnsignedUserOperation(callData, config.account, nonce);

        //2. Get the userOp Hash
        bytes32 UserOpHash = IEntryPoint(config.entryPoint).getUserOpHash(UserOp);
        bytes32 digest = UserOpHash.toEthSignedMessageHash();


        // 3. sign it, and return it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        

        UserOp.signature = abi.encodePacked( r, s, v);
        return UserOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce) internal pure returns(PackedUserOperation memory) {
        
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint256 maxPriorityFeePerGas = 256;
        uint256 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation ({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
                paymasterAndData: hex"",
                signature: hex""
        });
    }

}
