pragma solidity ^0.4.18;

contract DToken {
    function mintable(address _to, uint _amount);
    function start();
    function getTotalSupply() returns(uint);
    function balanceOf(address _owner) returns(uint);
    function transfer(address _to, uint _amount) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
}