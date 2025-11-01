module memory::app;
use sui::dynamic_field as dfield;


// --- Singleton Objects ---

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

// ===================== package helpers UID

// photo tag 
public(package) fun mut_photo_tag_handler_uid(t: &mut TagHandlerPhoto): &mut UID{
    &mut t.id
}

public(package) fun photo_tag_handler_uid(t: &TagHandlerPhoto): &UID{
    &t.id
}


// event
public(package) fun mut_event_tag_handler_uid(t: &mut TagHandlerEvent): &mut UID{
    &mut t.id
}

public(package) fun event_tag_handler_uid(t: &TagHandlerEvent): &UID{
    &t.id
}


// category
public(package) fun mut_category_uid(c: &mut Category): &mut UID{
    &mut c.id
}

public(package) fun category_uid(c: &Category): &UID{
    &c.id
}


// ==================== application view =============
public fun event_counts(app: &Application): u256{
    app.event_counts
}

public fun image_count(app: &Application): u256{
    app.image_count
}

public fun support(app: &Application): u64{
    app.support
}

public fun total_likes(app: &Application): u256{
    app.total_likes
}


// --- Initialization ---

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

// --- Internal (package) Functions for Application Storage ---

public(package) fun add_event_id(application: &mut Application, event_id: ID) {
    let index = application.event_counts;
   
    dfield::add<u256, ID>(&mut application.id, index, event_id);
}

public(package) fun get_event_id(application: &Application, index: u256): ID {
    *dfield::borrow<u256, ID>(&application.id, index)
}

public(package) fun add_profile_id(application: &mut Application, profile: ID, user: address) {
    dfield::add<address, ID>(&mut application.id, user, profile);
}

public(package) fun has_created_profile(application: &Application, user: address): bool {
    dfield::exists_(&application.id, user)
}

public(package) fun get_profile_id_by_address(application: &Application, user: address): ID {
    *dfield::borrow<address, ID>(&application.id, user)
}

public(package) fun add_event_count(application: &mut Application){
    application.event_counts = 1 + application.event_counts;
}


public(package) fun add_image_count(application: &mut Application){
    application.image_count = 1 + application.image_count;
}

public(package) fun add_total_likes(application: &mut Application){
    application.total_likes = 1 + application.total_likes;
}
