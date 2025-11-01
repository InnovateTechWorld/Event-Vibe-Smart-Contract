module memory::profile;
use std::string::String;
use memory::app::{Self, Application};

// --- Object ---

public struct Profile has key {
    id: UID,
    name: String,
    image: String,
    email: String,
    event_list: vector<ID>,
    claimedNft_list: vector<ID>,
}

// --- Errors ---

#[error]
const EProfileCreationConflit: vector<u8> = b"profile exist";

// ======= package functions
public(package) fun event_list(p: &mut Profile): &mut vector<ID>{
    &mut p.event_list
}

public(package) fun claimedNft_list(p: &mut Profile): &mut vector<ID>{
    &mut p.claimedNft_list
}



// --- Entry Functions ---


public fun set_profile(
    application: &mut Application,
    name: String,
    image: String,
    email: String,
    ctx: &mut TxContext,
) {
    assert!(!app::has_created_profile(application, ctx.sender()), EProfileCreationConflit);
    let profile = Profile {
        id: object::new(ctx),
        name: name,
        image: image,
        email: email,
        event_list: vector::empty<ID>(),
        claimedNft_list: vector::empty<ID>(),
    };

    app::add_profile_id(application, object::id(&profile), ctx.sender());
    transfer::transfer(profile, ctx.sender());
}

public fun edit_profile(profile: &mut Profile, name: String, image: String, email: String) {
    profile.name = name;
    profile.image = image;
    profile.email = email;
}
