// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Order {
  string A = "A";
  string B = "B";
  string C = "C";

  function functionA() public view returns(string memory) { return A;} // 9febadf2
  function functionB() public view returns(string memory) { return B;} // 93219fd1
  function functionC() public view returns(string memory) { return C;} // 6426dc6e
}