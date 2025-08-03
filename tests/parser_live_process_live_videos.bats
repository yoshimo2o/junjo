#!/usr/bin/env bats

# Test file for process_live_videos function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"

  # Initialize global arrays for testing
  declare -gA live_video_files
  declare -gA file_src
  declare -gA file_cid
  declare -gA live_video_by_cid
  declare -gA live_video_duplicates
  declare -gA file_has_duplicates
  declare -gA file_is_preferred_duplicate
}

teardown() {
  # Clean up global arrays
  unset live_video_files
  unset file_src
  unset file_cid
  unset live_video_by_cid
  unset live_video_duplicates
  unset file_has_duplicates
  unset file_is_preferred_duplicate
}

# ====================================================================================================
# Tests for process_live_videos function
# ====================================================================================================

@test "process_live_videos: processes single live video" {
  # Setup test data
  live_video_files["fid1"]=1
  file_src["fid1"]="/path/IMG_0001.MOV"
  file_cid["fid1"]="cid123"

  # Run the function
  process_live_videos

  # Verify the video is mapped to its CID
  [ "${live_video_by_cid[cid123]}" = "fid1" ]

  # Verify no duplicates are created
  [[ ! -v live_video_duplicates[cid123] ]]
  [[ ! -v file_has_duplicates[fid1] ]]
}

@test "process_live_videos: processes multiple videos with different CIDs" {
  # Setup test data - different CIDs
  live_video_files["fid1"]=1
  live_video_files["fid2"]=1
  file_src["fid1"]="/path/IMG_0001.MOV"
  file_src["fid2"]="/path/IMG_0002.MOV"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid456"

  # Run the function
  process_live_videos

  # Verify both videos are mapped to their respective CIDs
  [ "${live_video_by_cid[cid123]}" = "fid1" ]
  [ "${live_video_by_cid[cid456]}" = "fid2" ]

  # Verify no duplicates are created
  [[ ! -v live_video_duplicates[cid123] ]]
  [[ ! -v live_video_duplicates[cid456] ]]
}

@test "process_live_videos: processes duplicate videos with same CID" {
  # Setup test data - same CID
  live_video_files["fid1"]=1
  live_video_files["fid2"]=1
  file_src["fid1"]="/path/IMG_0001.MOV"
  file_src["fid2"]="/path/IMG_0001(1).MOV"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid123"

  # Run the function
  process_live_videos

  # Verify one of the videos is mapped as primary (order not guaranteed with associative arrays)
  [[ "${live_video_by_cid[cid123]}" == "fid1" || "${live_video_by_cid[cid123]}" == "fid2" ]]

  # Verify duplicates array contains both files (order may vary)
  [[ "${live_video_duplicates[cid123]}" == "fid1|fid2" || "${live_video_duplicates[cid123]}" == "fid2|fid1" ]]

  # Verify duplicate markers are set
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]

  # Verify the primary video is marked as preferred duplicate (initially)
  primary_fid="${live_video_by_cid[cid123]}"
  [ "${file_is_preferred_duplicate[$primary_fid]}" = "1" ]
}

@test "process_live_videos: processes multiple duplicates with same CID" {
  # Setup test data - three videos with same CID
  live_video_files["fid1"]=1
  live_video_files["fid2"]=1
  live_video_files["fid3"]=1
  file_src["fid1"]="/path/IMG_0001.MOV"
  file_src["fid2"]="/path/IMG_0001(1).MOV"
  file_src["fid3"]="/path/IMG_0001(2).MOV"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid123"
  file_cid["fid3"]="cid123"

  # Run the function
  process_live_videos

  # Verify one of the videos is mapped as primary (order not guaranteed with associative arrays)
  [[ "${live_video_by_cid[cid123]}" =~ ^(fid1|fid2|fid3)$ ]]

  # Verify duplicates array contains all three files (order may vary)
  duplicates="${live_video_duplicates[cid123]}"
  [[ "$duplicates" =~ fid1 && "$duplicates" =~ fid2 && "$duplicates" =~ fid3 ]]
  [[ $(echo "$duplicates" | tr '|' '\n' | wc -l) -eq 3 ]]

  # Verify all files are marked as having duplicates
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  [ "${file_has_duplicates[fid3]}" = "1" ]
}

@test "process_live_videos: handles empty live_video_files array" {
  # No setup needed - arrays are empty by default

  # Run the function (should not error)
  process_live_videos

  # Verify no mappings are created
  [ "${#live_video_by_cid[@]}" -eq 0 ]
  [ "${#live_video_duplicates[@]}" -eq 0 ]
}
