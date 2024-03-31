import { Aptos, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import 'dotenv/config';
import { getCollection } from "../utils";
import moment from "moment";

const creator = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(process.env.NFT_CREATOR_PRIVATE_KEY || "")
});
console.log("🚀 ~ creator:", creator.accountAddress.toString())

const aptos = new Aptos(); // Devnet

async function main() {
    const nftmachine = process.env.NFT_MACHINE;
    const collection = getCollection();

    const collection_address = collection.address;

    // Account
    await aptos.fundAccount({
        accountAddress: creator.accountAddress,
        amount: 1e18,
    });

    const price = 17 * 1e7;
    const start = moment().unix();
    const end = moment().add("days", 1).unix();

    // Set public mint config
    const setWhitelistMintRaw = await aptos.transaction.build.simple({
        sender: creator.accountAddress,
        data: {
            function: `${nftmachine}::nftmachine::set_mint_whitelist`,
            functionArguments: [
                collection_address,
                price,
                start, end,
                ["0xf8cad0049294097a72c6d37f6b259d592ff1b2fb13259b0e1b82994ecc0ef522", "0x04211a725381d5cef7a648583de9b0c197a235822b120964e94f24438eb33a09", "0x7e833ed1bc62cfb7857e382bf1fe106a794e325d72c92296c5f0022cda3b09fc"],
                [1, 5, 5]
            ],
        },
    });
    // sign and submit transaction to chain
    const setWhitelistMintTx = await aptos.signAndSubmitTransaction({
        signer: creator,
        transaction: setWhitelistMintRaw,
    });
    console.log("🚀 ~ main ~ setWhitelistMintTx:", setWhitelistMintTx)





}

main();