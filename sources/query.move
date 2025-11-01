module memory::query;
use std::string::String;



use memory::{
    app::{Application, TagHandlerPhoto, TagHandlerEvent, Self},
    event::{Event},
    tag_service,
    config
    };

// --- Errors ---
#[error]
const EInvalidRange: vector<u8> = b"enter valid range";

// --- View Structs ---


public struct SearchResult has copy, store, drop {
    ids: vector<ID>,
    values: vector<u64>,
}




// --- View Functions ---

public fun viewEvent(application: &Application, start_index: u256, end_index: u256): vector<ID> {
    assert!(start_index < end_index && application.event_counts() >= end_index, EInvalidRange);
    let mut result: vector<ID> = vector::empty<ID>();
    let mut b = start_index;
    while (b <= end_index) {
        let event_id = app::get_event_id(application, b);
        result.push_back(event_id);
        b = b + 1;
    };
    result
}

public fun viewPhotos(event: &Event, start_index: u256, end_index: u256): vector<ID> {
    assert!(start_index < end_index && event.total_images() >= end_index, EInvalidRange);
    let mut result: vector<ID> = vector::empty<ID>();
    let mut b = start_index;
    while (b <= end_index) {
        let photo_id = event.get_photo_id(b);
        result.push_back(photo_id);
        b = b + 1;
    };
    result
}




// --- Search Functions ---

public fun search(
    event: &Event,
    tag_handler_photo: &TagHandlerPhoto,
    tags: vector<String>,
): SearchResult {
    assert!(config::get_tag_length() == tags.length(), 1);
    let mut results_id: vector<ID> = vector::empty<ID>();
    let mut results_value: vector<u64> = vector::empty<u64>();
    let mut i = 0;

    while (i < tags.length()) {
        let state_id_list = tag_service::get_obj_list_photo(tag_handler_photo, tags[i]);
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
    while (p < results_value.length()){
        if(results_value[p]< config::get_common_factor() || !event.check_if_in_event(results_id[p])){
            results_value.swap_remove(p);
            results_id.swap_remove(p);
        }else{
            p = p + 1;
        };
    };

  assert!(results_id.length() == results_value.length(), 1);

    let mut m = 0;
    while (m < results_id.length()){
        let mut p = 1 + m;
        while (p < results_id.length()){
            let m_position_value = results_value[m];
            let p_position_value = results_value[p];

            if (p_position_value > m_position_value){
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
    
    SearchResult {
        ids: results_id,
        values: results_value,
    }
}






public fun search_event(
    tag_handler_event: &TagHandlerEvent,
    tags: vector<String>,
): SearchResult {
     let mut results_id: vector<ID> = vector::empty<ID>();
    let mut results_value: vector<u64> = vector::empty<u64>();

    let mut i = 0;

    while (i < tags.length() ){
        let state_id_list = tag_service::get_obj_list_event(tag_handler_event, tags[i]);
        let mut j = 0;
        while (j < state_id_list.length()){
            let (st, index) = results_id.index_of(&state_id_list[j]);
            if (st){
                let inner_count = results_value.borrow_mut(index);
                *inner_count = *inner_count + 1;
            }else {
                results_id.push_back(state_id_list[j]);
                results_value.push_back(1);
            };

            j = 1 + j;
        };

        i = 1 + i;
    };


    assert!(results_id.length() == results_value.length(), 1);

    let mut p = 0;
    while (p < results_value.length()){
        if(results_value[p]< tags.length()){
            results_value.swap_remove(p);
            results_id.swap_remove(p);
        }else{
            p = p + 1;
        };
    };

  assert!(results_id.length() == results_value.length(), 1);

    let mut m = 0;
    while (m < results_id.length()){
        let mut p = 1 + m;
        while (p < results_id.length()){
            let m_position_value = results_value[m];
            let p_position_value = results_value[p];

            if (p_position_value > m_position_value){
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

    SearchResult{
        ids: results_id,
        values: results_value,
    }
}
