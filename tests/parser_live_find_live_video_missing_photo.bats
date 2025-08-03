#!/usr/bin/env bats

# Test file for find_live_video_missing_photo function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"

  # Initialize global arrays for testing
  declare -gA live_video_by_cid
  declare -gA live_photo_by_cid
  declare -gA live_video_missing_photo
}

teardown() {
  # Clean up global arrays
  unset live_video_by_cid
  unset live_photo_by_cid
  unset live_video_missing_photo
}

# ====================================================================================================
# Tests for find_live_video_missing_photo function
# ====================================================================================================

@test "find_live_video_missing_photo: detects video with missing photo" {
  # Setup test data - video without corresponding photo
  live_video_by_cid["cid123"]="fid2"
  # Intentionally not setting live_photo_by_cid["cid123"]

  # Run the function
  find_live_video_missing_photo

  # Verify missing photo is detected
  [ "${live_video_missing_photo[cid123]}" = "1" ]
}

@test "find_live_video_missing_photo: does not flag complete pairs" {
  # Setup test data - video with corresponding photo
  live_video_by_cid["cid123"]="fid2"
  live_photo_by_cid["cid123"]="fid1"

  # Run the function
  find_live_video_missing_photo

  # Verify no missing photo is detected
  [[ ! -v live_video_missing_photo[cid123] ]]
}

@test "find_live_video_missing_photo: handles multiple videos with mixed scenarios" {
  # Setup test data - multiple videos, some with photos, some without
  live_video_by_cid["cid123"]="fid2"  # Has photo
  live_video_by_cid["cid456"]="fid4"  # Missing photo
  live_video_by_cid["cid789"]="fid6"  # Missing photo
  live_photo_by_cid["cid123"]="fid1"  # Corresponding to cid123
  # cid456 and cid789 intentionally have no photos

  # Run the function
  find_live_video_missing_photo

  # Verify only missing photos are flagged
  [[ ! -v live_video_missing_photo[cid123] ]]  # Complete pair
  [ "${live_video_missing_photo[cid456]}" = "1" ]  # Missing photo
  [ "${live_video_missing_photo[cid789]}" = "1" ]  # Missing photo
}

@test "find_live_video_missing_photo: handles empty live_video_by_cid array" {
  # Setup test data - no videos
  # Arrays are empty by default

  # Run the function
  find_live_video_missing_photo

  # Verify no missing photos are detected
  [ "${#live_video_missing_photo[@]}" -eq 0 ]
}

@test "find_live_video_missing_photo: ignores orphaned photos" {
  # Setup test data - photo without corresponding video
  live_photo_by_cid["cid123"]="fid1"
  # Intentionally not setting live_video_by_cid["cid123"]

  # Run the function
  find_live_video_missing_photo

  # Verify no missing photos are detected (function only looks at videos)
  [ "${#live_video_missing_photo[@]}" -eq 0 ]
}

@test "find_live_video_missing_photo: handles all videos having photos" {
  # Setup test data - all videos have corresponding photos
  live_video_by_cid["cid123"]="fid2"
  live_video_by_cid["cid456"]="fid4"
  live_video_by_cid["cid789"]="fid6"
  live_photo_by_cid["cid123"]="fid1"
  live_photo_by_cid["cid456"]="fid3"
  live_photo_by_cid["cid789"]="fid5"

  # Run the function
  find_live_video_missing_photo

  # Verify no missing photos are detected
  [ "${#live_video_missing_photo[@]}" -eq 0 ]
}

@test "find_live_video_missing_photo: handles all videos missing photos" {
  # Setup test data - no photos exist
  live_video_by_cid["cid123"]="fid2"
  live_video_by_cid["cid456"]="fid4"
  live_video_by_cid["cid789"]="fid6"
  # Intentionally not setting any live_photo_by_cid entries

  # Run the function
  find_live_video_missing_photo

  # Verify all videos are flagged as missing photos
  [ "${live_video_missing_photo[cid123]}" = "1" ]
  [ "${live_video_missing_photo[cid456]}" = "1" ]
  [ "${live_video_missing_photo[cid789]}" = "1" ]
  [ "${#live_video_missing_photo[@]}" -eq 3 ]
}
