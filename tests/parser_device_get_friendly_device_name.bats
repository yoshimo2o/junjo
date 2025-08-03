#!/usr/bin/env bats

# Test file for get_friendly_device_name function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_device.sh"

  # Clear any existing test data
  unset file_exif_make file_exif_model file_exif_lens_make file_exif_lens_model
  unset file_takeout_device_type file_takeout_upload_origin

  # Declare test arrays
  declare -gA file_exif_make
  declare -gA file_exif_model
  declare -gA file_exif_lens_make
  declare -gA file_exif_lens_model
  declare -gA file_takeout_device_type
  declare -gA file_takeout_upload_origin
}

teardown() {
  # Clean up test data
  unset file_exif_make file_exif_model file_exif_lens_make file_exif_lens_model
  unset file_takeout_device_type file_takeout_upload_origin
  unset result
}

# Helper function to set up mock EXIF data
setup_exif_data() {
  local fid="$1"
  local make="$2"
  local model="$3"
  local lens_make="$4"
  local lens_model="$5"

  file_exif_make["$fid"]="$make"
  file_exif_model["$fid"]="$model"
  file_exif_lens_make["$fid"]="$lens_make"
  file_exif_lens_model["$fid"]="$lens_model"
}

# Helper function to set up mock Takeout data
setup_takeout_data() {
  local fid="$1"
  local device_type="$2"
  local upload_origin="$3"

  file_takeout_device_type["$fid"]="$device_type"
  file_takeout_upload_origin["$fid"]="$upload_origin"
}

# ====================================================================================================
# Tests for Apple devices
# ====================================================================================================

@test "get_friendly_device_name: Apple device uses model only" {
  setup_exif_data "test1" "Apple" "iPhone 15 Pro Max" "" ""

  result=$(get_friendly_device_name "test1")
  [ "$result" = "iPhone 15 Pro Max" ]
}

@test "get_friendly_device_name: Apple iPad device" {
  setup_exif_data "test2" "Apple" "iPad Pro" "" ""

  result=$(get_friendly_device_name "test2")
  [ "$result" = "iPad Pro" ]
}

@test "get_friendly_device_name: iPhone 4 lens fallback - back camera" {
  setup_exif_data "test3" "" "" "Apple" "iPhone 4 back camera 3.85mm f/2.8"

  result=$(get_friendly_device_name "test3")
  [ "$result" = "iPhone 4" ]
}

@test "get_friendly_device_name: iPhone 4 lens fallback - front camera" {
  setup_exif_data "test4" "" "" "Apple" "iPhone 4 front camera 2.85mm f/2.8"

  result=$(get_friendly_device_name "test4")
  [ "$result" = "iPhone 4" ]
}

@test "get_friendly_device_name: Apple lens fallback - no match pattern" {
  setup_exif_data "test6" "" "" "Apple" "Some Unknown Apple Lens"

  result=$(get_friendly_device_name "test6")
  [ "$result" = "Apple Unknown" ]
}

# ====================================================================================================
# Tests for device make and model normalization
# ====================================================================================================

@test "get_friendly_device_name: Shortened make names" {
  setup_exif_data "test8" "LG ELECTRONICS" "H870" "" ""

  result=$(get_friendly_device_name "test8")
  [ "$result" = "LG H870" ]
}

@test "get_friendly_device_name: No repeated make names" {
  setup_exif_data "test10" "CANON" "Canon IXUS 185" "" ""

  result=$(get_friendly_device_name "test10")
  [ "$result" = "Canon IXUS 185" ]
}

@test "get_friendly_device_name: Regular make and model device name" {
  setup_exif_data "test11" "SONY" "ILCE-7RM4" "" ""

  result=$(get_friendly_device_name "test11")
  [ "$result" = "Sony ILCE-7RM4" ]
}


# ====================================================================================================
# Tests for model-only scenarios
# ====================================================================================================

@test "get_friendly_device_name: Model only, no make" {
  setup_exif_data "test13" "" "SM-G973F" "" ""

  result=$(get_friendly_device_name "test13")
  [ "$result" = "SM-G973F" ]
}

# ====================================================================================================
# Tests for device type fallback
# ====================================================================================================

@test "get_friendly_device_name: Takeout IOS_PHONE fallback" {
  setup_exif_data "test14" "" "" "" ""
  setup_takeout_data "test14" "IOS_PHONE" ""

  result=$(get_friendly_device_name "test14")
  [ "$result" = "iPhone" ]
}

@test "get_friendly_device_name: Takeout IOS_TABLET fallback" {
  setup_exif_data "test15" "" "" "" ""
  setup_takeout_data "test15" "IOS_TABLET" ""

  result=$(get_friendly_device_name "test15")
  [ "$result" = "iPad" ]
}

@test "get_friendly_device_name: Takeout ANDROID_PHONE fallback" {
  setup_exif_data "test16" "" "" "" ""
  setup_takeout_data "test16" "ANDROID_PHONE" ""

  result=$(get_friendly_device_name "test16")
  [ "$result" = "Android Phone" ]
}

@test "get_friendly_device_name: Takeout ANDROID_TABLET fallback" {
  setup_exif_data "test17" "" "" "" ""
  setup_takeout_data "test17" "ANDROID_TABLET" ""

  result=$(get_friendly_device_name "test17")
  [ "$result" = "Android Tablet" ]
}

# ====================================================================================================
# Tests for upload origin fallback
# ====================================================================================================

@test "get_friendly_device_name: Takeout upload origin mobile fallback" {
  setup_exif_data "test18" "" "" "" ""
  setup_takeout_data "test18" "" "mobile"

  result=$(get_friendly_device_name "test18")
  [ "$result" = "Mobile" ]
}

@test "get_friendly_device_name: Takeout upload origin desktop fallback" {
  setup_exif_data "test19" "" "" "" ""
  setup_takeout_data "test19" "" "desktop"

  result=$(get_friendly_device_name "test19")
  [ "$result" = "Desktop" ]
}

@test "get_friendly_device_name: Takeout upload origin web fallback" {
  setup_exif_data "test20" "" "" "" ""
  setup_takeout_data "test20" "" "web"

  result=$(get_friendly_device_name "test20")
  [ "$result" = "Web" ]
}

# ====================================================================================================
# Tests for unknown fallback
# ====================================================================================================

@test "get_friendly_device_name: Completely unknown device" {
  setup_exif_data "test21" "" "" "" ""
  setup_takeout_data "test21" "" ""

  result=$(get_friendly_device_name "test21")
  [ "$result" = "Unknown" ]
}
