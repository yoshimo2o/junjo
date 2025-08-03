#!/usr/bin/env bats

# Test file for add_to_live_video_duplicates function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"
  
  # Initialize global arrays for testing
  declare -gA live_video_by_cid
  declare -gA live_video_duplicates
  declare -gA file_has_duplicates
  declare -gA file_is_preferred_duplicate
}

teardown() {
  # Clean up global arrays
  unset live_video_by_cid
  unset live_video_duplicates
  unset file_has_duplicates
  unset file_is_preferred_duplicate
}

# ====================================================================================================
# Tests for add_to_live_video_duplicates function
# ====================================================================================================

@test "add_to_live_video_duplicates: adds first duplicate for CID" {
  # Setup - simulate first video already found
  live_video_by_cid["cid123"]="fid1"

  # Run the function - add first duplicate
  add_to_live_video_duplicates "cid123" "fid2"

  # Verify duplicate is tracked (includes both original and duplicate)
  [ "${live_video_duplicates[cid123]}" = "fid1|fid2" ]
  
  # Verify both files are marked as having duplicates
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  
  # Verify first found file is marked as preferred duplicate (initially)
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "add_to_live_video_duplicates: adds second duplicate for CID" {
  # Setup - simulate first video and one duplicate already found
  live_video_by_cid["cid123"]="fid1"
  live_video_duplicates["cid123"]="fid2"
  file_has_duplicates["fid1"]=1
  file_has_duplicates["fid2"]=1
  file_is_preferred_duplicate["fid1"]=1

  # Run the function - add second duplicate
  add_to_live_video_duplicates "cid123" "fid3"

  # Verify duplicate is appended with pipe separator
  [ "${live_video_duplicates[cid123]}" = "fid2|fid3" ]
  
  # Verify new file is marked as having duplicates
  [ "${file_has_duplicates[fid3]}" = "1" ]
  
  # Verify original preferred duplicate remains unchanged
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "add_to_live_video_duplicates: adds multiple duplicates sequentially" {
  # Setup - simulate first video already found
  live_video_by_cid["cid123"]="fid1"

  # Add first duplicate
  add_to_live_video_duplicates "cid123" "fid2"
  
  # Add second duplicate
  add_to_live_video_duplicates "cid123" "fid3"
  
  # Add third duplicate
  add_to_live_video_duplicates "cid123" "fid4"

  # Verify all duplicates are tracked (includes original + all duplicates)
  [ "${live_video_duplicates[cid123]}" = "fid1|fid2|fid3|fid4" ]
  
  # Verify all files are marked as having duplicates
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  [ "${file_has_duplicates[fid3]}" = "1" ]
  [ "${file_has_duplicates[fid4]}" = "1" ]
  
  # Verify preferred duplicate remains the first found
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}

@test "add_to_live_video_duplicates: handles different CIDs independently" {
  # Setup - simulate videos for different CIDs
  live_video_by_cid["cid123"]="fid1"
  live_video_by_cid["cid456"]="fid3"

  # Add duplicates for different CIDs
  add_to_live_video_duplicates "cid123" "fid2"
  add_to_live_video_duplicates "cid456" "fid4"

  # Verify duplicates are tracked separately (includes original + duplicate)
  [ "${live_video_duplicates[cid123]}" = "fid1|fid2" ]
  [ "${live_video_duplicates[cid456]}" = "fid3|fid4" ]
  
  # Verify preferred duplicates are set correctly for each CID
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
  [ "${file_is_preferred_duplicate[fid3]}" = "1" ]
}

@test "add_to_live_video_duplicates: requires existing primary video" {
  # This test verifies the function works correctly when primary video exists
  # Setup - simulate first video already found
  live_video_by_cid["cid123"]="fid1"
  
  # Run the function - should succeed
  add_to_live_video_duplicates "cid123" "fid2"
  
  # Verify duplicate tracking occurs correctly
  [ "${live_video_duplicates[cid123]}" = "fid1|fid2" ]
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}
