#!/usr/bin/env bats

# Test file for process_live_photos function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_live.sh"
  
  # Initialize global arrays for testing
  declare -gA live_photo_files
  declare -gA file_src
  declare -gA file_cid
  declare -gA live_photo_by_cid
  declare -gA live_photo_duplicates
  declare -gA file_has_duplicates
  declare -gA file_is_preferred_duplicate
}

teardown() {
  # Clean up global arrays
  unset live_photo_files
  unset file_src
  unset file_cid
  unset live_photo_by_cid
  unset live_photo_duplicates
  unset file_has_duplicates
  unset file_is_preferred_duplicate
}

# ====================================================================================================
# Tests for process_live_photos function
# ====================================================================================================

@test "process_live_photos: processes single live photo" {
  # Setup test data
  live_photo_files["fid1"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_cid["fid1"]="cid123"

  # Run the function
  process_live_photos

  # Verify the photo is mapped to its CID
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  
  # Verify no duplicates are created
  [[ ! -v live_photo_duplicates[cid123] ]]
  [[ ! -v file_has_duplicates[fid1] ]]
}

@test "process_live_photos: processes multiple photos with different CIDs" {
  # Setup test data - different CIDs
  live_photo_files["fid1"]=1
  live_photo_files["fid2"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_src["fid2"]="/path/IMG_0002.HEIC"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid456"

  # Run the function
  process_live_photos

  # Verify both photos are mapped to their respective CIDs
  [ "${live_photo_by_cid[cid123]}" = "fid1" ]
  [ "${live_photo_by_cid[cid456]}" = "fid2" ]
  
  # Verify no duplicates are created
  [[ ! -v live_photo_duplicates[cid123] ]]
  [[ ! -v live_photo_duplicates[cid456] ]]
}

@test "process_live_photos: processes duplicate photos with same CID" {
  # Setup test data - same CID
  live_photo_files["fid1"]=1
  live_photo_files["fid2"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_src["fid2"]="/path/IMG_0001(1).HEIC"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid123"

  # Run the function
  process_live_photos

  # Verify one of the photos is mapped as primary (order not guaranteed with associative arrays)
  [[ "${live_photo_by_cid[cid123]}" == "fid1" || "${live_photo_by_cid[cid123]}" == "fid2" ]]
  
  # Verify duplicates array contains both files (order may vary)
  [[ "${live_photo_duplicates[cid123]}" == "fid1|fid2" || "${live_photo_duplicates[cid123]}" == "fid2|fid1" ]]
  
  # Verify duplicate markers are set
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  
  # Verify the primary photo is marked as preferred duplicate (initially)
  primary_fid="${live_photo_by_cid[cid123]}"
  [ "${file_is_preferred_duplicate[$primary_fid]}" = "1" ]
}

@test "process_live_photos: processes multiple duplicates with same CID" {
  # Setup test data - three photos with same CID
  live_photo_files["fid1"]=1
  live_photo_files["fid2"]=1
  live_photo_files["fid3"]=1
  file_src["fid1"]="/path/IMG_0001.HEIC"
  file_src["fid2"]="/path/IMG_0001(1).HEIC"
  file_src["fid3"]="/path/IMG_0001(2).HEIC"
  file_cid["fid1"]="cid123"
  file_cid["fid2"]="cid123"
  file_cid["fid3"]="cid123"

  # Run the function
  process_live_photos

  # Verify one of the photos is mapped as primary (order not guaranteed with associative arrays)
  [[ "${live_photo_by_cid[cid123]}" =~ ^(fid1|fid2|fid3)$ ]]
  
  # Verify duplicates array contains all three files (order may vary)
  duplicates="${live_photo_duplicates[cid123]}"
  [[ "$duplicates" =~ fid1 && "$duplicates" =~ fid2 && "$duplicates" =~ fid3 ]]
  [[ $(echo "$duplicates" | tr '|' '\n' | wc -l) -eq 3 ]]
  
  # Verify all files are marked as having duplicates
  [ "${file_has_duplicates[fid1]}" = "1" ]
  [ "${file_has_duplicates[fid2]}" = "1" ]
  [ "${file_has_duplicates[fid3]}" = "1" ]
}

@test "process_live_photos: handles empty live_photo_files array" {
  # No setup needed - arrays are empty by default
  
  # Run the function (should not error)
  process_live_photos

  # Verify no mappings are created
  [ "${#live_photo_by_cid[@]}" -eq 0 ]
  [ "${#live_photo_duplicates[@]}" -eq 0 ]
}
