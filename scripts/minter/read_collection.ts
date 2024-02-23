import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});

const aptos = new Aptos(); // Devnet

async function main() {
    const collectionName = "Highland 1708708202540";
    const resource_account = "0x5ab36b22446d7aacc7aa8507a0a403e781c67654b59bb7d373c41e6a34138323";
    // collection: 0x5ab36b22446d7aacc7aa8507a0a403e781c67654b59bb7d373c41e6a34138323
    const collectionData = await aptos.getCollectionData({
        collectionName,
        creatorAddress: resource_account
    });
    console.log("🚀 ~ main ~ collectionData:", collectionData)
   


}

main();