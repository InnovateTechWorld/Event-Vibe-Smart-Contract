module memory::tag_service;
use std::string::String;
use sui::dynamic_field as dfield;


use memory::app::{TagHandlerPhoto, TagHandlerEvent, Category};

// --- Photo Tag Functions ---

public(package) fun add_tag_libary_photo(tag_handler_photo: &mut TagHandlerPhoto, tag: String, photo_id: ID) {
    if (dfield::exists_(tag_handler_photo.photo_tag_handler_uid(), tag)) {
        let state_ids: &mut vector<ID> = get_mut_obj_list_photo(tag_handler_photo, tag);
        state_ids.push_back(photo_id);
        return
    };
    
    let mut new_id_list: vector<ID> = vector::empty<ID>();
    new_id_list.push_back(photo_id);
    dfield::add<String, vector<ID>>(tag_handler_photo.mut_photo_tag_handler_uid(), tag, new_id_list);
}

fun get_mut_obj_list_photo(tag_handler_photo: &mut TagHandlerPhoto, tag: String): &mut vector<ID> {
    dfield::borrow_mut<String, vector<ID>>(tag_handler_photo.mut_photo_tag_handler_uid(), tag)
}

public(package) fun get_obj_list_photo(tag_handler_photo: &TagHandlerPhoto, tag: String): &vector<ID> {
    dfield::borrow<String, vector<ID>>(tag_handler_photo.photo_tag_handler_uid(), tag)
}

// --- Event Tag Functions ---

public(package) fun add_tag_libary_event(tag_handler_event: &mut TagHandlerEvent, tag: String, event_id: ID) {
    if (dfield::exists_(tag_handler_event.event_tag_handler_uid(), tag)) {
        let state_ids: &mut vector<ID> = get_mut_obj_list_event(tag_handler_event, tag);
        state_ids.push_back(event_id);
        return
    };
    
    let mut new_id_list: vector<ID> = vector::empty<ID>();
    new_id_list.push_back(event_id);
    dfield::add<String, vector<ID>>(tag_handler_event.mut_event_tag_handler_uid(), tag, new_id_list);
}

fun get_mut_obj_list_event(tag_handler_event: &mut TagHandlerEvent, tag: String): &mut vector<ID> {
    dfield::borrow_mut<String, vector<ID>>(tag_handler_event.mut_event_tag_handler_uid(), tag)
}

public(package) fun get_obj_list_event(tag_handler_event: &TagHandlerEvent, tag: String): &vector<ID> {
    dfield::borrow<String, vector<ID>>(tag_handler_event.event_tag_handler_uid(), tag)
}

// --- Category Functions ---

public(package) fun add_to_category(category_object: &mut Category, category: String, event_id: ID) {
    if (dfield::exists_(category_object.category_uid(), category)) {
        let state_ids: &mut vector<ID> = get_mut_obj_list_category(category_object, category);
        state_ids.push_back(event_id);
        return
    };
    
    let mut new_id_list: vector<ID> = vector::empty<ID>();
    new_id_list.push_back(event_id);
    dfield::add<String, vector<ID>>(category_object.mut_category_uid(), category, new_id_list);
}

public(package) fun get_mut_obj_list_category(category_object: &mut Category, category: String): &mut vector<ID> {
    dfield::borrow_mut<String, vector<ID>>(category_object.mut_category_uid(), category)
}