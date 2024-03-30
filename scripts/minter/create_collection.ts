import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.accountAddress.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    // Account
    // await aptos.fundAccount({
    //     accountAddress: creator.accountAddress,
    //     amount: 1e18,
    // });
    // Create collection
    const completedRaw = await aptos.transaction.build.simple({
        sender: creator.accountAddress,
        data: {
            function: `04211a725381d5cef7a648583de9b0c197a235822b120964e94f24438eb33a09::nftmachine::create_collection`,
            functionArguments: [
                "Highland " + Date.now(), "HL", "https://api.pudgypenguins.io/lil/100", 
                3, 
                "0x637b3459fa497e5a52692ec3acb1b9b1863cc284b2d8a52a10d4ffd681d7dfb1", "1000", "15", 
                [false, true, false], [true, true, true, true, true], Date.now().toString()],
        },
    });
    // sign and submit transaction to chain
    const completedTx = await aptos.signAndSubmitTransaction({
        signer: creator,
        transaction: completedRaw,
    });
    console.log("🚀 ~ main ~ completedTx:", completedTx)
}

main();