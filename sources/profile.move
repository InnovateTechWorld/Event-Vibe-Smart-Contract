module memory::profile;

use std::string::{String};
use sui::transfer;
use sui::object;
use sui::tx_context::{TxContext};

use memory::memory;

// Structs
public struct User has key, store {
    id: UID,
    vote: vector<ID>,
    deduct: u64,
    submit: u64,
    has_claimed: bool,
}

public struct Profile has key {
    id: UID,
    name: String,
    image: String,
    email: String,
    event_list: vector<ID>,
    claimedNft_list: vector<ID>,
}

public struct ProfileView has drop {
    id: ID,
    name: String,
    email: String,
    event_list: vector<ID>,
    claimedNft_list: vector<ID>,
}

public struct AppView {
    id: ID,
    event_counts: u256,
    image_count: u256,
    support: u64,
    total_likes: u256,
}

// Functions
public fun set_profile(
    application: &mut memory::Application,
    name: String,
    image: String,
    email: String,
    ctx: &mut TxContext
) {
    assert!(!memory::has_created_profile(application, ctx.sender()), memory::EProfileCreationConflit);
    let profile = Profile {
        id: object::new(ctx),
        name,
        image,
        email,
        event_list: vector::empty<ID>(),
        claimedNft_list: vector::empty<ID>(),
    };
    memory::add_profile_id(application, object::id(&profile), ctx.sender());
    transfer::transfer(profile, ctx.sender());
}

public fun edit_profile(profile: &mut Profile, name: String, image: String, email: String) {
    profile.name = name;
    profile.image = image;
    profile.email = email;
}

public fun viewApplications(app: &memory::Application): AppView {
    AppView {
        id: object::id(app),
        event_counts: app.event_counts,
        image_count: app.image_count,
        support: app.support,
        total_likes: app.total_likes,
    }
}

public fun profile_view(profile: &Profile): ProfileView {
    ProfileView {
        id: object::id(profile),
        name: profile.name,
        email: profile.email,
        event_list: profile.event_list,
        claimedNft_list: profile.claimedNft_list,
    }
}