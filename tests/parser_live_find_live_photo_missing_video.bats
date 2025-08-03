#!/usr/bin/env bats

# Test file for find_live_photo_missing_video function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"

  # Initialize global arrays for testing
  declare -gA live_photo_by_cid
  declare -gA live_video_by_cid
  declare -gA live_photo_missing_video
}

teardown() {
  # Clean up global arrays
  unset live_photo_by_cid
  unset live_video_by_cid
  unset live_photo_missing_video
}

# ====================================================================================================
# Tests for find_live_photo_missing_video function
# ====================================================================================================

@test "find_live_photo_missing_video: detects photo with missing video" {
  # Setup test data - photo without corresponding video
  live_photo_by_cid["cid123"]="fid1"
  # Intentionally not setting live_video_by_cid["cid123"]

  # Run the function
  find_live_photo_missing_video

  # Verify missing video is detected
  [ "${live_photo_missing_video[cid123]}" = "1" ]
}

@test "find_live_photo_missing_video: does not flag complete pairs" {
  # Setup test data - photo with corresponding video
  live_photo_by_cid["cid123"]="fid1"
  live_video_by_cid["cid123"]="fid2"

  # Run the function
  find_live_photo_missing_video

  # Verify no missing video is detected
  [[ ! -v live_photo_missing_video[cid123] ]]
}

@test "find_live_photo_missing_video: handles multiple photos with mixed scenarios" {
  # Setup test data - multiple photos, some with videos, some without
  live_photo_by_cid["cid123"]="fid1"  # Has video
  live_photo_by_cid["cid456"]="fid3"  # Missing video
  live_photo_by_cid["cid789"]="fid5"  # Missing video
  live_video_by_cid["cid123"]="fid2"  # Corresponding to cid123
  # cid456 and cid789 intentionally have no videos

  # Run the function
  find_live_photo_missing_video

  # Verify only missing videos are flagged
  [[ ! -v live_photo_missing_video[cid123] ]]  # Complete pair
  [ "${live_photo_missing_video[cid456]}" = "1" ]  # Missing video
  [ "${live_photo_missing_video[cid789]}" = "1" ]  # Missing video
}

@test "find_live_photo_missing_video: handles empty live_photo_by_cid array" {
  # Setup test data - no photos
  # Arrays are empty by default

  # Run the function
  find_live_photo_missing_video

  # Verify no missing videos are detected
  [ "${#live_photo_missing_video[@]}" -eq 0 ]
}

@test "find_live_photo_missing_video: ignores orphaned videos" {
  # Setup test data - video without corresponding photo
  live_video_by_cid["cid123"]="fid2"
  # Intentionally not setting live_photo_by_cid["cid123"]

  # Run the function
  find_live_photo_missing_video

  # Verify no missing videos are detected (function only looks at photos)
  [ "${#live_photo_missing_video[@]}" -eq 0 ]
}

@test "find_live_photo_missing_video: handles all photos having videos" {
  # Setup test data - all photos have corresponding videos
  live_photo_by_cid["cid123"]="fid1"
  live_photo_by_cid["cid456"]="fid3"
  live_photo_by_cid["cid789"]="fid5"
  live_video_by_cid["cid123"]="fid2"
  live_video_by_cid["cid456"]="fid4"
  live_video_by_cid["cid789"]="fid6"

  # Run the function
  find_live_photo_missing_video

  # Verify no missing videos are detected
  [ "${#live_photo_missing_video[@]}" -eq 0 ]
}

@test "find_live_photo_missing_video: handles all photos missing videos" {
  # Setup test data - no videos exist
  live_photo_by_cid["cid123"]="fid1"
  live_photo_by_cid["cid456"]="fid3"
  live_photo_by_cid["cid789"]="fid5"
  # Intentionally not setting any live_video_by_cid entries

  # Run the function
  find_live_photo_missing_video

  # Verify all photos are flagged as missing videos
  [ "${live_photo_missing_video[cid123]}" = "1" ]
  [ "${live_photo_missing_video[cid456]}" = "1" ]
  [ "${live_photo_missing_video[cid789]}" = "1" ]
  [ "${#live_photo_missing_video[@]}" -eq 3 ]
}
