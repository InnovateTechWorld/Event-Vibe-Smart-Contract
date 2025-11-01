module memory::event;
use std::string::{String};
use sui::{
    sui::SUI,
    coin::{Coin},
    clock::Clock,
    dynamic_field as dfield,
    dynamic_object_field as ofields
    };

use memory::{
    config,
    app::{Application, Category, TagHandlerEvent},
    profile::Profile,
    types::{Location, ImageMetaData, Self},
    tag_service,
    emit_event::Self
    };

// --- Errors ---
#[error]
const EInvalidEventParameters: vector<u8> = b"empty data";
#[error]
const EInvalidTimeParameter: vector<u8> = b"invalid timestamp";
#[error]
const EInvalidEventImageParameter: vector<u8> = b"empty component";
#[error]
const EClaimedNft: vector<u8> = b"Nft has been claimed";
#[error]
const EMeetCriteria: vector<u8> = b"criteria not meet";
#[error]
const EInsufficentEventFee: vector<u8> = b"add coin";

// --- Objects ---

public struct POAP has key, store {
    id: UID,
    name: String,
    description: String,
    image: String,
    event_id: address,
    organizer: address,
}

public struct Event has key, store {
    id: UID,
    creator: address,
    time: u64,
    location: Location,
    name: String,
    description: String,
    event_images: ImageMetaData,
    event_reward: POAP, // The template POAP
    total_images: u256,
    total_likes: u256,
}

// User is an object added as a dynamic field to an Event
public struct User has key, store {
    id: UID,
    vote: vector<ID>,
    deduct: u64,
    submit: u64,
    has_claimed: bool,
}

// ================ views 
public fun location(e: &Event): &Location{
    &e.location
}

public fun time(e: &Event): u64{
    e.time
}

public fun total_images(e: &Event): u256{
    e.total_images
}

public fun get_photo_id(event: &Event, index: u256): ID{
    *dfield::borrow<u256, ID>(&event.id, index)
}

//  ======= mut ref 
public(package) fun mut_vote(u: &mut User): &mut vector<ID>{
    &mut u.vote
}

public fun vote(u: &User): &vector<ID>{
    &u.vote
}



// --- Entry Functions ---

public fun create_event(
    application: &mut Application,
    profile: &mut Profile,
    tag_handler_event: &mut TagHandlerEvent,
    category_object: &mut Category,
    time: u64,
    long: u64,
    lat: u64,
    name: String,
    description: String,
    event_profile: String,
    event_bannar: String,
    reward_name: String,
    reward_description: String,
    reward_image: String,
    event_name_tag: vector<String>,
    category: String,
    coin: &mut Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(time > clock.timestamp_ms(), EInvalidTimeParameter);
    assert!(!name.is_empty() && !description.is_empty(), EInvalidEventParameters);
    assert!(!event_bannar.is_empty() && !event_profile.is_empty(), EInvalidEventImageParameter);
    assert!(coin.value() >= config::get_event_creation_fee(), EInsufficentEventFee);
    
    let fee = coin.split<SUI>(config::get_event_creation_fee(), ctx);
    transfer::public_transfer(fee, config::get_admin_address());
    
    let location : Location = types::location( long, lat );
    let event_images : ImageMetaData = types::image_meta_data( event_profile, event_bannar );

    let reward = POAP {
        id: object::new(ctx),
        name: reward_name,
        description: reward_description,
        image: reward_image,
        event_id: @0x0, // Placeholder
        organizer: ctx.sender(),
    };

    let event = Event {
        id: object::new(ctx),
        creator: ctx.sender(),
        time: clock.timestamp_ms(), 
        location,
        name,
        description,
        event_images,
        event_reward: reward,
        total_images: 0,
        total_likes: 0,
    };

    application.add_event_count();
    let event_id = object::id(&event);

    emit_event::new_event(
        event_id,
        ctx.sender(),
    );

    let mut i = 0;
    while (i < event_name_tag.length()) {
        tag_service::add_tag_libary_event(tag_handler_event, event_name_tag[i], event_id);
        i = 1 + i;
    };

    tag_service::add_to_category(category_object, category, event_id);
    memory::app::add_event_id(application, event_id);

    profile.event_list().push_back(event_id);
    transfer::public_share_object(event);
}

#[allow(lint(self_transfer))]
public fun claim_nft(
    event: &mut Event,
    profile: &mut Profile,
    ctx: &mut TxContext,
) {
    assert!(!has_claimed(event, ctx), EClaimedNft);
    assert!(meet_criteria(event, ctx), EMeetCriteria);
    
    let reward = POAP {
        id: object::new(ctx),
        name: event.event_reward.name,
        description: event.event_reward.description,
        image: event.event_reward.image,
        event_id: object::uid_to_address(&event.id),
        organizer: event.creator,
    };

    emit_event::claimed_nft(
        object::id(event),
        object::id(&reward),
        ctx.sender(),
    );

    let user_card = get_user_by_event_mut(event, ctx.sender());
    user_card.has_claimed = true;
    profile.claimedNft_list().push_back(object::id(&reward));

    transfer::transfer(reward, ctx.sender());
}

// --- Public (non-entry) Functions ---
// Readable by anyone, but not callable as a tx.
public fun meet_criteria(event: &Event, ctx: &TxContext): bool {
    let user_card: &User = ofields::borrow(&event.id, ctx.sender());
    let vote_count = user_card.vote.length() - user_card.deduct;
    if (user_card.submit < config::get_criteria_submit() || vote_count < config::get_criteria_vote()) {
        return false
    };
    true
}

// --- Internal (package) Functions ---
// Called by other modules, e.g., `photo` module.

public(package) fun add_user(event: &mut Event, ctx: &mut TxContext) {
    if (ofields::exists_(&event.id, ctx.sender())) {
        return
    };
    let new_user = User {
        id: object::new(ctx),
        vote: vector::empty<ID>(),
        deduct: 0,
        submit: 0,
        has_claimed: false,
    };
    ofields::add<address, User>(&mut event.id, ctx.sender(), new_user);
}

public(package) fun get_user_by_event_mut(event: &mut Event, user: address): &mut User {
    ofields::borrow_mut<address, User>(&mut event.id, user)
}

public(package) fun get_user_by_event(event: &Event, user: address): &User {
    ofields::borrow<address, User>(&event.id, user)
}

public(package) fun add_photo_id_to_event(event: &mut Event, photo_id: ID) {
    // This function creates a "set" of photos for an event
    // for fast lookups (check_if_in_event).
    dfield::add<ID, u8>(&mut event.id, photo_id, 1);
    
    // It also adds to the paginated list.
    let index = event.total_images;
    dfield::add<u256, ID>(&mut event.id, index, photo_id);
}

public(package) fun check_if_in_event(event: &Event, photo_id: ID): bool {
    dfield::exists_(&event.id, photo_id)
}

public(package) fun add_total_image(event: &mut Event){
    event.total_images = 1 + event.total_images;
}

public(package) fun add_total_likes(event: &mut Event){
        event.total_likes = 1 + event.total_likes;
}


//  ======= user card 
public(package) fun add_submit(user_card: &mut User){
    user_card.submit = 1 + user_card.submit;
}

public(package) fun add_deduct(user_card: &mut User){
     user_card.deduct = 1 + user_card.deduct;
}

// --- Private Functions ---

fun has_claimed(event: &Event, ctx: &TxContext): bool {
    let user_card: &User = ofields::borrow(&event.id, ctx.sender());
    user_card.has_claimed
}
