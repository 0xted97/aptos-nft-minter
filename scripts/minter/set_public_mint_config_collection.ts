import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.accountAddress.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    const nftmachine = process.env.NFT_MACHINE;
    const collection_address = "0xd7009bc1e4565f50dd3f09fcf7f1b826c794a7b177d0fd9ecb0ed4cc3e32007f";

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