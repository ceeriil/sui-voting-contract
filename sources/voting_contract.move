/*
/// Module: voting_contract
module voting_contract::voting_contract;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions



/// Module: voting
module voting::voting {
  use std::string;
  use sui::table;
  use sui::vec_map;
  use sui::url;
  use sui::zklogin_verified_issuer::check_zklogin_issuer;

  const EInvalidProof: u64 = 1;
  const EUserAlreadyVoted: u64 = 2;
  const ETooManyVotes: u64 = 3;
  const EInvalidProjectId: u64 = 4;
  const EVotingInactive: u64 = 5;

  public struct Votes has key {
    id: UID, 
    total_votes: u64, 
    candidates_list: vector<Candidate>,
    votes: table::Table<address, vector<u64>>,
    voting_active: bool
  }

public struct Candidate has store {
    id: u64,
    name: string::String, 
    genre: string::String, // Music genre (e.g., Pop, Rock, Jazz)
    profile_url: url::Url, // Link to musician's profile or portfolio
    votes: u64
}
  public struct AdminCap has key, store {
    id: UID
  }

  fun init(ctx: &mut TxContext) {
    let votes = Votes {
      id: object::new(ctx),
      total_votes: 0, 
      candidates_list: vector[
       Candidate {
        id: 0, 
        name: b"Drake".to_string(),
        genre: b"Hip-Hop".to_string(),
        profile_url: url::new_unsafe_from_bytes(b"https://www.drakeofficial.com/"),
        votes: 0
    },
    Candidate {
        id: 1, 
        name: b"Beyoncé".to_string(),
        genre: b"R&B".to_string(),
        profile_url: url::new_unsafe_from_bytes(b"https://www.beyonce.com/"),
        votes: 0
    },
    Candidate {
        id: 2, 
        name: b"Bad Bunny".to_string(),
        genre: b"Reggaeton".to_string(),
        profile_url: url::new_unsafe_from_bytes(b"https://www.badbunny.com/"),
        votes: 0
    },
    Candidate {
        id: 3, 
        name: b"Taylor Swift".to_string(),
        genre: b"Pop".to_string(),
        profile_url: url::new_unsafe_from_bytes(b"https://www.taylorswift.com/"),
        votes: 0
    },
    Candidate {
        id: 4, 
        name: b"The Weeknd".to_string(),
        genre: b"R&B".to_string(),
        profile_url: url::new_unsafe_from_bytes(b"https://www.theweeknd.com/"),
        votes: 0
    }
        
      ],
      votes: table::new(ctx),
      voting_active: false
    };
    transfer::share_object(votes);

    transfer::transfer(
      AdminCap {
        id: object::new(ctx)
      }, 
      ctx.sender()
    );
  }

 public fun vote(candidate_ids: vector<u64>, votes: &mut Votes, address_seed: u256, ctx: &TxContext) {

    let voter = ctx.sender();

    assert_user_has_not_voted(voter, votes);
    assert_sender_zklogin(address_seed, ctx);
    assert_valid_project_ids(candidate_ids, votes);
    assert_voting_is_active(votes);

    // Update candidate's vote
    let mut curr_index = 0;
    while (curr_index < candidate_ids.length()) {
      let candidate = &mut votes.candidates_list[candidate_ids[curr_index]];
      candidate.votes = candidate.votes + 1;

      // Increment total votes
      votes.total_votes = votes.total_votes + 1;

      curr_index = curr_index + 1;
    };

    // Record user's vote
    table::add(
      &mut votes.votes, 
      voter, 
      candidate_ids
    );
  }

 
 
}