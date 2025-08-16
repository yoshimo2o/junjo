#!/usr/bin/env bats

# Test file for parser_timestamp.sh functions

setup() {
  source "$BATS_TEST_DIRNAME/init.sh"

  # Change to project root for sample file access
  cd "$BATS_TEST_DIRNAME/.."
}

# ====================================================================================================
# Tests for to_exif_ts function
# ====================================================================================================

@test "to_exif_ts: Epoch timestamp conversion" {
  result=$(to_exif_ts "1026484386")
  [[ "$result" == "2002:07:12 14:33:06.000" ]]
}

@test "to_exif_ts: EXIF timestamp with timezone Z" {
  result=$(to_exif_ts "2017:09:02 07:13:40Z")
  [[ "$result" == "2017:09:02 07:13:40.000" ]]
}

@test "to_exif_ts: EXIF timestamp with positive offset" {
  result=$(to_exif_ts "2017:09:02 07:13:40+08:00")
  [[ "$result" == "2017:09:01 23:13:40.000" ]]
}

@test "to_exif_ts: EXIF timestamp with negative offset" {
  result=$(to_exif_ts "2017:09:02 07:13:40-05:00")
  [[ "$result" == "2017:09:02 12:13:40.000" ]]
}

@test "to_exif_ts: EXIF timestamp with milliseconds" {
  result=$(to_exif_ts "2017:09:02 07:13:40.123")
  [[ "$result" == "2017:09:02 07:13:40.123" ]]
}

@test "to_exif_ts: EXIF timestamp without milliseconds" {
  result=$(to_exif_ts "2017:09:02 07:13:40")
  [[ "$result" == "2017:09:02 07:13:40.000" ]]
}

@test "to_exif_ts: invalid input returns empty string" {
  result=$(to_exif_ts "invalid-timestamp")
  [[ "$result" == "" ]]
}

# ====================================================================================================
# Tests for exif_ts_to_epoch_ms function
# ====================================================================================================

@test "exif_ts_to_epoch_ms: EXIF timestamp to epoch ms" {
  result=$(exif_ts_to_epoch_ms "2017:09:02 07:13:40.123")
  [[ "$result" == "1504336420123" ]]
}

# ====================================================================================================
# Tests for get_best_available_timestamp function
# ====================================================================================================
@test "get_best_available_timestamp: photo with takeout metadata" {
  local fid ts ts_epoch ts_source
  analyze_media_file "samples/google-takeout-direct-match/IMG_9087.HEIC" fid
  get_best_available_timestamp "$fid" ts ts_epoch ts_source
  echo "DEBUG: ts=$ts"
  echo "DEBUG: ts=$ts_epoch"
  [[ "$ts" == "2018:11:29 11:30:26.000" ]]
  [[ "$ts_epoch" == "1543491026000" ]]
  [[ "$ts_source" == "PhotoTakenTime" ]]
}

@test "get_best_available_timestamp: photo without takeout metadata" {
  local fid ts ts_epoch ts_source
  analyze_media_file "samples/google-takeout-no-match/DSC09311.JPG" fid
  get_best_available_timestamp "$fid" ts ts_epoch ts_source
  echo "DEBUG: ts=$ts"
  echo "DEBUG: ts=$ts_epoch"
  [[ "$ts" == "2022:03:11 12:48:26.000" ]]
  [[ "$ts_epoch" == "1647002906000" ]]
  [[ "$ts_source" == "DateTimeOriginal" ]]
}

@test "get_best_available_timestamp: movie file" {
  local fid ts ts_epoch ts_source
  analyze_media_file "samples/google-takeout-missing-geo/IMG_9806.MOV" fid
  get_best_available_timestamp "$fid" ts ts_epoch ts_source
  [[ "$ts" == "2018:01:12 06:40:49.000" ]]
  [[ "$ts_epoch" == "1515739249000" ]]
  [[ "$ts_source" == "PhotoTakenTime" ]]
}