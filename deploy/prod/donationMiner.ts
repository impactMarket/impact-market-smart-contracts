import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "@ethersproject/units";
import { getCUSDAddress } from "./cUSD";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	// @ts-ignore
	const { deployments, ethers } = hre;
	const { deploy } = deployments;

	const accounts: SignerWithAddress[] = await ethers.getSigners();
	const deployer = accounts[0];

	const Token = await deployments.get("PACTToken");
	const Treasury = await deployments.get("TreasuryProxy");

	const ImpactProxyAdmin = await deployments.get("ImpactProxyAdmin");

	const pactTimelock = await deployments.get("PACTTimelock"); //prod
	const ownerAddress = pactTimelock.address; //prod
	// const ownerAddress = deployer.address; //dev
	const cUSDAddress = getCUSDAddress();

	const donationMinerImplementationResult = await deploy(
		"DonationMinerImplementation",
		{
			from: deployer.address,
			args: [],
			log: true,
			// gasLimit: 13000000,
		}
	);

	await new Promise((resolve) => setTimeout(resolve, 6000));

	const donationMinerProxyResult = await deploy("DonationMinerProxy", {
		from: deployer.address,
		args: [
			donationMinerImplementationResult.address,
			ImpactProxyAdmin.address,
		],
		log: true,
		// gasLimit: 13000000,
	});

	await new Promise((resolve) => setTimeout(resolve, 6000));

	const donationMinerContract = await ethers.getContractAt(
		"DonationMinerImplementation",
		donationMinerProxyResult.address
	);

	await donationMinerContract.initialize(
		cUSDAddress,
		Token.address,
		Treasury.address,
		parseEther("250"),
		17280,
		9455225,
		"998902",
		"1000000"
	);

	await new Promise((resolve) => setTimeout(resolve, 6000));

	const PACT = await deployments.get("PACTToken");
	const PACTContract = await ethers.getContractAt("PACTToken", PACT.address);
	await PACTContract.transfer(
		donationMinerContract.address,
		parseEther("4000000000")
	);

	await new Promise((resolve) => setTimeout(resolve, 6000));

	await donationMinerContract.transferOwnership(ownerAddress);

	await new Promise((resolve) => setTimeout(resolve, 6000));
};

export default func;
func.dependencies = [
	"ImpactProxyAdminProd",
	"GovernanceProd",
	"TreasuryProd",
	"cUSDProd",
];
func.tags = ["DonationMinerProd", "Prod"];
