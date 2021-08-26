//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "hardhat/console.sol";

contract DonationMiner3 is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    event RewardClaim(address indexed user, uint256 amount);
    event DonationEvent(address indexed user, uint256 amount);

    IERC20 public immutable cUSD;
    IERC20 public immutable IPCT;
    address public treasuryAddress;
    uint256 public blocksInRewardPeriod;
    uint256 public startingRewardBlock;

    uint256 public unclaimedReward;
    uint256 public lastClaimedBlock;

    struct Donation {
        address donor;
        uint256 amount;
        uint256 blockNumber;
        bool isClaimed;
    }
    mapping(uint256 => Donation) private donations;
    uint256 donationsCount;

    mapping(address => uint256) private userReward;

    /**
     * @notice Enforces values > 0 only
     */
    modifier greaterThanZero(uint256 _value) {
        require(_value > 0, "ERR_ZERO_VALUE");
        _;
    }

    /**
     * @notice Enforces beginning rewardPeriod has started
     */
    modifier whenStarted() {
        require(block.number >= startingRewardBlock, "ERR_NOT_STARTED");
        _;
    }

    constructor(
        IERC20 _cUSD,
        IERC20 _IPCT,
        uint256 _startingRewardPerBlock,
        uint256 _blocksInRewardPeriod,
        uint256 _startingRewardPeriod,
        uint256 _startingRewardPeriodRatioSpan,
        address _treasuryAddress
    ) {
        require(address(_cUSD) != address(0), "_cUSD address not set!");
        require(address(_IPCT) != address(0), "_IPCT address not set!");
        require(address(_treasuryAddress) != address(0), "_treasuryAddress not set!");

        require(_startingRewardPerBlock != 0, "_startingRewardPerBlock not set!");
        require(_startingRewardPeriod != 0, "_startingRewardPeriod not set!");
        // require(_startingRewardPeriod > _getCurrentRewardPeriod(), "_startingRewardPeriod must be in future!");
        require(_startingRewardPeriodRatioSpan != 0, "_startingRewardPeriodRatioSpan not set!");

        cUSD = _cUSD;
        IPCT = _IPCT;
        treasuryAddress = _treasuryAddress;
        startingRewardBlock = _startingRewardPeriod;
        blocksInRewardPeriod = _blocksInRewardPeriod;

        lastClaimedBlock = _startingRewardPeriod;
    }

    function _rewardToAdd(uint256 _blockNUmber) internal view returns (uint256) {
        return (_blockNUmber - lastClaimedBlock) * 100e18;
    }

    /**
     * @dev Deposit cUSD tokens to the donation mining contract
     * @param _amount Amount of cUSD tokens to deposit.
     */
    function donate(uint256 _amount)
        external
        greaterThanZero(_amount)
        whenNotPaused
        whenStarted
        nonReentrant
    {
        // Transfer the cUSD from the user to the treasury
        cUSD.safeTransferFrom(address(msg.sender), address(treasuryAddress), _amount);

        donationsCount++;
        Donation storage donation = donations[donationsCount];
        donation.donor = msg.sender;
        donation.blockNumber = block.number;
        donation.amount = _amount;

        uint256 totalDonations = calculateTotalDonations(block.number);
        unclaimedReward += _rewardToAdd(block.number);
        lastClaimedBlock = block.number;
        uint256 claimAmount;
        claimAmount = (unclaimedReward * _amount) / totalDonations;

        unclaimedReward -= claimAmount;

        userReward[msg.sender] += claimAmount;

        emit DonationEvent(msg.sender, _amount);
    }

    /**
     * @dev Calculate and claim all pending rewards for a user
     */
    function claimRewards() external whenNotPaused whenStarted nonReentrant {
        if (userReward[msg.sender] > 0) {
            IPCT.safeTransfer(msg.sender, userReward[msg.sender]);
            emit RewardClaim(msg.sender, userReward[msg.sender]);
            userReward[msg.sender] = 0;
        }
    }

    function getUnclaimedReward(uint256 _blockNumber) public view returns (uint256) {
        return unclaimedReward + _rewardToAdd(_blockNumber);
    }

    function calculateTotalDonations(uint256 _blockNumber) public view returns (uint256) {
        uint256 totalDonations;
        uint256 iterator = donationsCount;
        uint256 startingBlock = block.number - blocksInRewardPeriod > startingRewardBlock
            ? block.number - blocksInRewardPeriod
            : startingRewardBlock;

        while (donations[iterator].blockNumber >= startingBlock) {
            totalDonations = totalDonations + donations[iterator].amount;
            iterator--;
        }

        return totalDonations;
    }
}