#!/usr/bin/env bats

# Test file for determine_best_live_video_duplicate_candidate function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"
  
  # Initialize global arrays for testing
  declare -gA live_video_duplicates
  declare -gA file_duplicate_score
  declare -gA file_src_root_stem
  declare -gA file_dest_dupe_marker
  declare -gA live_video_by_cid
  declare -gA file_is_preferred_duplicate
}

teardown() {
  # Clean up global arrays
  unset live_video_duplicates
  unset file_duplicate_score
  unset file_src_root_stem
  unset file_dest_dupe_marker
  unset live_video_by_cid
  unset file_is_preferred_duplicate
}

# ====================================================================================================
# Tests for determine_best_live_video_duplicate_candidate function
# ====================================================================================================

@test "determine_best_live_video_duplicate_candidate: selects candidate with IMG prefix" {
  # Setup test data - one with IMG prefix, one without
  live_video_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="DCIM_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=0
  live_video_by_cid["cid123"]="fid1"

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "0" ]    # No IMG prefix
  [ "${file_duplicate_score[fid2]}" = "100" ]  # IMG prefix

  # Verify fid2 is selected as preferred and becomes the primary
  [ "${live_video_by_cid[cid123]}" = "fid2" ]
  [ "${file_is_preferred_duplicate[fid2]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: penalizes duplicate markers" {
  # Setup test data - same conditions except duplicate markers
  live_video_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=3
  live_video_by_cid["cid123"]="fid2"

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "100" ]  # IMG prefix
  [ "${file_duplicate_score[fid2]}" = "97" ]   # IMG prefix - 3 (dupe marker)

  # Verify fid1 is selected as preferred (no duplicate marker penalty) and becomes primary
  [ "${live_video_by_cid[cid123]}" = "fid1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: handles complex scoring scenario" {
  # Setup test data - three duplicates with different attributes
  live_video_duplicates["cid123"]="fid1|fid2|fid3"
  file_src_root_stem["fid1"]="DCIM_0001"  # No IMG prefix
  file_src_root_stem["fid2"]="IMG_0001"   # IMG prefix with dupe marker
  file_src_root_stem["fid3"]="IMG_0001"   # IMG prefix, no dupe marker
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=2
  file_dest_dupe_marker["fid3"]=0
  live_video_by_cid["cid123"]="fid1"

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "0" ]    # No IMG prefix
  [ "${file_duplicate_score[fid2]}" = "98" ]   # IMG prefix - 2 (dupe marker)
  [ "${file_duplicate_score[fid3]}" = "100" ]  # IMG prefix only

  # Verify fid3 is selected as preferred (highest score) and becomes primary
  [ "${live_video_by_cid[cid123]}" = "fid3" ]
  [ "${file_is_preferred_duplicate[fid3]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: handles equal scores" {
  # Setup test data - two duplicates with identical scoring
  live_video_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=0
  live_video_by_cid["cid123"]="fid1"

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify scores are identical
  [ "${file_duplicate_score[fid1]}" = "100" ]
  [ "${file_duplicate_score[fid2]}" = "100" ]

  # Verify one of the files with equal scores is selected as primary
  # When scores are equal, the first processed wins
  primary_fid="${live_video_by_cid[cid123]}"
  [[ "$primary_fid" == "fid1" || "$primary_fid" == "fid2" ]]
  [ "${file_duplicate_score[$primary_fid]}" = "100" ]
  [ "${file_is_preferred_duplicate[$primary_fid]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: handles single duplicate" {
  # Setup test data - single duplicate
  live_video_duplicates["cid123"]="fid1"
  file_src_root_stem["fid1"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=1
  live_video_by_cid["cid123"]="fid0"  # Different initial value

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify score is calculated
  [ "${file_duplicate_score[fid1]}" = "99" ]  # IMG prefix - 1 (dupe marker)

  # Verify fid1 is selected as preferred and becomes primary
  [ "${live_video_by_cid[cid123]}" = "fid1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: handles multiple CIDs independently" {
  # Setup test data - two different CIDs with duplicates
  live_video_duplicates["cid123"]="fid1|fid2"
  live_video_duplicates["cid456"]="fid3|fid4"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="DCIM_0001"
  file_src_root_stem["fid3"]="DCIM_0002"
  file_src_root_stem["fid4"]="IMG_0002"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=0
  file_dest_dupe_marker["fid3"]=0
  file_dest_dupe_marker["fid4"]=0
  live_video_by_cid["cid123"]="fid2"
  live_video_by_cid["cid456"]="fid3"

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify both CIDs are processed independently and updated to best candidates
  [ "${live_video_by_cid[cid123]}" = "fid1" ]  # IMG prefix wins, becomes primary
  [ "${live_video_by_cid[cid456]}" = "fid4" ]  # IMG prefix wins, becomes primary
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
  [ "${file_is_preferred_duplicate[fid4]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: no takeout metadata scoring" {
  # Setup test data - verify takeout metadata is not considered for videos
  live_video_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=1
  # Note: We don't set file_takeout_meta_file for videos as they don't have it
  live_video_by_cid["cid123"]="fid2"

  # Run the function
  determine_best_live_video_duplicate_candidate

  # Verify scores don't include takeout metadata bonus
  [ "${file_duplicate_score[fid1]}" = "100" ]  # IMG prefix only
  [ "${file_duplicate_score[fid2]}" = "99" ]   # IMG prefix - 1 (dupe marker)

  # Verify fid1 wins (no duplicate marker penalty) and becomes primary
  [ "${live_video_by_cid[cid123]}" = "fid1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "determine_best_live_video_duplicate_candidate: handles empty duplicates array" {
  # No setup needed - array is empty by default
  
  # Run the function (should not error)
  determine_best_live_video_duplicate_candidate

  # Verify no processing occurs
  [ "${#file_duplicate_score[@]}" -eq 0 ]
  [ "${#live_video_by_cid[@]}" -eq 0 ]
}
