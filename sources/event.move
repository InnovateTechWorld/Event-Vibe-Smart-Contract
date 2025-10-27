module memory::event;

use std::string::{String};
use sui::sui::SUI;
use sui::coin::{Coin};
use sui::clock::Clock;
use sui::dynamic_field as dfield;
use sui::dynamic_object_field as ofields;
use sui::event;
use sui::transfer;
use sui::object;
use sui::tx_context::{TxContext};
use sui::vec_map::{Self, VecMap};
use sui::vec_set::{Self, VecSet};

use memory::config;
use memory::memory;
use memory::profile;

// Structs
public struct Location has store, copy, drop {
    long: u64,
    lat: u64,
}

public struct ImageMetaData has store, copy {
    event_profile: String,
    event_bannar: String,
}

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
    event_reward: POAP,
    total_images: u256,
    total_likes: u256,
}

public struct EventPlaceHolder has store {
    event_id: ID,
}

public struct Photo has key, store {
    id: UID,
    creator: address,
    name: String,
    image: String,
    time_taken: u64,
    location: Location,
    tags: vector<String>,
    total_likes: u256,
}

public struct PhotoPlaceHolder has store {
    photo_id: ID,
}

// Event structs
public struct NewEvent has copy, drop {
    event_id: ID,
    creator: address,
}

public struct NewImage has copy, drop {
    event_id: ID,
    image_id: ID,
    creator: address,
}

public struct NewLike has copy, drop {
    event_id: ID,
    image_id: ID,
    like_count: u256,
}

public struct ClaimedNft has copy, drop {
    event_id: ID,
    nft_id: ID,
    claimer: address,
}

