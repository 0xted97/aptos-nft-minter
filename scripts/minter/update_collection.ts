import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.accountAddress.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    // Create collection
    const completedRaw = await aptos.transaction.build.simple({
        sender: creator.accountAddress,
        data: {
            function: `04211a725381d5cef7a648583de9b0c197a235822b120964e94f24438eb33a09::nftmachine::update_collection`,
            functionArguments: [
                "0xc93167146cf281b170e1e247a604bbad3b96e82b7fb596b5624e6f4c1d6e098a", 
                "Highland le duc tho", 
                "https://d2n53fle6zg0fj.cloudfront.net/metadata/lumins/32", 
                "0",
                "0xc5764d8804022fdb826cc339f72c4ca37dbad318db6845e8e6d9cc60cf9dc0c5",
                1000,
                159
            ],
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