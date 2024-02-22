module nftmachine_addr::nftmachine {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_framework::timestamp;
    use aptos_framework::account::{Self, SignerCapability, create_resource_account, create_signer_with_capability};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::resource_account;
    use aptos_token::token::{Self, TokenId, CollectionMutabilityConfig, TokenMutabilityConfig, create_tokendata, create_token_data_id, mint_token, direct_transfer, create_collection_mutability_config, create_token_mutability_config};

    // Errors
    const ENOT_ADMIN: u64 = 0;
    const ENO_COIN_CAP: u64 = 1;
    const ENOT_ALREADY: u64 = 2;
    const INVALID_MUTABLE_CONFIG:u64 = 7;

    struct NFTMachineConfig has key {
        admin: address,
        treasury: address,
    }

    struct ResourceInfo has key {
        source: address,
        resource_cap: SignerCapability,
        token_minting_events: EventHandle<NFTMintMintingEvent>
    }

    struct NFTMintMintingEvent has drop, store {
        token_receiver_address: address,
        token_id: TokenId
    }

    struct CollectionConfig has key {
        collection_name: String,
        collection_description: String,
        collection_maximum: u64,
        collection_uri: String,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        collection_mutate_config: CollectionMutabilityConfig,

        token_counter: u64,
        // Token Config
        token_mutate_config: TokenMutabilityConfig,
    }

    fun init_module(account: &signer) {
        move_to(account, NFTMachineConfig {
            admin: signer::address_of(account),
            treasury: signer::address_of(account),
        });
    }

    public entry fun create_collection(
        account: &signer, 
        collection_name: String,
        collection_description: String,
        collection_uri: String,
        maximum_supply: u64,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        collection_mutate_config: vector<bool>,
        token_mutate_config: vector<bool>,
        seeds: vector<u8>
    ) {
        let (resource, resource_cap) = create_resource_account(account, seeds);
        let resource_signer_from_cap = create_signer_with_capability(&resource_cap);
        let account_addr = signer::address_of(account);
        
        move_to<ResourceInfo>(&resource_signer_from_cap, ResourceInfo {
            source: account_addr,
            resource_cap: resource_cap,
            token_minting_events: account::new_event_handle<NFTMintMintingEvent>(&resource_signer_from_cap)
        });

        // Start Validate inputs here.
        // assert!(vector::length(&collection_mutate_config) == 3 && vector::length(&token_mutate_config) == 5, INVALID_MUTABLE_CONFIG);
        // End Validate inputs here.

        // Token

        move_to(&resource_signer_from_cap, CollectionConfig {
            collection_name,
            collection_description,
            collection_maximum: maximum_supply,
            collection_uri,
            royalty_payee_address,
            royalty_points_numerator,
            royalty_points_denominator,
            collection_mutate_config: create_collection_mutability_config(&collection_mutate_config),
            token_counter: 1,
            // Token
            token_mutate_config: create_token_mutability_config(&token_mutate_config),
        });

        token::create_collection(
            &resource_signer_from_cap, 
            collection_name,
            collection_description,
            collection_uri,
            maximum_supply, 
            collection_mutate_config
        );
    }

    public entry fun mint_public(receiver: &signer, candymachine: address, property_keys: vector<string::String>, property_values: vector<vector<u8>>, property_types: vector<string::String>) acquires ResourceInfo, CollectionConfig {
       mint(receiver, candymachine, 0, 1, property_keys, property_values, property_types);
    }

    public entry fun set_whitelist(admin: &signer)  {
      
    }

    public entry fun set_treasury(admin: &signer, candymachine: address ,new_treasury_address: address) acquires NFTMachineConfig {
        let admin_addr = signer::address_of(admin);
        let nft_mint_config = borrow_global_mut<NFTMachineConfig>(candymachine);
        assert!(admin_addr == nft_mint_config.admin, error::permission_denied(ENOT_ADMIN));
        nft_mint_config.treasury = new_treasury_address;
    }


    // ======================================================================
    //   view functions //
    // ======================================================================
    // #[view]
    // public fun get_nft_collection(): CollectionConfig acquires CollectionConfig {
    //     borrow_global<CollectionConfig>(@nftmachine)
    // }

    // ======================================================================
    //   private helper functions //
    // ======================================================================
    fun mint(nft_claimer: &signer, candymachine: address, price: u64, amount: u64, property_keys: vector<string::String>, property_values: vector<vector<u8>>, property_types: vector<string::String>) acquires ResourceInfo, CollectionConfig {
        let nft_claimer_addr = signer::address_of(nft_claimer);
        
        let collection_config = borrow_global_mut<CollectionConfig>(candymachine);
        let resource_info = borrow_global_mut<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);


        let token_id = u64_to_string(collection_config.token_counter);

        let token_name = string::utf8(b"Token name");
        string::append_utf8(&mut token_name, b": ");
        string::append(&mut token_name, token_id);

        let token_description = string::utf8(b"Token description");

        // NOTE: Test, remove it later
        let token_uri = collection_config.collection_uri;
        string::append(&mut token_uri, token_id);
        let token_data_id = create_tokendata(
                &resource_signer_from_cap,
                collection_config.collection_name,
                token_name,
                token_description,
                collection_config.collection_maximum,
                token_uri,
                collection_config.royalty_payee_address,
                collection_config.royalty_points_denominator,
                collection_config.royalty_points_numerator,
                collection_config.token_mutate_config,
                property_keys, property_values, property_types
            );

        let token_data_id = create_token_data_id(candymachine, collection_config.collection_name, token_name);
        // mint_token_to(&resource_signer, nft_claimer_addr, token_data_id, 1);

        let token_id = mint_token(&resource_signer_from_cap, token_data_id, 1);
        direct_transfer(&resource_signer_from_cap, nft_claimer, token_id, 1);

        // Update counter
        collection_config.token_counter = collection_config.token_counter + 1;
        
        event::emit_event<NFTMintMintingEvent>(
            &mut resource_info.token_minting_events,
            NFTMintMintingEvent {
                token_receiver_address: nft_claimer_addr,
                token_id,
            }
        );
    }

    // fun assert_is_admin(addr: address) acquires NFTMachineConfig {
    //     let admin = borrow_global<NFTMachineConfig>(@nftmachine).admin;
    //     assert!(addr == admin, error::permission_denied(ENOT_ADMIN));
    // }

    fun u64_to_string(value: u64): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }
}