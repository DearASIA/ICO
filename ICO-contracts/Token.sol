pragma solidity ^0.4.18;

import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./Base.sol";

contract Token is MintableToken, BurnableToken, Base{
    using SafeMath for uint;
    string public name = "Dear Coin";
    string public symbol = "DEAR";
    uint8 public decimals = 18;
    bool    public isStarted = false;
    modifier isStartedOnly() {
        require(isStarted);
        _;
    }
    address public ICOMinter;
    modifier onlyICOMinter(){
        require(msg.sender == ICOMinter);
        _;
    }
    
    modifier isNotStartedOnly() {
        require(!isStarted);
        _;
    }
    function Token(address _ICOMinter){
        ICOMinter = _ICOMinter;
    }
    function start()
    public
    onlyICOMinter
    isNotStartedOnly
    {
        isStarted = true;
    }
    function emergencyStop()
    public
    onlyOwner()
    {
        isStarted = false;
    }

    function mintable(address _to, uint _amount) public
    onlyICOMinter
    isNotStartedOnly
    returns(bool)
    {
        totalSupply_ =totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        return true;
    }
}