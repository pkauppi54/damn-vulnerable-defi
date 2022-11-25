const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Backdoor', function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther('40');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address]

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory('GnosisSafe', deployer)).deploy();
        this.walletFactory = await (await ethers.getContractFactory('GnosisSafeProxyFactory', deployer)).deploy();
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        
        // Deploy the registry
        this.walletRegistry = await (await ethers.getContractFactory('WalletRegistry', deployer)).deploy(
            this.masterCopy.address,
            this.walletFactory.address,
            this.token.address,
            users
        );

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.true;            
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);

        this.intruder = await (await ethers.getContractFactory('Intruder', attacker)).deploy(
            this.walletFactory.address,
            this.walletRegistry.address,
            this.masterCopy.address,
            attacker.address
        );
        
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        this.timeout(20000);
        this.token.provider.pollingInterval = 1;
        console.log("Attacker tokens: ", await (await this.token.balanceOf(attacker.address)).toString())
        console.log("Balance of singleton: ", await (await this.token.balanceOf(this.masterCopy.address)).toString())
        console.log("Intruder tokens: ", await (await this.token.balanceOf(this.intruder.address)).toString())
        console.log("Registry tokens: ", await (await this.token.balanceOf(this.walletRegistry.address)).toString())
        console.log("-----------------ATTACK----------------")


        await this.intruder.connect(attacker).attack(users, this.token.address);

        console.log("-----------------FINISHED----------------")
        console.log("Attacker tokens: ", await (await this.token.balanceOf(attacker.address)).toString())
        console.log("Balance of singleton: ", await (await this.token.balanceOf(this.masterCopy.address)).toString())
        console.log("Intruder tokens: ", await (await this.token.balanceOf(this.intruder.address)).toString())
        console.log("Registry tokens: ", await (await this.token.balanceOf(this.walletRegistry.address)).toString())

        console.log("Balance of user wallet: ", await (await this.token.balanceOf(await this.walletRegistry.wallets(users[0]))).toString())
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i]);
            
            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet");

            // User is no longer registered as a beneficiary
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.false;
        }

        // Attacker must have taken all tokens
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
    });
});
