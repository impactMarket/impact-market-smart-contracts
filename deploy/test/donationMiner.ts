import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "@ethersproject/units";
import { getCUSDAddress } from "./cUSD";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	// @ts-ignore
	const { deployments, getNamedAccounts, ethers } = hre;
	const { deploy } = deployments;

	const accounts: SignerWithAddress[] = await ethers.getSigners();
	const deployer = accounts[0];

	const Token = await deployments.get("IPCTToken");
	const Treasury = await deployments.get("TreasuryProxy");

	const ImpactProxyAdmin = await deployments.get("ImpactProxyAdmin");

	// const IPCTTimelock = await deployments.get("IPCTTimelock"); //prod
	// const ownerAddress = IPCTTimelock.address; //prod
	const ownerAddress = deployer.address; //dev
	// const cUSDAddress = getCUSDAddress(); //prod
	const cUSDAddress = (await deployments.get("TokenMock")).address; //dev

	const donationMinerImplementationResult = await deploy(
		"DonationMinerImplementation",
		{
			from: deployer.address,
			args: [],
			log: true,
			// gasLimit: 13000000,
		}
	);

	const donationMinerProxyResult = await deploy("DonationMinerProxy", {
		from: deployer.address,
		args: [
			donationMinerImplementationResult.address,
			ImpactProxyAdmin.address,
		],
		log: true,
		// gasLimit: 13000000,
	});

	const donationMinerContract = await ethers.getContractAt(
		"DonationMinerImplementation",
		donationMinerProxyResult.address
	);

	await donationMinerContract.initialize(
		cUSDAddress,
		Token.address,
		Treasury.address,
		parseEther("100"),
		14,
		30
	);

	await donationMinerContract.transferOwnership(ownerAddress);
};

export default func;
func.dependencies = [
	"ImpactProxyAdminTest",
	"GovernanceTest",
	"TreasuryTest",
	"cUSDTest",
];
func.tags = ["DonationMinerTest", "Test"];
