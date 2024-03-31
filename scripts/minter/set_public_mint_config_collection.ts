import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.accountAddress.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    const nftmachine = process.env.NFT_MACHINE;
    const collection_address = "0x4f942fd8d433c34d921c4f4ddcd10d751db6a377e8980ee187c50ab9b61a7f09";

    // Account
    await aptos.fundAccount({
        accountAddress: creator.accountAddress,
        amount: 1e18,
    });

    const price = 13 * 1e7;

    // Set public mint config
    const setPublicMintRaw = await aptos.transaction.build.simple({
        sender: creator.accountAddress,
        data: {
            function: `${nftmachine}::nftmachine::set_mint_public`,
            functionArguments: [collection_address, price],
        },
    });
    // sign and submit transaction to chain
    const setPublicMintTx = await aptos.signAndSubmitTransaction({
        signer: creator,
        transaction: setPublicMintRaw,
    });
    console.log("🚀 ~ main ~ setPublicMintTx:", setPublicMintTx)





}

main();