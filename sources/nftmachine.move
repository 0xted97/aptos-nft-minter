module nftmachine_addr::nftmachine {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Option};

    use aptos_framework::account::{Self, SignerCapability, create_resource_account, create_signer_with_capability};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_token::token::{
        Self, TokenId, CollectionMutabilityConfig, TokenMutabilityConfig, 
        create_tokendata, create_token_data_id, mint_token, direct_transfer, 
        create_collection_mutability_config, create_token_mutability_config, 
        mutate_collection_description, mutate_collection_uri, mutate_collection_maximum,
        mutate_tokendata_description, mutate_tokendata_uri ,mutate_tokendata_royalty, mutate_tokendata_property,
        get_collection_supply, get_token_supply,
        get_collection_mutability_description, get_collection_mutability_uri, get_collection_mutability_maximum,
    };

    // Errors
    const ENOT_ADMIN: u64 = 0;
    const ENO_COIN_CAP: u64 = 1;
    const ENOT_ALREADY: u64 = 2;
    const EINVALID_ROYALTY_NUMERATOR_DENOMINATOR: u64 = 3;
    const EINVALID_MUTABLE_CONFIG:u64 = 7;
    const EINVALID_PRICE: u64 = 8;
    const ENOT_ALREADY_COLLECTION: u64 = 12;
    const EALREADY_COLLECTION_CREATED: u64 = 13;


    struct NFTMachineConfig has key {
        admin: address,
        treasury: address,
    }

    struct ResourceInfo has key {
        source: address,
        resource_cap: SignerCapability,
        token_minting_events: EventHandle<NFTMintMintingEvent>,
        collection_update_events: EventHandle<NFTUpdateEvent>,
    }

    struct NFTMintMintingEvent has drop, store {
        token_receiver_address: address,
        token_id: TokenId
    }

    struct NFTUpdateEvent has drop, store {
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
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
        token_base_name: String,
        token_description: String,
        // Token Config
        token_mutate_config: TokenMutabilityConfig,
    }

    struct PublicMintConfig has key {
       public_mint_price: u64,
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
        collection_maximum: u64,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        collection_mutate_config: vector<bool>,
        // Token
        token_base_name: String,
        token_description: String,
        token_mutate_config: vector<bool>,
        seeds: vector<u8>
    ) {
        let (resource, resource_cap) = create_resource_account(account, seeds);
        let resource_signer_from_cap = create_signer_with_capability(&resource_cap);
        let account_addr = signer::address_of(account);

        // Start Validate inputs here.
        assert!(vector::length(&collection_mutate_config) == 3 && vector::length(&token_mutate_config) == 5, EINVALID_MUTABLE_CONFIG);
        assert!(royalty_points_denominator > 0, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        assert!(royalty_points_numerator <= royalty_points_denominator, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);

        // End Validate inputs here.

        // Token
        move_to<ResourceInfo>(&resource_signer_from_cap, ResourceInfo {
            source: account_addr,
            resource_cap: resource_cap,
            token_minting_events: account::new_event_handle<NFTMintMintingEvent>(&resource_signer_from_cap),
            collection_update_events: account::new_event_handle<NFTUpdateEvent>(&resource_signer_from_cap),
        });

        move_to(&resource_signer_from_cap, CollectionConfig {
            collection_name,
            collection_description,
            collection_maximum: collection_maximum,
            collection_uri,
            royalty_payee_address,
            royalty_points_numerator,
            royalty_points_denominator,
            collection_mutate_config: create_collection_mutability_config(&collection_mutate_config),
            token_counter: 1,
            // Token
            token_base_name,
            token_description,
            token_mutate_config: create_token_mutability_config(&token_mutate_config),
        });

        token::create_collection(
            &resource_signer_from_cap, 
            collection_name,
            collection_description,
            collection_uri,
            collection_maximum,
            collection_mutate_config
        );
    }

    public entry fun set_mint_public(
        admin: &signer, 
        candymachine: address,
        public_mint_price: u64,
    ) acquires PublicMintConfig, ResourceInfo {
        assert!(exists<ResourceInfo>(candymachine), error::permission_denied(ENOT_ALREADY_COLLECTION));

        let admin_addr = signer::address_of(admin);
        let resource_info = borrow_global_mut<ResourceInfo>(candymachine);

        // Start Validate
        assert!(admin_addr == resource_info.source, error::permission_denied(ENOT_ADMIN));
        assert!(public_mint_price > 0, EINVALID_PRICE);
        
        if(exists<PublicMintConfig>(candymachine)) {
            let public_mint_config = borrow_global_mut<PublicMintConfig>(candymachine);
            public_mint_config.public_mint_price = public_mint_price;
        } else {
            let resource_signer_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);
            move_to(&resource_signer_from_cap, PublicMintConfig {
                public_mint_price,
            });
        }
    }

    /// @dev: Mint one token at once time
    public entry fun mint_public(receiver: &signer, candymachine: address, amount: u64) acquires ResourceInfo, CollectionConfig, PublicMintConfig {
        assert!(exists<PublicMintConfig>(candymachine), error::permission_denied(ENOT_ALREADY_COLLECTION));
        let public_mint_config = borrow_global<PublicMintConfig>(candymachine);
        let public_mint_price = public_mint_config.public_mint_price;

        mint(receiver, candymachine, public_mint_price, amount);
    }

    public entry fun set_whitelist(admin: &signer)  {
      
    }

    public entry fun set_treasury(admin: &signer, candymachine: address ,new_treasury_address: address) acquires NFTMachineConfig {
        let admin_addr = signer::address_of(admin);
        let nft_mint_config = borrow_global_mut<NFTMachineConfig>(candymachine);
        assert!(admin_addr == nft_mint_config.admin, error::permission_denied(ENOT_ADMIN));
        nft_mint_config.treasury = new_treasury_address;
    }

    /// @dev: Update collection_info, mint token will get royalty in collection_info
    public entry fun update_collection(
        admin: &signer, 
        candymachine: address,
        collection_description: String,
        collection_uri: String,
        collection_maximum: u64,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64
    ) acquires CollectionConfig, ResourceInfo {
        // Check exist resource in candymachine like ResourceInfo, CollectionConfig
        assert!(exists<CollectionConfig>(candymachine), error::permission_denied(ENOT_ALREADY_COLLECTION));
        assert!(exists<ResourceInfo>(candymachine), error::permission_denied(ENOT_ALREADY_COLLECTION));

        let admin_addr = signer::address_of(admin);
        let resource_info = borrow_global_mut<ResourceInfo>(candymachine);
        let collection_config = borrow_global_mut<CollectionConfig>(candymachine);

        // Start Validate
        assert!(admin_addr == resource_info.source, error::permission_denied(ENOT_ADMIN));
        assert!(royalty_points_denominator > 0, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        assert!(royalty_points_numerator <= royalty_points_denominator, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        // End Validate

        collection_config.collection_description = collection_description;
        collection_config.collection_uri = collection_uri;
        collection_config.collection_maximum = collection_maximum;
        collection_config.royalty_payee_address = royalty_payee_address;
        collection_config.royalty_points_numerator = royalty_points_numerator;
        collection_config.royalty_points_denominator = royalty_points_denominator;

        // Update collection resource
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);
        // Get muate direct from resource_info becasue config cannot change
        let collection_mutate_config = collection_config.collection_mutate_config;
        let is_mutate_description = get_collection_mutability_description(&collection_mutate_config);
        let is_mutate_uri =  get_collection_mutability_uri(&collection_mutate_config);
        let is_mutate_maximum =  get_collection_mutability_maximum(&collection_mutate_config);

        // Check mutate of description, uri, maximum before update
        if (is_mutate_description) {
            mutate_collection_description(&resource_signer_from_cap, collection_config.collection_name, collection_description);
        };

        if (is_mutate_uri) {
            mutate_collection_uri(&resource_signer_from_cap, collection_config.collection_name, collection_uri);
        };
        
        if (is_mutate_maximum) {
            mutate_collection_maximum(&resource_signer_from_cap, collection_config.collection_name, collection_maximum);
        };

        // Emit event
        event::emit_event<NFTUpdateEvent>(
            &mut resource_info.collection_update_events,
            NFTUpdateEvent {
                royalty_payee_address,
                royalty_points_numerator,
                royalty_points_denominator
            }
        );
        
    }

    /// @dev: Update token info: desciption, uri, royalty
    /// NODE: cannot update batch of tokens in the same time
    public entry fun update_token(
        admin: &signer, 
        candymachine: address,
        token_name: String,
        token_description: String,
        token_uri: String,
        royalty_points_numerator: u64,
        royalty_points_denominator: u64,
        property_keys: vector<String>, property_values: vector<vector<u8>>, property_types: vector<String>
    ) acquires CollectionConfig, ResourceInfo {
        // Check exist resource in candymachine like ResourceInfo, CollectionConfig
        assert!(exists<ResourceInfo>(candymachine), error::permission_denied(ENOT_ALREADY_COLLECTION));
        assert!(exists<CollectionConfig>(candymachine), error::permission_denied(ENOT_ALREADY_COLLECTION));
        
        let admin_addr = signer::address_of(admin);
        let resource_info = borrow_global_mut<ResourceInfo>(candymachine);
        let collection_config = borrow_global_mut<CollectionConfig>(candymachine);

        // Start validate
        assert!(admin_addr == resource_info.source, error::permission_denied(ENOT_ADMIN));
        assert!(royalty_points_denominator > 0, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        assert!(royalty_points_numerator <= royalty_points_denominator, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        // End validate

        // Update token
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);
        let token_data_id = create_token_data_id(candymachine, collection_config.collection_name, token_name);
        let royalty = token::create_royalty(royalty_points_numerator, royalty_points_denominator, collection_config.royalty_payee_address);

        mutate_tokendata_description(&resource_signer_from_cap, token_data_id, token_description);
        mutate_tokendata_uri(&resource_signer_from_cap, token_data_id, token_uri);
        mutate_tokendata_royalty(&resource_signer_from_cap, token_data_id, royalty);
        mutate_tokendata_property(&resource_signer_from_cap, token_data_id, property_keys, property_values, property_types);
    }
    


    // ======================================================================
    //   view functions //
    // ======================================================================
    #[view]
    public fun get_token_counter(candymachine: address): u64 acquires CollectionConfig {
        borrow_global<CollectionConfig>(candymachine).token_counter
    }

    #[view]
    public fun get_collection_total_supply(creator: address, collection_name: String): Option<u64> {
        get_collection_supply(creator, collection_name)
    }

    #[view]
    public fun get_token_total_supply(creator: address, collection_name: String, token_name: String): Option<u64> {
        let token_data_id = create_token_data_id(creator, collection_name, token_name);
        get_token_supply(creator, token_data_id)
    }

    // ======================================================================
    //   private helper functions //
    // ======================================================================
    fun mint(nft_claimer: &signer, candymachine: address, price: u64, amount: u64) acquires ResourceInfo, CollectionConfig {
        let nft_claimer_addr = signer::address_of(nft_claimer);
        
        let collection_config = borrow_global_mut<CollectionConfig>(candymachine);
        let resource_info = borrow_global_mut<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_info.resource_cap);

        // Transfer Aptos token To Admin's Collection
        coin::transfer<AptosCoin>(nft_claimer, resource_info.source, price * amount);

        let token_name = collection_config.token_base_name;
        string::append_utf8(&mut token_name, b": ");
        
        let token_description = collection_config.token_description;

        // NOTE: Base URI is collection uri, should admin fill them in PublicMintConfig
        let token_uri = collection_config.collection_uri;

        while(amount > 0) {
            let token_id = u64_to_string(collection_config.token_counter);
            string::append(&mut token_name, token_id);
            string::append(&mut token_uri, token_id);

            // NOTE: Default empty property, should admin fill them in PublicMintConfig
            let property_keys = vector::empty<String>();
            let property_values = vector::empty<vector<u8>>();
            let property_types = vector::empty<String>();

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

            // let token_data_id = create_token_data_id(candymachine, collection_config.collection_name, token_name);

            let token_id = mint_token(&resource_signer_from_cap, token_data_id, 1);
            direct_transfer(&resource_signer_from_cap, nft_claimer, token_id, 1);

            event::emit_event<NFTMintMintingEvent>(
                &mut resource_info.token_minting_events,
                NFTMintMintingEvent {
                    token_receiver_address: nft_claimer_addr,
                    token_id,
                }
            );
            
            collection_config.token_counter = collection_config.token_counter + 1;
            amount = amount - 1;
        }

        
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