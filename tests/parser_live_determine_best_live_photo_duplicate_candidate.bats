#!/usr/bin/env bats

# Test file for determine_best_live_photo_duplicate_candidate function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"

  # Initialize global arrays for testing
  declare -gA live_photo_duplicates
  declare -gA file_duplicate_score
  declare -gA file_takeout_meta_file
  declare -gA file_src_root_stem
  declare -gA file_dest_dupe_marker
  declare -gA live_photo_by_cid
  declare -gA file_is_preferred_duplicate
}

teardown() {
  # Clean up global arrays
  unset live_photo_duplicates
  unset file_duplicate_score
  unset file_takeout_meta_file
  unset file_src_root_stem
  unset file_dest_dupe_marker
  unset live_photo_by_cid
  unset file_is_preferred_duplicate
}

# ====================================================================================================
# Tests for determine_best_live_photo_duplicate_candidate function
# ====================================================================================================

@test "determine_best_live_photo_duplicate_candidate: selects best candidate with takeout metadata" {
  # Setup test data - two duplicates, one with takeout metadata
  live_photo_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=1
  file_takeout_meta_file["fid2"]="/path/IMG_0001(1).HEIC.json"
  live_photo_by_cid["cid123"]="fid1"  # Initially set to first found

  # Run the function
  determine_best_live_photo_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "100" ]  # IMG prefix only
  [ "${file_duplicate_score[fid2]}" = "199" ]  # IMG prefix + takeout metadata - dupe marker

  # Verify fid2 is selected as preferred (higher score) and becomes the primary
  [ "${live_photo_by_cid[cid123]}" = "fid2" ]
  [ "${file_is_preferred_duplicate[fid2]}" = "1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "0" ]
}

@test "determine_best_live_photo_duplicate_candidate: selects candidate with IMG prefix" {
  # Setup test data - one with IMG prefix, one without
  live_photo_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="DCIM_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=0
  live_photo_by_cid["cid123"]="fid1"

  # Run the function
  determine_best_live_photo_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "0" ]    # No IMG prefix
  [ "${file_duplicate_score[fid2]}" = "100" ]  # IMG prefix

  # Verify fid2 is selected as preferred and becomes the primary
  [ "${live_photo_by_cid[cid123]}" = "fid2" ]
  [ "${file_is_preferred_duplicate[fid2]}" = "1" ]
}

@test "determine_best_live_photo_duplicate_candidate: penalizes duplicate markers" {
  # Setup test data - same conditions except duplicate markers
  live_photo_duplicates["cid123"]="fid1|fid2"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=5
  live_photo_by_cid["cid123"]="fid2"

  # Run the function
  determine_best_live_photo_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "100" ]  # IMG prefix
  [ "${file_duplicate_score[fid2]}" = "95" ]   # IMG prefix - 5 (dupe marker)

  # Verify fid1 is selected as preferred (no duplicate marker penalty) and becomes primary
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "determine_best_live_photo_duplicate_candidate: handles complex scoring scenario" {
  # Setup test data - three duplicates with different attributes
  live_photo_duplicates["cid123"]="fid1|fid2|fid3"
  file_src_root_stem["fid1"]="DCIM_0001"  # No IMG prefix
  file_src_root_stem["fid2"]="IMG_0001"   # IMG prefix
  file_src_root_stem["fid3"]="IMG_0001"   # IMG prefix
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=2
  file_dest_dupe_marker["fid3"]=0
  file_takeout_meta_file["fid1"]="/path/DCIM_0001.HEIC.json"  # Has takeout metadata
  live_photo_by_cid["cid123"]="fid1"

  # Run the function
  determine_best_live_photo_duplicate_candidate

  # Verify scores are calculated correctly
  [ "${file_duplicate_score[fid1]}" = "100" ]  # Takeout metadata only
  [ "${file_duplicate_score[fid2]}" = "98" ]   # IMG prefix - 2 (dupe marker)
  [ "${file_duplicate_score[fid3]}" = "100" ]  # IMG prefix only

  # Verify one of the 100-point files is selected (fid1 or fid3) since they tie
  # When scores are equal, the first processed wins
  primary_fid="${live_photo_by_cid[cid123]}"
  [[ "$primary_fid" == "fid1" || "$primary_fid" == "fid3" ]]
  [ "${file_duplicate_score[$primary_fid]}" = "100" ]
  [ "${file_is_preferred_duplicate[$primary_fid]}" = "1" ]
}

@test "determine_best_live_photo_duplicate_candidate: handles single duplicate" {
  # Setup test data - single duplicate
  live_photo_duplicates["cid123"]="fid1"
  file_src_root_stem["fid1"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  live_photo_by_cid["cid123"]="fid0"  # Different initial value

  # Run the function
  determine_best_live_photo_duplicate_candidate

  # Verify score is calculated
  [ "${file_duplicate_score[fid1]}" = "100" ]

  # Verify fid1 is selected as preferred and becomes primary
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "determine_best_live_photo_duplicate_candidate: handles multiple CIDs independently" {
  # Setup test data - two different CIDs with duplicates
  live_photo_duplicates["cid123"]="fid1|fid2"
  live_photo_duplicates["cid456"]="fid3|fid4"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="DCIM_0001"
  file_src_root_stem["fid3"]="DCIM_0002"
  file_src_root_stem["fid4"]="IMG_0002"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=0
  file_dest_dupe_marker["fid3"]=0
  file_dest_dupe_marker["fid4"]=0
  live_photo_by_cid["cid123"]="fid2"
  live_photo_by_cid["cid456"]="fid3"

  # Run the function
  determine_best_live_photo_duplicate_candidate

  # Verify both CIDs are processed independently and updated to best candidates
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]  # IMG prefix wins, becomes primary
  [ "${live_photo_by_cid[cid456]}" = "fid4" ]  # IMG prefix wins, becomes primary
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
  [ "${file_is_preferred_duplicate[fid4]}" = "1" ]
}

@test "determine_best_live_photo_duplicate_candidate: handles empty duplicates array" {
  # No setup needed - array is empty by default

  # Run the function (should not error)
  determine_best_live_photo_duplicate_candidate

  # Verify no processing occurs
  [ "${#file_duplicate_score[@]}" -eq 0 ]
  [ "${#live_photo_by_cid[@]}" -eq 0 ]
}
