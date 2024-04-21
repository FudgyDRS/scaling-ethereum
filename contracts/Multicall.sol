// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// halfarse gas inefficent multicall, cause the multicall3 is garbo
contract Multicall {
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
