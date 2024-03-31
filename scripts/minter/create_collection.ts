import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import * as fs from "fs";
import 'dotenv/config';
import { COLLECTIONS_PATH } from "../utils";

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.accountAddress.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    const nftmachine = process.env.NFT_MACHINE;

    // Account
    await aptos.fundAccount({
        accountAddress: creator.accountAddress,
        amount: 1e18,
    });

    // Create collection
    const collection_name = "Highland " + Date.now();
    const seed = Date.now().toString();
    const createCollectionRaw = await aptos.transaction.build.simple({
        sender: creator.accountAddress,
        data: {
            function: `${nftmachine}::nftmachine::create_collection`,
            functionArguments: [
                collection_name, "HL", "https://api.pudgypenguins.io/lil/100", 
                3, 
                creator.accountAddress, "1000", "15", 
                [true, true, true], 
                "Token Base Name", "Token description Here",
                [true, true, true, true, true], seed],
        },
    });

    // sign and submit transaction to chain
    const createCollectionTx = await aptos.signAndSubmitTransaction({
        signer: creator,
        transaction: createCollectionRaw,
    });
    console.log("🚀 ~ main ~ createCollectionTx:", createCollectionTx)

    const collection_info = {
        name: collection_name,
        seed,
        creator: creator.accountAddress.toString(),
        nftmachine,
    };
    fs.writeFileSync(COLLECTIONS_PATH, JSON.stringify(collection_info, null, 2));
}

main();