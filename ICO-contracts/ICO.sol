pragma solidity ^0.4.18;

import "./Base.sol";
import"./Ownable.sol";
import "./DToken.sol";
import "./SafeMath.sol";

contract ICO is Base, Ownable {

using SafeMath for uint;
    enum State { INIT, Private_SALE, ICO_FIRST, ICO_SECOND, ICO_THIRD, STOPPED, CLOSED, EMERGENCY_STOP}
    uint public constant MAX_SALE_SUPPLY = 25 * (10**25);
    uint public constant DECIMALS = (10**18); 
    State public currentState = State.INIT; 
    DToken public token;
    uint public totalSaleSupply = 0;
    uint public totalFunds = 0;
    uint public tokenPrice = 1000000000000000000; 
    uint public bonus = 100000; 
    uint public currentPrice;
    address public beneficiary;
    mapping(address => uint) balances;
 
    address public foundersWallet; 
    uint public foundersAmount = 100000000 * DECIMALS;
    uint public maxPrivateICOSupply = 48 * (10**24);
    uint public maxICOFirstSupply = 84 * (10**24);
    uint public maxICOSecondSupply = 48 * (10**24);
    uint public maxICOThirdSupply = 48 * (10**24);
    uint public currentRoundSupply = 0;
    uint private bonusBase = 100000; 
    modifier inState(State _state){
        require(currentState == _state);
        _;
    }
    modifier salesRunning(){
        require(currentState == State.Private_SALE
        || currentState == State.ICO_FIRST
        || currentState == State.ICO_SECOND
        || currentState == State.ICO_THIRD);
        _;
    }
    modifier minAmount(){
        require(msg.value >= 0.05 ether);
        _;
    }
    
    event Transfer(address indexed _to, uint _value);
    
    function ICO(address _foundersWallet, address _beneficiary){
        beneficiary = _beneficiary;
        foundersWallet = _foundersWallet;
    }
    function initialize(DToken _token)
    public
    onlyOwner()
    inState(State.INIT)
    {
        require(_token != address(0));
        token = _token;
        currentPrice = tokenPrice;
        _mintable(foundersWallet, foundersAmount);
    }
    function setBonus(uint _bonus) public
    onlyOwner()
    {
        bonus = _bonus;
    }
    function setPrice(uint _tokenPrice)
    public
    onlyOwner()
    {
        currentPrice = _tokenPrice;
    }
    function setState(State _newState)
    public
    onlyOwner()
    {
        require(
        currentState == State.INIT && _newState == State.Private_SALE
        || currentState == State.Private_SALE && _newState == State.ICO_FIRST
        || currentState == State.ICO_FIRST && _newState == State.STOPPED
        || currentState == State.STOPPED && _newState == State.ICO_SECOND        
        || currentState == State.ICO_SECOND && _newState == State.STOPPED
        || currentState == State.STOPPED && _newState == State.ICO_THIRD
        || currentState == State.ICO_THIRD && _newState == State.CLOSED
        || _newState == State.EMERGENCY_STOP
        );
        currentState = _newState;
        if(_newState == State.Private_SALE
        || _newState == State.ICO_FIRST
        || _newState == State.ICO_SECOND
        || _newState == State.ICO_THIRD){
            currentRoundSupply = 0;
        }
        if(_newState == State.CLOSED){
            _finish();
        }
    }
    function setStateWithBonus(State _newState, uint _bonus)
    public
    onlyOwner()
    {
        require(
        currentState == State.INIT && _newState == State.Private_SALE
        || currentState == State.Private_SALE && _newState == State.ICO_FIRST
        || currentState == State.ICO_FIRST && _newState == State.STOPPED
        || currentState == State.STOPPED && _newState == State.ICO_SECOND        
        || currentState == State.ICO_SECOND && _newState == State.STOPPED
        || currentState == State.STOPPED && _newState == State.ICO_THIRD
        || currentState == State.ICO_THIRD && _newState == State.CLOSED
        || _newState == State.EMERGENCY_STOP
        );
        currentState = _newState;
        bonus = _bonus;
        if(_newState == State.Private_SALE
        || _newState == State.ICO_FIRST
        || _newState == State.ICO_SECOND
        || _newState == State.ICO_THIRD){
            currentRoundSupply = 0;
        }
        if(_newState == State.CLOSED){
            _finish();
        }
    }
    function mintPrivate(address _to, uint _amount)
    public
    onlyOwner()
    inState(State.Private_SALE)
    {
        require(totalSaleSupply.add(_amount) <= MAX_SALE_SUPPLY);
        totalSaleSupply = totalSaleSupply.add(_amount);
        _mintable(_to, _amount);
    }
    function ()
    public
    payable
    salesRunning
    minAmount
    {
        _receiveFunds();
    }

    
    function _receiveFunds()
    internal
    {
        require(msg.value != 0);
        uint transferTokens = msg.value.mul(DECIMALS).div(currentPrice);
        require(totalSaleSupply.add(transferTokens) <= MAX_SALE_SUPPLY);
        uint bonusTokens = transferTokens.mul(bonus).div(bonusBase);
        transferTokens = transferTokens.add(bonusTokens);
        _checkMaxRoundSupply(transferTokens);
        totalSaleSupply = totalSaleSupply.add(transferTokens);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalFunds = totalFunds.add(msg.value);
        _mintable(msg.sender, transferTokens);
        beneficiary.transfer(msg.value);
        Transfer(msg.sender, transferTokens);
    }
    function _mintable(address _to, uint _amount)
    noAnyReentrancy
    internal
    {
        token.mintable(_to, _amount);
    }
    function _checkMaxRoundSupply(uint _amountTokens)
    internal
    {
        if (currentState == State.Private_SALE) {
            require(currentRoundSupply.add(_amountTokens) <= maxPrivateICOSupply);
            currentRoundSupply = currentRoundSupply.add(_amountTokens);
        } else if (currentState == State.ICO_FIRST) {
            require(currentRoundSupply.add(_amountTokens) <= maxICOFirstSupply);
            currentRoundSupply = currentRoundSupply.add(_amountTokens);
        } else if (currentState == State.ICO_SECOND) {
            require(currentRoundSupply.add(_amountTokens) <= maxICOSecondSupply);
            currentRoundSupply = currentRoundSupply.add(_amountTokens);
        } else if (currentState == State.ICO_THIRD) {
            require(currentRoundSupply.add(_amountTokens) <= maxICOThirdSupply);
            currentRoundSupply = currentRoundSupply.add(_amountTokens);
        }
    }
    function _finish()
    noAnyReentrancy
    internal
    {
        token.start();
    }
}
