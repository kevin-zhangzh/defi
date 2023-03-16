// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol"; // 引入 ERC20 接口

contract AKLFarm {
    struct UserInfo {
        uint256 amount; // 用户存款数量
        uint256 rewardDebt; // 已经结算的奖励债务
    }

    struct PoolInfo {
        IERC20 lpToken; // 池子的 LP Token 合约地址
        uint256 allocPoint; // 分配给该池子的权重
        uint256 lastRewardBlock; // 上一个区块的奖励分配量
        uint256 accRewardPerShare; // 每个份额的累计奖励
    }

    // 代币总供应量
    uint256 public totalSupply;
    // 用户存款总量
    uint256 public totalDeposited;
    // 奖励代币总量
    uint256 public totalRewards;

    // 奖励代币地址
    address public rewardToken;
    // owner
    address public admin;
    // 池子信息数组
    PoolInfo[] public poolInfo;
    // 用户信息映射
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // 各个池子的总权重
    uint256 public totalAllocPoint = 0;
    // perBlock 奖励
    uint256 public rewardPerBlock;

    // 存款事件，记录存款者地址、存款量和奖励量
    event Deposit(address indexed user, uint256 amount, uint256 reward);

    // 提现事件，记录提现者地址、提现量和奖励量
    event Withdraw(address indexed user, uint256 amount, uint256 reward);

    // 添加流动性池子事件，记录流动性 Token 地址、奖励 Token 地址和奖励系数
    event AddPool(address indexed lpToken, uint256 poolId);

    // 更新流动性池子事件，记录流动性 Token 地址、奖励 Token 地址、总存款量和奖励池余额
    event UpdatePool(address indexed lpToken, address indexed rewardToken, uint256 totalAmount, uint256 rewardBalance);

    // 提取奖励事件，记录管理员地址和提取的奖励量
    event EmergencyRewardWithdraw(address indexed admin, uint256 amount);

    // 更改管理员事件，记录原管理员地址和新管理员地址
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(
    address _rewardToken,
    uint256 _rewardPerBlock
    ) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock * 10**18;

        // 初始化管理员为合约创建者
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function addPool(address _lpToken, uint256 _allocPoint) public {
        require(msg.sender == admin, "MasterChef: caller is not the owner");
        uint256 i;
        for (i = 0; i < poolInfo.length; i++) {
            require(poolInfo[i].lpToken != IERC20(_lpToken), "MasterChef: pool already exists");
        }
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accRewardPerShare: 0
            })
        );
        emit AddPool(_lpToken, i);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 reward = (block.number - pool.lastRewardBlock) * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        totalRewards += reward;
        pool.accRewardPerShare += reward / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingReward = user.amount * pool.accRewardPerShare - user.rewardDebt;
            safeRewardTransfer(msg.sender, pendingReward);
        }
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;
        totalDeposited += _amount;
        user.rewardDebt = user.amount * pool.accRewardPerShare;
        emit Deposit(msg.sender, user.amount, user.rewardDebt);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "MasterChef: insufficient balance");
        updatePool(_pid);
        uint256 pendingReward = user.amount * pool.accRewardPerShare - user.rewardDebt;
        safeRewardTransfer(msg.sender, pendingReward);
        user.amount -= _amount;
        totalDeposited -= _amount;
        user.rewardDebt = user.amount * pool.accRewardPerShare;
        pool.lpToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, user.amount, _amount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
        if (_amount > rewardBal) {
            IERC20(rewardToken).transfer(_to, rewardBal);
        } else {
            IERC20(rewardToken).transfer(_to, _amount);
        }
    }

    function adminChange(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be 0");
        admin = _newAdmin;
        emit AdminChanged(admin, _newAdmin);
    }

}