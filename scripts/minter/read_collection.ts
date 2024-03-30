import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});

const aptos = new Aptos(); // Devnet

async function main() {
    const collectionName = "Highland 1708711657440";
    const resource_account = "0xc93167146cf281b170e1e247a604bbad3b96e82b7fb596b5624e6f4c1d6e098a";
    // collection: 0xc93167146cf281b170e1e247a604bbad3b96e82b7fb596b5624e6f4c1d6e098a
    const collectionData = await aptos.getCollectionData({
        collectionName,
        creatorAddress: resource_account
    });
    console.log("🚀 ~ main ~ collectionData:", collectionData)
   


}

main();