// Functions (adjusted for cross-module calls)
public fun create_event(
    application: &mut memory::Application,
    profile: &mut memory::profile::Profile,
    tag_handler_event: &mut memory::TagHandlerEvent,
    category_object: &mut memory::Category,
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
    ctx: &mut TxContext
) {
    assert!(time > clock.timestamp_ms(), memory::EInvalidTimeParameter);
    assert!(!name.is_empty() && !description.is_empty(), memory::EInvalidEventParameters);
    assert!(!event_bannar.is_empty() && !event_profile.is_empty(), memory::EInvalidEventImageParameter);
    assert!(coin.value() >= config::get_event_creation_fee(), memory::EInsufficentEventFee);
    let fee = coin.split<SUI>(config::get_event_creation_fee(), ctx);
    transfer::public_transfer(fee, config::get_admin_address());
    let location = Location { long, lat };
    let event_images = ImageMetaData { event_profile, event_bannar };
    let reward = POAP {
        id: object::new(ctx),
        name: reward_name,
        description: reward_description,
        image: reward_image,
        event_id: @0x0,
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
    let old_count = application.event_counts;
    application.event_counts = 1 + old_count;
    let event_holder = EventPlaceHolder { event_id: object::id(&event) };
    event::emit(NewEvent { event_id: object::id(&event), creator: ctx.sender() });
    let mut i = 0;
    while (i < event_name_tag.length()) {
        memory::add_tag_libary_event(tag_handler_event, event_name_tag[i], event_holder.event_id);
        i = 1 + i;
    };
    memory::add_to_category(category_object, category, event_holder.event_id);
    memory::add_event_id(application, event_holder);
    profile.event_list.push_back(object::id(&event));
    transfer::public_share_object(event);
}

public fun add_image(
    application: &mut memory::Application,
    event: &mut Event,
    tag_handler_photo: &mut memory::TagHandlerPhoto,
    name: String,
    image: String,
    long: u64,
    lat: u64,
    metadata_tag: vector<String>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    assert!(config::get_tag_length() == metadata_tag.length(), memory::EInvalidLenTags);
    assert!(event.time < clock.timestamp_ms(), memory::EEventTimeAhead);
    let location = Location { long, lat };
    let pic = Photo {
        id: object::new(ctx),
        creator: ctx.sender(),
        name,
        image,
        time_taken: clock.timestamp_ms(),
        location,
        tags: metadata_tag,
        total_likes: 0,
    };
    if (location == event.location) {
        add_user(event, ctx);
        let user_card: &mut memory::profile::User = get_user_by_event(event, ctx.sender());
        let old_submit = user_card.submit;
        user_card.submit = 1 + old_submit;
    };
    let old_im_count_app = application.image_count;
    application.image_count = 1 + old_im_count_app;
    let old_pic_count_ev = event.total_images;
    event.total_images = 1 + old_pic_count_ev;
    let photo_holder = PhotoPlaceHolder { photo_id: object::id(&pic) };
    let mut i = 0;
    while (i < config::get_tag_length()) {
        memory::add_tag_libary_photo(tag_handler_photo, metadata_tag[i], photo_holder.photo_id);
        i = 1 + i;
    };
    add_photo_id(event, photo_holder);
    event::emit(NewImage { event_id: object::id(event), image_id: object::id(&pic), creator: ctx.sender() });
    transfer::public_share_object(pic);
}

public fun like_pic(
    application: &mut memory::Application,
    event: &mut Event,
    photo: &mut Photo,
    ctx: &mut TxContext
) {
    assert!(check_if_in_event(event, object::id(photo)), memory::EInvalidEventState);
    assert!(!has_liked(event, photo, ctx), memory::EHasLiked);
    let old_photo_likes = photo.total_likes;
    photo.total_likes = 1 + old_photo_likes;
    let old_event_total_likes = event.total_likes;
    event.total_likes = 1 + old_event_total_likes;
    let old_application_likes = application.total_likes;
    application.total_likes = 1 + old_application_likes;
    event::emit(NewLike { event_id: object::id(event), image_id: object::id(photo), like_count: photo.total_likes });
    add_user(event, ctx);
    let user_card: &mut memory::profile::User = get_user_by_event(event, ctx.sender());
    user_card.vote.push_back(object::id(photo));
    if (ctx.sender() == photo.creator) {
        let d_n = user_card.deduct;
        user_card.deduct = 1 + d_n;
    };
}

#[allow(lint(self_transfer))]
public fun claim_nft(
    event: &mut Event,
    profile: &mut memory::profile::Profile,
    ctx: &mut TxContext
) {
    assert!(!has_claimed(event, ctx), memory::EClaimedNft);
    assert!(meet_criteria(event, ctx), memory::EMeetCriteria);
    let reward = POAP {
        id: object::new(ctx),
        name: event.event_reward.name,
        description: event.event_reward.description,
        image: event.event_reward.image,
        event_id: object::uid_to_address(&event.id),
        organizer: event.creator,
    };
    event::emit(ClaimedNft { event_id: object::id(event), nft_id: object::id(&reward), claimer: ctx.sender() });
    let user_card = get_user_by_event(event, ctx.sender());
    user_card.has_claimed = true;
    profile.claimedNft_list.push_back(object::id(&reward));
    transfer::transfer(reward, ctx.sender());
}

public fun meet_criteria(event: &Event, ctx: &TxContext): bool {
    let user_card: &memory::profile::User = ofields::borrow(&event.id, ctx.sender());
    let vote_count = user_card.vote.length() - user_card.deduct;
    if (user_card.submit < config::get_criteria_submit() || vote_count < config::get_criteria_vote()) {
        return false;
    };
    return true;
}

// Helper functions for events/photos
fun add_photo_id(event: &mut Event, photo: PhotoPlaceHolder) {
    create_photo_tag(event, photo.photo_id);
    let index = event.total_images;
    dfield::add<u256, PhotoPlaceHolder>(&mut event.id, index, photo);
}

fun create_photo_tag(event: &mut Event, photo: ID) {
    dfield::add<ID, u8>(&mut event.id, photo, 1);
}

fun check_if_in_event(event: &Event, photo: ID): bool {
    dfield::exists_(&event.id, photo)
}

fun add_user(event: &mut Event, ctx: &mut TxContext) {
    if (ofields::exists_(&event.id, ctx.sender())) {
        return;
    };
    let new_user = memory::profile::User {
        id: object::new(ctx),
        vote: vector::empty<ID>(),
        deduct: 0,
        submit: 0,
        has_claimed: false,
    };
    let user = ctx.sender();
    ofields::add<address, memory::profile::User>(&mut event.id, user, new_user);
}

fun get_user_by_event(event: &mut Event, user: address): &mut memory::profile::User {
    ofields::borrow_mut<address, memory::profile::User>(&mut event.id, user)
}

public fun has_liked(event: &Event, photo: &Photo, ctx: &TxContext): bool {
    let user_card: &memory::profile::User = ofields::borrow(&event.id, ctx.sender());
    user_card.vote.contains(&object::id(photo))
}

public fun has_claimed(event: &Event, ctx: &TxContext): bool {
    let user_card: &memory::profile::User = ofields::borrow(&event.id, ctx.sender());
    user_card.has_claimed
}

// View and search functions (moved here as they relate to events/photos)
public struct LocationView has drop {
    long: u64,
    lat: u64,
}

public struct ImageView has drop {
    event_profile: String,
    event_bannar: String,
}

public struct EventView has drop {
    id: ID,
    creator: address,
    time: u64,
    location: LocationView,
    name: String,
    description: String,
    event_images: ImageView,
    total_images: u256,
    total_likes: u256,
}

public struct PhotoView has drop {
    id: ID,
    creator: address,
    name: String,
    image: String,
    time_taken: u64,
    location: LocationView,
    total_likes: u256,
}

public struct SearchResult has drop {
    ids: vector<ID>,
    values: vector<u64>,
}

public fun viewEvent(application: &memory::Application, start_index: u256, end_index: u256): vector<ID> {
    assert!(start_index < end_index && start_index != end_index && application.event_counts >= end_index, memory::EInvalidRange);
    let mut result: vector<ID> = vector::empty<ID>();
    let mut b = start_index;
    while (b <= end_index) {
        let event_ = memory::get_event_id(application, b);
        result.push_back(event_.event_id);
        b = b + 1;
    };
    return result;
}

public fun viewPhotos(event: &Event, start_index: u256, end_index: u256): vector<ID> {
    assert!(start_index < end_index && start_index != end_index && event.total_images >= end_index, memory::EInvalidRange);
    let mut result: vector<ID> = vector::empty<ID>();
    let mut b = start_index;
    while (b <= end_index) {
        let photo_ = dfield::borrow<u256, PhotoPlaceHolder>(&event.id, b);
        result.push_back(photo_.photo_id);
        b = b + 1;
    };
    return result;
}

public fun event_view(event: &Event): EventView {
    let image = ImageView {
        event_profile: event.event_images.event_profile,
        event_bannar: event.event_images.event_bannar,
    };
    let location = LocationView {
        long: event.location.long,
        lat: event.location.lat,
    };
    EventView {
        id: object::id(event),
        creator: event.creator,
        time: event.time,
        location,
        name: event.name,
        description: event.description,
        event_images: image,
        total_images: event.total_images,
        total_likes: event.total_likes,
    }
}

public fun photo_view(photo: &Photo): PhotoView {
    let location = LocationView {
        long: photo.location.long,
        lat: photo.location.lat,
    };
    PhotoView {
        id: object::id(photo),
        creator: photo.creator,
        name: photo.name,
        image: photo.image,
        time_taken: photo.time_taken,
        location,
        total_likes: photo.total_likes,
    }
}

public fun search(event: &Event, tag_handler_photo: &memory::TagHandlerPhoto, tags: vector<String>): SearchResult {
    assert!(config::get_tag_length() == tags.length(), memory::EInvalidLenTags);
    let mut results_id: vector<ID> = vector::empty<ID>();
    let mut results_value: vector<u64> = vector::empty<u64>();
    let mut i = 0;
    while (i < tags.length()) {
        let state_id_list = memory::get_obj_list_photo(tag_handler_photo, tags[i]);
        let mut j = 0;
        while (j < state_id_list.length()) {
            let (st, index) = results_id.index_of(&state_id_list[j]);
            if (st) {
                let inner_count = results_value.borrow_mut(index);
                *inner_count = *inner_count + 1;
            } else {
                results_id.push_back(state_id_list[j]);
                results_value.push_back(1);
            };
            j = 1 + j;
        };
        i = 1 + i;
    };
    assert!(results_id.length() == results_value.length(), 1);
    let mut p = 0;
    while (p < results_value.length()) {
        if (results_value[p] < config::get_common_factor() || !check_if_in_event(event, results_id[p])) {
            results_value.swap_remove(p);
            results_id.swap_remove(p);
        } else {
            p = p + 1;
        };
    };
    assert!(results_id.length() == results_value.length(), 1);
    let mut m = 0;
    while (m < results_id.length()) {
        let mut p = 1 + m;
        while (p < results_id.length()) {
            let m_position_value = results_value[m];
            let p_position_value = results_value[p];
            if (p_position_value > m_position_value) {
                let temp = results_value[m];
                *results_value.borrow_mut(m) = results_value[p];
                *results_value.borrow_mut(p) = temp;
                let temp = results_id[m];
                *results_id.borrow_mut(m) = results_id[p];
                *results_id.borrow_mut(p) = temp;
            };
            p = 1 + p;
        };
        m = 1 + m;
    };
    SearchResult { ids: results_id, values: results_value }
}

public fun search_event(tag_handler_event: &memory::TagHandlerEvent, tags: vector<String>): SearchResult {
    let mut results_id: vector<ID> = vector::empty<ID>();
    let mut results_value: vector<u64> = vector::empty<u64>();
    let mut i = 0;
    while (i < tags.length()) {
        let state_id_list = memory::get_obj_list_event(tag_handler_event, tags[i]);
        let mut j = 0;
        while (j < state_id_list.length()) {
            let (st, index) = results_id.index_of(&state_id_list[j]);
            if (st) {
                let inner_count = results_value.borrow_mut(index);
                *inner_count = *inner_count + 1;
            } else {
                results_id.push_back(state_id_list[j]);
                results_value.push_back(1);
            };
            j = 1 + j;
        };
        i = 1 + i;
    };
    assert!(results_id.length() == results_value.length(), 1);
    let mut p = 0;
    while (p < results_value.length()) {
        if (results_value[p] < tags.length()) {
            results_value.swap_remove(p);
            results_id.swap_remove(p);
        } else {
            p = p + 1;
        };
    };
    assert!(results_id.length() == results_value.length(), 1);
    let mut m = 0;
    while (m < results_id.length()) {
        let mut p = 1 + m;
        while (p < results_id.length()) {
            let m_position_value = results_value[m];
            let p_position_value = results_value[p];
            if (p_position_value > m_position_value) {
                let temp = results_value[m];
                *results_value.borrow_mut(m) = results_value[p];
                *results_value.borrow_mut(p) = temp;
                let temp = results_id[m];
                *results_id.borrow_mut(m) = results_id[p];
                *results_id.borrow_mut(p) = temp;
            };
            p = 1 + p;
        };
        m = 1 + m;
    };
    SearchResult { ids: results_id, values: results_value }
}