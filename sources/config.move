module memory::config;



// ======= OTHER CONSTANTS =======//
const ADMINADDRESS: address = @0xbffd2a1e8aae0e2bd8817e721bc3f4eb5128e54babfc441c9f5646736f4c6bbe;
const TagLength: u64 = 8;
const CommonFactor: u64 = 3;
const CriteriaVote: u64 = 3;
const CriteriaSubmit: u64 = 3;
const SUIEventCreationFee: u64 = 50000;


// ======= FUNCTIONS TO ACCESS CONSTANTS =======//

/// Returns the admin address
public fun get_admin_address(): address {ADMINADDRESS}

/// Returns the tag length
public fun get_tag_length(): u64 {TagLength}

/// Returns the common factor
public fun get_common_factor(): u64 {CommonFactor}

/// Returns the criteria vote count
public fun get_criteria_vote(): u64 {CriteriaVote}

/// Returns the criteria submission count
public fun get_criteria_submit(): u64 {CriteriaSubmit}

/// Returns the event creation fee
public fun get_event_creation_fee(): u64 {SUIEventCreationFee}

