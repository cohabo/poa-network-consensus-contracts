pragma solidity ^0.4.18;


interface IBallotsStorage {
    function setThreshold(uint256, uint8) public;
    function getBallotThreshold(uint8) public view returns(uint256);
    function getVotingToChangeThreshold() public view returns(address);
}