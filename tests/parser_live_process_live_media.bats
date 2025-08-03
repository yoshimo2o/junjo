#!/usr/bin/env bats

# Test file for process_live_media function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"
  
  # Initialize global arrays for testing
  declare -gA live_photo_files
  declare -gA live_video_files
  declare -gA file_src
  declare -gA file_cid
  declare -gA live_photo_by_cid
  declare -gA live_video_by_cid
  declare -gA live_photo_duplicates
  declare -gA live_video_duplicates
  declare -gA file_has_duplicates
  declare -gA file_is_preferred_duplicate
  declare -gA live_photo_missing_video
  declare -gA live_video_missing_photo
  declare -gA file_duplicate_score
  declare -gA file_takeout_meta_file
  declare -gA file_src_root_stem
  declare -gA file_dest_dupe_marker
}

teardown() {
  # Clean up global arrays
  unset live_photo_files
  unset live_video_files
  unset file_src
  unset file_cid
  unset live_photo_by_cid
  unset live_video_by_cid
  unset live_photo_duplicates
  unset live_video_duplicates
  unset file_has_duplicates
  unset file_is_preferred_duplicate
  unset live_photo_missing_video
  unset live_video_missing_photo
  unset file_duplicate_score
  unset file_takeout_meta_file
  unset file_src_root_stem
  unset file_dest_dupe_marker
}

# ====================================================================================================
# Tests for process_live_media orchestration function
# ====================================================================================================

@test "process_live_media: processes complete live photo pair" {
  # Setup test data - matching live photo and video with same CID
  live_photo_files["fid1"]=1
  live_video_files["fid2"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_src["fid2"]="/path/IMG_0001.MOV"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid123"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=0

  # Run the main function
  process_live_media

  # Verify live photo and video are properly mapped
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  [ "${live_video_by_cid[cid123]}" = "fid2" ]
  
  # Verify no missing components
  [[ ! -v live_photo_missing_video[cid123] ]]
  [[ ! -v live_video_missing_photo[cid123] ]]
  
  # Verify no duplicates detected
  [[ ! -v live_photo_duplicates[cid123] ]]
  [[ ! -v live_video_duplicates[cid123] ]]
}

@test "process_live_media: processes live photo with missing video" {
  # Setup test data - live photo without corresponding video
  live_photo_files["fid1"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_cid["fid1"]="cid123"
  file_src_root_stem["fid1"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0

  # Run the main function
  process_live_media

  # Verify live photo is mapped
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  
  # Verify missing video is detected
  [ "${live_photo_missing_video[cid123]}" = "1" ]
  
  # Verify no video mapping exists
  [[ ! -v live_video_by_cid[cid123] ]]
}

@test "process_live_media: processes live video with missing photo" {
  # Setup test data - live video without corresponding photo
  live_video_files["fid2"]=1
  file_src["fid2"]="/path/IMG_0001.MOV"
  file_cid["fid2"]="cid123"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid2"]=0

  # Run the main function
  process_live_media

  # Verify live video is mapped
  [ "${live_video_by_cid[cid123]}" = "fid2" ]
  
  # Verify missing photo is detected
  [ "${live_video_missing_photo[cid123]}" = "1" ]
  
  # Verify no photo mapping exists
  [[ ! -v live_photo_by_cid[cid123] ]]
}

@test "process_live_media: processes duplicates and selects best candidate" {
  # Setup test data - multiple live photos with same CID
  live_photo_files["fid1"]=1
  live_photo_files["fid2"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_src["fid2"]="/path/IMG_0001(1).HEIC"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid123"
  file_src_root_stem["fid1"]="IMG_0001"
  file_src_root_stem["fid2"]="IMG_0001"
  file_dest_dupe_marker["fid1"]=0
  file_dest_dupe_marker["fid2"]=1
  file_takeout_meta_file["fid1"]="/path/IMG_0001.HEIC.json"

  # Run the main function
  process_live_media

  # Verify best candidate is selected as primary (fid1 has higher score)
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  
  # Verify duplicates are detected (order may vary based on processing)
  [[ "${live_photo_duplicates[cid123]}" == "fid1|fid2" || "${live_photo_duplicates[cid123]}" == "fid2|fid1" ]]
  
  # Verify both files are marked as having duplicates
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  
  # Verify best duplicate is selected (fid1 should win due to takeout metadata and be the primary)
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  [ "${file_is_preferred_duplicate[fid1]}" = "1" ]
}
