// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.6.0 <0.9.0; 

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

    contract yusToken is ERC20Interface{
        string public name = "YusToken";
        string public symbol = "YUS";
        uint public decimals = 0;
        uint public override totalSupply;
        address public founder;
        mapping(address => uint) public balances;
        mapping(address => mapping(address => uint)) allowed; 
        //0x111 allows 0x22 100 tokens, allowed[0x111][0x222]=100 
        constructor() {
            totalSupply = 1000000000;
            founder = msg.sender;
            //founder will have 1,000,000 tokens
            balances[founder] = totalSupply;
        }

        function balanceOf(address tokenOwner) public override view returns (uint balance){
            return balances[tokenOwner]; 
        }

        function transfer(address to, uint tokens) public virtual override returns (bool success){
            require(balances[msg.sender] >= tokens);
            balances[to] += tokens;
            balances[msg.sender] -= tokens;
            emit Transfer(msg.sender,to, tokens);
            return true;
        }

        function allowance(address tokenOwner, address spender) view public override returns(uint){
            return allowed[tokenOwner][spender];
        }
        function approve(address spender, uint tokens) public override returns (bool success) {
            require(balances[msg.sender] >= tokens);
            require(tokens > 0);
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender,spender,tokens);
            return true;
        }

        function transferFrom(address from, address to, uint tokens) public virtual override returns(bool success){
            require(allowed[from][msg.sender] >= tokens);
            require(balances[from] >= tokens);
            balances[from] -= tokens;
            allowed[from][msg.sender] -= tokens;
            balances[to] += tokens;
            emit Transfer(from, to , tokens);
            return true; 
        }
    }

    contract yusICO is yusToken{
        address public admin;
        address payable public deposit; 
        uint tokenPrice = 0.001 ether;
        uint public cap = 200 ether; 
        uint public raisedAmount; 
        //ICO will start a minute after deployment.
        uint public saleStart = block.timestamp + 60; 
        //ICO ends in one week.
        uint public saleEnd = block.timestamp +604800;
        //Intial inverstors will be able to trade and sell token after one week. 
        uint public tokenTradeStart = saleEnd + 604800;
        uint public maxInvestment = 10 ether;
        uint public minInvestment = 0.1 ether;
        enum State{beforeStart, running, end, halted}
        State public icoState; 
        constructor(address payable _deposit){
            deposit = _deposit;
            admin = msg.sender;
            icoState = State.beforeStart;
        }
        modifier onlyAdmin{
            require(msg.sender == admin);
            _;
        }
        function haltICO() onlyAdmin public {
            icoState = State.halted;
        }
        function resumeICO() onlyAdmin public{
            icoState = State.running;
        }
        function changeDepositAddress(address payable newDeposit) public onlyAdmin{
            deposit = newDeposit; 
        }
        function getCurrentState() public view returns(State){
           if(icoState == State.halted){
               return State.halted;
           }else if(block.timestamp < saleStart){
               return State.beforeStart;
           }else if (block.timestamp <= saleEnd && block.timestamp >= saleStart){
               return State.running;
           }else{
               return State.end;
           }
        }
        event InvestICO(address investor, uint value, uint tokens);
        function investICO() payable public returns(bool){ 
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= cap);
        uint tokens = msg.value / tokenPrice;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens; 
        deposit.transfer(msg.value); 
        emit InvestICO(msg.sender, msg.value, tokens);
        return true;
    }
        receive() payable external{
        investICO();
        }
        function transfer(address to, uint tokens) public override returns (bool success){
            require(block.timestamp > tokenTradeStart);
            yusToken.transfer(to, tokens);
            return true;
        }
           function transferFrom(address from, address to, uint tokens) public override returns(bool success){
            require(block.timestamp > tokenTradeStart);
            yusToken.transferFrom(from, to, tokens);
            return true;
        }

        function burnTokens() public returns(bool) {
            icoState = getCurrentState();
            require(icoState == State.end);
            balances[founder] == 0;
            return true;
        }
    }
 