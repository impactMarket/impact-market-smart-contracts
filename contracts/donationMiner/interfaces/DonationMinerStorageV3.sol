// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import "./DonationMinerStorageV2.sol";

/**
 * @title Storage for DonationMiner
 * @notice For future upgrades, do not change DonationMinerStorageV3. Create a new
 * contract which implements DonationMinerStorageV3 and following the naming convention
 * DonationMinerStorageVX.
 */
abstract contract DonationMinerStorageV3 is DonationMinerStorageV2 {
    uint256 public override againstPeriods;
}
