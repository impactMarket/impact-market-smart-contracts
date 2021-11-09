// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.5;

import "./ITreasury.sol";

/**
 * @title Storage for Treasury
 * @notice For future upgrades, do not change TreasuryStorageV1. Create a new
 * contract which implements TreasuryStorageV1 and following the naming convention
 * TreasuryStorageVX.
 */
abstract contract TreasuryStorageV1 is ITreasury {
    ICommunityAdmin internal _communityAdmin;
}