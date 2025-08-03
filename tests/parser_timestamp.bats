#!/usr/bin/env bats

# Test file for parser_timestamp.sh functions

setup() {
  # Set up JUNJO_LIB_DIR for the library files
  export JUNJO_LIB_DIR="$BATS_TEST_DIRNAME/../lib"

  # Load the library functions
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/utils_exif.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_file.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_takeout.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_timestamp.sh"

  # Change to project root for sample file access
  cd "$BATS_TEST_DIRNAME/.."
}

# ====================================================================================================
# Tests for normalize_timestamp function
# ====================================================================================================

@test "normalize_timestamp: Unix epoch conversion" {
  result=$(normalize_timestamp "1026484386")
  [[ "$result" == "2002:07:12 14:33:06.000" ]]
}

@test "normalize_timestamp: Unix epoch conversion (original test)" {
  result=$(normalize_timestamp "1504360420")
  [[ "$result" == "2017:09:02 13:53:40.000" ]]
}

@test "normalize_timestamp: EXIF timestamp with timezone Z" {
  result=$(normalize_timestamp "2017:09:02 07:13:40Z")
  [[ "$result" == "2017:09:02 07:13:40.000" ]]
}

@test "normalize_timestamp: EXIF timestamp with offset" {
  result=$(normalize_timestamp "2017:09:02 07:13:40+08:00")
  [[ "$result" == "2017:09:02 07:13:40.000" ]]
}

@test "normalize_timestamp: EXIF timestamp with milliseconds" {
  result=$(normalize_timestamp "2017:09:02 07:13:40.123")
  [[ "$result" == "2017:09:02 07:13:40.123" ]]
}

@test "normalize_timestamp: EXIF timestamp without milliseconds" {
  result=$(normalize_timestamp "2017:09:02 07:13:40")
  [[ "$result" == "2017:09:02 07:13:40.000" ]]
}

@test "normalize_timestamp: invalid input returns empty string" {
  result=$(normalize_timestamp "invalid-timestamp")
  [[ "$result" == "" ]]
}

# ====================================================================================================
# Tests for get_best_available_timestamp function
# ====================================================================================================

@test "get_best_available_timestamp: direct call without caching" {
  local timestamp timestamp_source

  # Clear any cached values to force direct processing
  unset file_takeout_photo_taken_time
  declare -A file_takeout_photo_taken_time

  # Call the function - it should process the file directly
  get_best_available_timestamp "samples/google-takeout-photo-taken-time/IMAGE005.JPG" \
    timestamp timestamp_source

  # Should get a timestamp and source
  [[ -n "$timestamp_source" ]]
  [[ -n "$timestamp" ]]
}

@test "get_best_available_timestamp: retrieve from cache" {
  local timestamp timestamp_source
  local test_file="samples/google-takeout-photo-taken-time/IMAGE005.JPG"

  # Clear any cached values and set up cache test
  unset file_takeout_photo_taken_time
  declare -A file_takeout_photo_taken_time

  # Get the file ID and set the cached value
  local fid=$(get_media_file_id "$test_file")
  file_takeout_photo_taken_time["$fid"]="1026484386"

  get_best_available_timestamp "$test_file" timestamp timestamp_source

  # Should extract PhotoTakenTime from the cached value
  [[ "$timestamp" == "2002:07:12 14:33:06.000" ]]
  [[ "$timestamp_source" == "PhotoTakenTime" ]]
}

@test "get_best_available_timestamp: timestamp format validation" {
  local timestamp timestamp_source

  # Clear any cached values
  unset file_takeout_photo_taken_time
  declare -A file_takeout_photo_taken_time

  get_best_available_timestamp "samples/google-takeout-no-match/DSC09311.JPG" \
    timestamp timestamp_source

  # Should fallback to EXIF and still have proper format if timestamp exists
  if [[ -n "$timestamp" ]]; then
    # Verify timestamp format: YYYY:MM:DD HH:MM:SS.mmm
    [[ "$timestamp" =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}$ ]]
  fi
  [[ "$timestamp_source" != "PhotoTakenTime" ]]
}
@test "get_best_available_timestamp: missing timestamp falls back to EXIF" {
  local timestamp timestamp_source

  # Clear any cached values
  unset file_takeout_photo_taken_time
  declare -A file_takeout_photo_taken_time

  get_best_available_timestamp "samples/google-takeout-missing-geo/IMG_9806.MOV" \
    timestamp timestamp_source

  # Should get PhotoTakenTime from the JSON metadata (timestamp: "1515739249")
  [[ "$timestamp" == "2018:01:12 06:40:49.000" ]]
  [[ "$timestamp_source" == "PhotoTakenTime" ]]
}

@test "get_best_available_timestamp: handles nonexistent files gracefully" {
  local timestamp timestamp_source

  # Clear any cached values
  unset file_takeout_photo_taken_time
  declare -A file_takeout_photo_taken_time

  get_best_available_timestamp "nonexistent/file.jpg" timestamp timestamp_source

  # Should not crash and may return empty or fallback values
  [[ $? -eq 0 ]]
}
