// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import "./DonationMinerStorageV1.sol";

/**
 * @title Storage for DonationMiner
 * @notice For future upgrades, do not change DonationMinerStorageV2. Create a new
 * contract which implements DonationMinerStorageV2 and following the naming convention
 * DonationMinerStorageVX.
 */
abstract contract DonationMinerStorageV2 is DonationMinerStorageV1 {
    uint256 public override claimDelay;
}
