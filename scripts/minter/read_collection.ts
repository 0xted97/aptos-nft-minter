import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.publicKey.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    const collectionName = "Highland 1711876184943";
    const resource_account = "0x4f942fd8d433c34d921c4f4ddcd10d751db6a377e8980ee187c50ab9b61a7f09";
    const collectionData = await aptos.getCollectionData({
        collectionName,
        creatorAddress: resource_account
    });
    console.log("🚀 ~ main ~ collectionData:", collectionData)
   


}

main();