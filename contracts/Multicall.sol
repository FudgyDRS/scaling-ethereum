// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol";

// halfarse gas inefficent multicall, cause the multicall3 is garbo
contract Multicall {
    /// @notice RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable verifier;
    /// @notice Image ID of the only zkVM binary to accept verification from.
    bytes32 public constant imageId = ImageID.IS_CANONICAL_ID;

    /// @notice Initialize the contract, binding it to a specified RISC Zero verifier.
    constructor(IRiscZeroVerifier _verifier) {
        verifier = _verifier;
    }

    /// @notice Set the even number stored on the contract. Requires a RISC Zero proof that the number is even.
    function set(
        bytes calldata input,
        bytes32 postStateDigest,
        bytes calldata seal
    ) public {
        // Construct the expected journal data. Verify will fail if journal does not match.
        bytes memory journal = abi.encode(input);
        require(
            verifier.verify(seal, imageId, postStateDigest, sha256(journal))
        );
    }

    struct Call {
        address target;
        bytes callData;
    }

    struct Call2 {
        address target;
        bool success;
        bool isStatic;
        uint256 value;
        bytes callData;
    }

    struct Call3 {
        address target;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function multicallView(
        Call[] calldata calls
    ) public view returns (Result[] memory) {
        Result[] memory results = new Result[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            (results[i].success, results[i].returnData) = calls[i]
                .target
                .staticcall(calls[i].callData);
        }

        return results;
    }

    function multicallExecute(
        Call2[] calldata calls
    ) public payable returns (Result[] memory) {
        uint256 value = msg.value;
        Result[] memory results = new Result[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            if (calls[i].isStatic)
                (results[i].success, results[i].returnData) = calls[i]
                    .target
                    .staticcall(calls[i].callData);
            else {
                require(value >= calls[i].value);
                value -= calls[i].value;
                (results[i].success, results[i].returnData) = calls[i]
                    .target
                    .call{value: calls[i].value}(calls[i].callData);
            }
            if (calls[i].success) require(results[i].success == true);
        }

        payable(msg.sender).call{value: address(this).balance}("");

        return results;
    }

    function multicallExecuteAll(
        Call3[] calldata calls
    ) public payable returns (Result[] memory) {
        Result[] memory results = new Result[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            (results[i].success, results[i].returnData) = calls[i].target.call{
                value: calls[i].value
            }(calls[i].callData);
        }

        payable(msg.sender).call{value: address(this).balance}("");

        return results;
    }

    function getExtcodesize(
        address address_
    ) public view returns (uint256 size_) {
        assembly {
            size_ := extcodesize(address_)
        }
    }

    function at(address _addr) public view returns (bytes memory o_code) {
        assembly {
            let size := extcodesize(_addr)
            o_code := mload(0x40)
            mstore(
                0x40,
                add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(o_code, size)
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

    receive() external payable {}
}
