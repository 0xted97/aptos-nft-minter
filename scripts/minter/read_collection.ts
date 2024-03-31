import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';
import { getCollection } from "../utils";

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});

const aptos = new Aptos(); // Devnet

async function main() {

    const collection = getCollection();
    const collectionName = collection.name;
    const resource_account = collection.address;
    const collectionData = await aptos.getCollectionData({
        collectionName,
        creatorAddress: resource_account
    });
    console.log("🚀 ~ main ~ collectionData:", collectionData)
   


}

main();