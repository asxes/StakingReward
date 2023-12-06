// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Stake
 * @notice This contract stakes three different ERC20 tokens
 * and provides a certain amount of staking reward based on
 * the staking duration.
 */
contract Stake {
    /**
     * @dev supported ERC20 tokens.
     */

    IERC20 TNR = IERC20(0xE962c58ACdf0B69f33390a783ad1231994aA460B);
    IERC20 USDT = IERC20(0xebFa8d804f193678D42039C83f5a12cFeaf92945);
    IERC20 USDC = IERC20(0xcd0D7ec19055F5C080d20d3Fe1798d7321716f40);

    struct Stakes {
        uint256 amount;
        uint16 period;
        uint256 unlockDate;
    }

    mapping(address => Stakes) addressToStakes;

    event staked(uint256 _amount, uint16 _duration, address _staker);
    event unstaked(
        uint256 _amount,
        uint256 _reward,
        uint16 _duration,
        address _staker
    );
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call detected");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev period is equal to 30 days , 90 days and 365 days
     * @param amount_ :amount of staked token
     * @param period_ :d uration  of stake
     * @param currency_ : address of staking erc20 token
     * Emits an {Approval} event indicating the updated allowance. This is not.
     */

    function stake(
        uint256 amount_,
        uint16 period_,
        address currency_
    ) public returns (bool) {
        require(
            currency_ == address(TNR) ||
                currency_ == address(USDT) ||
                currency_ == address(USDC),
            "Unsupported currency"
        );

        require(amount_ > 0, "send 0  tokens");

        require(
            period_ == 30 || period_ == 90 || period_ == 365,
            "period is invalid"
        );
        require(
            IERC20(currency_).transferFrom(msg.sender, address(this), amount_),
            "Transfer failed"
        );
        uint256 unlockDate_;
        if (period_ == 30) {
            unlockDate_ = block.timestamp + 30 days;
        } else if (period_ == 90) {
            unlockDate_ = block.timestamp + 90 days;
        } else {
            unlockDate_ = block.timestamp + 365 days;
        }

        Stakes memory stake_ = Stakes(amount_, period_, unlockDate_);
        addressToStakes[msg.sender] = stake_;

        emit staked(amount_, period_, msg.sender);

        return true;
    }

    /**
     * @dev unstakes fund and adds amount of token according to it's stake duration.
     * @param staker_ :address of staked token
     * @param currency_ : address of staking erc20 token
     */

    function unstake(
        address staker_,
        address currency_
    ) public nonReentrant returns (bool) {
        require(checkPeriod(staker_), "can not unstake before unlock date");

        uint16 period_ = addressToStakes[staker_].period;

        uint256 amount_ = addressToStakes[staker_].amount;
        uint256 reward_ = calculateStake(staker_, period_);
        uint16 duration_ = addressToStakes[staker_].period;

        bool b = IERC20(currency_).transfer(
            staker_,
            amount_ + calculateStake(staker_, period_)
        );
        require(b, "unstake unsuccessfull");
        addressToStakes[staker_].amount = 0;

        emit unstaked(amount_, reward_, duration_, staker_);

        return true;
    }

    /**
     * @dev calculates rewards of staked token.
     */
    function calculateStake(
        address staker_,
        uint16 period_
    ) internal view returns (uint256 r) {
        uint256 amount_ = addressToStakes[staker_].amount;

        if (period_ == 30) {
            r = ((amount_ * 25) / 100);
        }

        if (period_ == 90) {
            r = ((amount_ * 50) / 100);
        }

        if (period_ == 365) {
            r = amount_;
        }
    }

    /**
     * @dev checks whether the period is fullfilled or not.
     */

    function checkPeriod(address staker_) internal view returns (bool) {
        uint256 unlockDate_ = addressToStakes[staker_].unlockDate;

        if (unlockDate_ <= block.timestamp) return true;
        else return false;
    }

    //////////////////////*  GETTERS  *//////////////////////
    function getUnlockDate2(
        address staker_
    ) external view returns (uint256 unlockDate_) {
        unlockDate_ = addressToStakes[staker_].unlockDate;
    }

    function getStakedAmount(
        address staker_
    ) external view returns (uint256 stakedAmount) {
        stakedAmount = addressToStakes[staker_].amount;
    }
}
