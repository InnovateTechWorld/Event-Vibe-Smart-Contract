module memory::photo;
use std::string::String;
use sui::clock::Clock;

use memory::{
    config,
    app::{Application, TagHandlerPhoto},
    event::{Self, Event},
    types::{Location, Self},
    tag_service,
    emit_event::Self
    };

// --- Errors ---
#[error]
const EInvalidEventState: vector<u8> = b"Input valid event";
#[error]
const EInvalidLenTags: vector<u8> = b"Input valid len tag";
#[error]
const EHasLiked: vector<u8> = b"Like another photo";
#[error]
const EEventTimeAhead: vector<u8> = b"Event not started";

// --- Object ---

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

// --- Entry Functions ---

public fun add_image(
    application: &mut Application,
    event: &mut Event,
    tag_handler_photo: &mut TagHandlerPhoto,
    name: String,
    image: String,
    long: u64,
    lat: u64,
    metadata_tag: vector<String>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(config::get_tag_length() == metadata_tag.length(), EInvalidLenTags);
    assert!(event.time() < clock.timestamp_ms(), EEventTimeAhead);

    let location = types::location( long, lat );

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

    if (types::same_location(&location, event.location())) {
        event::add_user(event, ctx);
        let user_card = event::get_user_by_event_mut(event, ctx.sender());
        user_card.add_submit();
    };

    application.add_image_count();
    event.add_total_image();
    
    let photo_id = object::id(&pic);

    let mut i = 0;
    let tags_vec = &pic.tags; // borrow
    while (i < config::get_tag_length()) {
        tag_service::add_tag_libary_photo(tag_handler_photo, tags_vec[i], photo_id);
        i = 1 + i;
    };

    event::add_photo_id_to_event(event, photo_id);

    emit_event::new_image(
        object::id(event),
        photo_id,
        ctx.sender(),
    );

    transfer::public_share_object(pic);
}

public fun like_pic(
    application: &mut Application,
    event: &mut Event,
    photo: &mut Photo,
    ctx: &mut TxContext,
) {
    let photo_id = object::id(photo);
    assert!(event::check_if_in_event(event, photo_id), EInvalidEventState);
    assert!(!has_liked(event, photo_id, ctx), EHasLiked);

    photo.total_likes = 1 + photo.total_likes;
    event.add_total_likes();
    application.add_total_likes();

    emit_event::new_like(
        object::id(event),
        photo_id,
        photo.total_likes,
    );

    event::add_user(event, ctx);
    let user_card = event::get_user_by_event_mut(event, ctx.sender());
    user_card.mut_vote()
        .push_back(photo_id);

    if (ctx.sender() == photo.creator) {
        user_card.add_deduct()
    };
}

// --- Private Functions ---

fun has_liked(event: &Event, photo_id: ID, ctx: &TxContext): bool {
    let user_card = event::get_user_by_event(event, ctx.sender());
    user_card.vote()
        .contains(&photo_id)
}
