module memory::emit_event;
use sui::event::Self;


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


// ========= emiters ==============================
public(package) fun new_event(event_id: ID, creator: address){
        event::emit(
            NewEvent {
        event_id,
        creator,
    });
}

public(package) fun new_image(event_id: ID, image_id: ID, creator: address){
    event::emit(
        NewImage{
            event_id,
            image_id, 
            creator,
        }
    )
}

public(package) fun new_like(
    event_id: ID,
    image_id: ID,
    like_count: u256,
){
    event::emit(
        NewLike{
            event_id,
            image_id,
            like_count,
        }
    )
}

public(package) fun claimed_nft(
    event_id: ID,
    nft_id: ID,
    claimer: address,
){
    event::emit(
        ClaimedNft{
            event_id,
            nft_id,
            claimer
        }
    )

}