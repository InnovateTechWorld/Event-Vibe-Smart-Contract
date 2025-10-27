module memory::MEMO;

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

// Shared structs
public struct Application has key, store {
    id: UID,
    event_counts: u256,
    image_count: u256,
    support: u64,
    total_likes: u256,
}

public struct TagHandlerPhoto has key, store {
    id: UID,
}

public struct TagHandlerEvent has key, store {
    id: UID,
}

public struct Category has key, store {
    id: UID,
}

// Errors (shared)
#[error]
const EInvalidEventParameters: vector<u8> = b"empty data";
#[error]
const EInvalidTimeParameter: vector<u8> = b"invalid timestamp";
#[error]
const EInvalidEventImageParameter: vector<u8> = b"empty component";
#[error]
const EInvalidEventState: vector<u8> = b"Input valid event";
#[error]
const EInvalidLenTags: vector<u8> = b"Input valid len tag";
#[error]
const EHasLiked: vector<u8> = b"Like another photo";
#[error]
const EClaimedNft: vector<u8> = b"Nft has been claimed";
#[error]
const EEventTimeAhead: vector<u8> = b"Event not started";
#[error]
const EMeetCriteria: vector<u8> = b"criteria not meet";
#[error]
const EProfileCreationConflit: vector<u8> = b"profile exist";
#[error]
const EInvalidRange: vector<u8> = b"enter valid range";
#[error]
const EInsufficentEventFee: vector<u8> = b"add coin";

fun init(ctx: &mut TxContext) {
    let application = Application {
        id: object::new(ctx),
        event_counts: 0,
        image_count: 0,
        support: 0,
        total_likes: 0,
    };

    let tag_handler_event = TagHandlerEvent {
        id: object::new(ctx),
    };

    let tag_handler_photo = TagHandlerPhoto {
        id: object::new(ctx),
    };

    let new_category = Category {
        id: object::new(ctx),
    };

    transfer::public_share_object(application);
    transfer::public_share_object(tag_handler_photo);
    transfer::public_share_object(tag_handler_event);
    transfer::public_share_object(new_category);
}

// Shared helper functions
fun add_event_id(application: &mut Application, event: memory::event::EventPlaceHolder) {
    let index = application.event_counts;
    dfield::add<u256, memory::event::EventPlaceHolder>(&mut application.id, index, event);
}

fun get_event_id(application: &Application, index: u256): &memory::event::EventPlaceHolder {
    dfield::borrow<u256, memory::event::EventPlaceHolder>(&application.id, index)
}

fun add_profile_id(application: &mut Application, profile: ID, user: address) {
    dfield::add<address, ID>(&mut application.id, user, profile);
}

public fun has_created_profile(application: &Application, user: address): bool {
    dfield::exists_(&application.id, user)
}

public fun get_profile_id_by_address(application: &Application, user: address): ID {
    *dfield::borrow<address, ID>(&application.id, user)
}

fun add_tag_libary_event(tag_handler_event: &mut TagHandlerEvent, tag: String, event_id: ID) {
    if (dfield::exists_(&tag_handler_event.id, tag)) {
        let state_ids: &mut vector<ID> = get_mut_obj_list_event(tag_handler_event, tag);
        state_ids.push_back(event_id);
        return;
    };
    let mut new_id_list: vector<ID> = vector::empty<ID>();
    new_id_list.push_back(event_id);
    dfield::add<String, vector<ID>>(&mut tag_handler_event.id, tag, new_id_list);
}

fun get_mut_obj_list_event(tag_handler_event: &mut TagHandlerEvent, tag: String): &mut vector<ID> {
    dfield::borrow_mut<String, vector<ID>>(&mut tag_handler_event.id, tag)
}

fun get_obj_list_event(tag_handler_event: &TagHandlerEvent, tag: String): &vector<ID> {
    dfield::borrow<String, vector<ID>>(&tag_handler_event.id, tag)
}

fun add_to_category(category_object: &mut Category, category: String, event_id: ID) {
    if (dfield::exists_(&category_object.id, category)) {
        let state_ids: &mut vector<ID> = get_mut_obj_list_category(category_object, category);
        state_ids.push_back(event_id);
        return;
    };
    let mut new_id_list: vector<ID> = vector::empty<ID>();
    new_id_list.push_back(event_id);
    dfield::add<String, vector<ID>>(&mut category_object.id, category, new_id_list);
}

public fun get_mut_obj_list_category(category_object: &mut Category, category: String): &mut vector<ID> {
    dfield::borrow_mut<String, vector<ID>>(&mut category_object.id, category)
}

fun add_tag_libary_photo(tag_handler_photo: &mut TagHandlerPhoto, tag: String, photo_id: ID) {
    if (dfield::exists_(&tag_handler_photo.id, tag)) {
        let state_ids: &mut vector<ID> = get_mut_obj_list_photo(tag_handler_photo, tag);
        state_ids.push_back(photo_id);
        return;
    };
    let mut new_id_list: vector<ID> = vector::empty<ID>();
    new_id_list.push_back(photo_id);
    dfield::add<String, vector<ID>>(&mut tag_handler_photo.id, tag, new_id_list);
}

fun get_mut_obj_list_photo(tag_handler_photo: &mut TagHandlerPhoto, tag: String): &mut vector<ID> {
    dfield::borrow_mut<String, vector<ID>>(&mut tag_handler_photo.id, tag)
}

fun get_obj_list_photo(tag_handler_photo: &TagHandlerPhoto, tag: String): &vector<ID> {
    dfield::borrow<String, vector<ID>>(&tag_handler_photo.id, tag)
}