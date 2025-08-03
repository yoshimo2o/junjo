#!/usr/bin/env bats

# Test file for analyze_media_file function
# Tests complete media file analysis with actual file from samples

# Set up required environment variables at the top level
export JUNJO_LIB_DIR="$BATS_TEST_DIRNAME/../lib"

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/functions.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_file.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_takeout.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_timestamp.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_exif.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_device.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_software.sh"
  source "$BATS_TEST_DIRNAME/../lib/media_scanner.sh"
}

# ====================================================================================================
# Test for analyze_media_file with actual media file
# ====================================================================================================

@test "analyze_media_file: analyzes IMG_3238(1).JPG and populates all global variables" {
  local test_file="$BATS_TEST_DIRNAME/../samples/google-takeout-duplication-match/IMG_3238(1).JPG"

  # Verify the test file exists
  [[ -f "$test_file" ]]

  # Call the function and capture the file ID
  # Note: We need to capture the output without using $() subshell
  # because subshells don't preserve global variable changes
  local temp_file=$(mktemp)
  analyze_media_file "$test_file" > "$temp_file"
  local fid=$(cat "$temp_file")
  rm "$temp_file"

  # Verify a file ID was returned
  [[ -n "$fid" ]]

  # Test file source properties
  [[ "${file_src[$fid]}" == "$test_file" ]]
  [[ -n "${file_src_dir[$fid]}" ]]
  [[ "${file_src_name[$fid]}" == "IMG_3238(1).JPG" ]]
  [[ "${file_src_stem[$fid]}" == "IMG_3238(1)" ]]
  [[ "${file_src_root_stem[$fid]}" == "IMG_3238" ]]
  [[ "${file_src_ext[$fid]}" == ".JPG" ]]
  [[ "${file_src_compound_ext[$fid]}" == ".JPG" ]]
  [[ "${file_src_dupe_marker[$fid]}" == "1" ]]

  # Test takeout metadata properties
  [[ "${file_takeout_meta_file[$fid]}" =~ IMG_3238\.JPG\.supplemental-metadata\(1\)\.json$ ]]
  [[ "${file_takeout_meta_file_name[$fid]}" == "IMG_3238.JPG.supplemental-metadata(1).json" ]]
  [[ "${file_takeout_meta_file_match_strategy[$fid]}" == "duplication" ]]
  [[ "${file_takeout_photo_taken_time[$fid]}" == "1487420483" ]]
  [[ "${file_takeout_geo_data[$fid]}" == *"52.4739389"* ]]
  [[ "${file_takeout_device_type[$fid]}" == "IOS_PHONE" ]]
  [[ "${file_takeout_device_folder[$fid]}" == "" ]]
  [[ "${file_takeout_upload_origin[$fid]}" == "mobile" ]]

  # Test EXIF metadata properties
  [[ "${file_exif_cid[$fid]}" == "" ]]
  [[ "${file_exif_make[$fid]}" == "" ]]
  [[ "${file_exif_model[$fid]}" == "" ]]
  [[ "${file_exif_lens_make[$fid]}" == "" ]]
  [[ "${file_exif_lens_model[$fid]}" == "" ]]
  [[ "${file_exif_image_width[$fid]}" == "" ]]
  [[ "${file_exif_image_height[$fid]}" == "" ]]
  [[ "${file_exif_image_size[$fid]}" == "" ]]
  [[ "${file_exif_date_time_original[$fid]}" == "" ]]
  [[ "${file_exif_create_date[$fid]}" == "" ]]
  [[ "${file_exif_track_create_date[$fid]}" == "" ]]
  [[ "${file_exif_media_create_date[$fid]}" == "" ]]
  [[ "${file_exif_user_comment[$fid]}" == "" ]]

  # File create/modify dates will vary depending on when the repo was cloned
  # They might be empty if ExifTool doesn't extract them
  [[ -v file_src_create_date[$fid] ]]
  [[ -v file_src_modify_date[$fid] ]]

  # Test Apple media detection
  [[ "${file_is_apple_media[$fid]}" == "0" ]]

  # Test timestamp properties
  [[ "${file_timestamp[$fid]}" == "2017:02:18 12:21:23.000" ]]
  [[ "${file_timestamp_source[$fid]}" == "PhotoTakenTime" ]]

  # Test device and software names
  [[ "${file_device_name[$fid]}" == "iPhone" ]]
  [[ "${file_software_name[$fid]}" == "" ]]

  # Test that the file was NOT added to apple_photo_files array
  # Since EXIF data is not being extracted, it's not detected as Apple media
  [[ "${apple_photo_files[$fid]}" == "" ]]

  # Print some debug information for manual verification
  echo "# File successfully analyzed!" >&3
  echo "# File ID: $fid" >&3
  echo "# File path: ${file_src[$fid]}" >&3
  echo "# Timestamp: ${file_timestamp[$fid]}" >&3
  echo "# Timestamp source: ${file_timestamp_source[$fid]}" >&3
  echo "# Device name: ${file_device_name[$fid]}" >&3
  echo "# Is Apple media: ${file_is_apple_media[$fid]}" >&3
}
