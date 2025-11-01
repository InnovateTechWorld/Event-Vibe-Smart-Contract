module memory::types;
use std::string::String;


// --- Data Structs ---

public struct Location has store, copy, drop {
    long: u64,
    lat: u64,
}

public struct ImageMetaData has store, copy {
    event_profile: String,
    event_banner: String,
}



// =================== view
public fun long(l: &Location): u64{
    l.long
}

public fun lat(l: &Location): u64{
    l.lat
}

public fun event_profile(e: &ImageMetaData): String{
    e.event_profile
}

public fun event_banner(e: &ImageMetaData): String{
    e.event_banner
}


public(package) fun location(long: u64, lat: u64): Location{
    Location{
        long,
        lat
    }
}

public fun same_location(l1: &Location, l2: &Location): bool{
    (l1.long == l2.long) && (l1.lat == l2.lat)
}

public(package) fun image_meta_data(
    event_profile: String,
    event_banner: String,
    ): ImageMetaData{
    ImageMetaData{
        event_profile,
        event_banner,
    }
}


