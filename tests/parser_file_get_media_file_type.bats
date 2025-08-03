#!/usr/bin/env bats

# Test file for get_media_file_type function
# Tests the media file type detection logic with mocked data

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_file.sh"

  # Clear any existing test data
  unset file_src_ext
  unset file_exif_content_identifier
  unset file_is_apple_media

  # Declare test arrays
  declare -gA file_src_ext
  declare -gA file_exif_content_identifier
  declare -gA file_is_apple_media
}

teardown() {
  # Clean up test data
  unset file_src_ext
  unset file_exif_content_identifier
  unset file_is_apple_media
}

# Helper function to set up mock data
setup_mock_file() {
  local fid="$1"
  local ext="$2"
  local cid="$3"
  local is_apple="$4"

  file_src_ext["$fid"]="$ext"
  file_exif_content_identifier["$fid"]="$cid"
  file_is_apple_media["$fid"]="$is_apple"
}

# ====================================================================================================
# Tests for JPEG/JPG/HEIC files
# ====================================================================================================

@test "get_media_file_type: JPEG with CID returns Live Photo" {
  setup_mock_file "test1" ".jpg" "ABC123DEF456" "0"

  result=$(get_media_file_type "test1")
  [ "$result" = "$FILE_TYPE_LIVE_PHOTO" ]
}

@test "get_media_file_type: HEIC with CID returns Live Photo" {
  setup_mock_file "test2" ".heic" "XYZ789GHI012" "1"

  result=$(get_media_file_type "test2")
  [ "$result" = "$FILE_TYPE_LIVE_PHOTO" ]
}

@test "get_media_file_type: JPEG without CID but Apple device returns Apple Photo" {
  setup_mock_file "test3" ".jpeg" "" "1"

  result=$(get_media_file_type "test3")
  [ "$result" = "$FILE_TYPE_APPLE_PHOTO" ]
}

@test "get_media_file_type: JPG without CID and non-Apple device returns Regular Photo" {
  setup_mock_file "test4" ".jpg" "" "0"

  result=$(get_media_file_type "test4")
  [ "$result" = "$FILE_TYPE_REGULAR_PHOTO" ]
}

@test "get_media_file_type: HEIC case insensitive with uppercase extension" {
  setup_mock_file "test5" ".HEIC" "" "1"

  result=$(get_media_file_type "test5")
  [ "$result" = "$FILE_TYPE_APPLE_PHOTO" ]
}

# ====================================================================================================
# Tests for video files
# ====================================================================================================

@test "get_media_file_type: MOV with CID returns Live Video" {
  setup_mock_file "test6" ".mov" "DEF456ABC123" "1"

  result=$(get_media_file_type "test6")
  [ "$result" = "$FILE_TYPE_LIVE_VIDEO" ]
}

@test "get_media_file_type: MP4 with CID returns Live Video" {
  setup_mock_file "test7" ".mp4" "GHI789XYZ012" "0"

  result=$(get_media_file_type "test7")
  [ "$result" = "$FILE_TYPE_LIVE_VIDEO" ]
}

@test "get_media_file_type: MOV without CID but Apple device returns Apple Video" {
  setup_mock_file "test8" ".mov" "" "1"

  result=$(get_media_file_type "test8")
  [ "$result" = "$FILE_TYPE_APPLE_VIDEO" ]
}

@test "get_media_file_type: MP4 without CID and non-Apple device returns Regular Video" {
  setup_mock_file "test9" ".mp4" "" "0"

  result=$(get_media_file_type "test9")
  [ "$result" = "$FILE_TYPE_REGULAR_VIDEO" ]
}

@test "get_media_file_type: AVI without CID and non-Apple device returns Regular Video" {
  setup_mock_file "test10" ".avi" "" "0"

  result=$(get_media_file_type "test10")
  [ "$result" = "$FILE_TYPE_REGULAR_VIDEO" ]
}

@test "get_media_file_type: 3GP case insensitive with uppercase extension" {
  setup_mock_file "test11" ".3GP" "" "0"

  result=$(get_media_file_type "test11")
  [ "$result" = "$FILE_TYPE_REGULAR_VIDEO" ]
}

# ====================================================================================================
# Tests for image files (PNG, GIF, WebP)
# ====================================================================================================

@test "get_media_file_type: PNG returns Regular Image" {
  setup_mock_file "test12" ".png" "" "0"

  result=$(get_media_file_type "test12")
  [ "$result" = "$FILE_TYPE_REGULAR_IMAGE" ]
}

@test "get_media_file_type: PNG with Apple device still returns Regular Image" {
  setup_mock_file "test13" ".png" "" "1"

  result=$(get_media_file_type "test13")
  [ "$result" = "$FILE_TYPE_REGULAR_IMAGE" ]
}

@test "get_media_file_type: GIF returns Regular Image" {
  setup_mock_file "test14" ".gif" "" "0"

  result=$(get_media_file_type "test14")
  [ "$result" = "$FILE_TYPE_REGULAR_IMAGE" ]
}

@test "get_media_file_type: WebP returns Regular Image" {
  setup_mock_file "test15" ".webp" "" "1"

  result=$(get_media_file_type "test15")
  [ "$result" = "$FILE_TYPE_REGULAR_IMAGE" ]
}

@test "get_media_file_type: WebP case insensitive with uppercase extension" {
  setup_mock_file "test16" ".WEBP" "" "0"

  result=$(get_media_file_type "test16")
  [ "$result" = "$FILE_TYPE_REGULAR_IMAGE" ]
}

# ====================================================================================================
# Tests for unknown file types
# ====================================================================================================

@test "get_media_file_type: unknown extension returns Unknown" {
  setup_mock_file "test17" ".xyz" "" "0"

  result=$(get_media_file_type "test17")
  [ "$result" = "$FILE_TYPE_UNKNOWN" ]
}

@test "get_media_file_type: TXT file returns Unknown" {
  setup_mock_file "test18" ".txt" "" "1"

  result=$(get_media_file_type "test18")
  [ "$result" = "$FILE_TYPE_UNKNOWN" ]
}

@test "get_media_file_type: empty extension returns Unknown" {
  setup_mock_file "test19" "" "" "0"

  result=$(get_media_file_type "test19")
  [ "$result" = "$FILE_TYPE_UNKNOWN" ]
}

# ====================================================================================================
# Edge cases and boundary tests
# ====================================================================================================

@test "get_media_file_type: CID takes precedence over Apple device detection for photos" {
  setup_mock_file "test20" ".jpg" "PRIORITY_TEST" "1"

  result=$(get_media_file_type "test20")
  [ "$result" = "$FILE_TYPE_LIVE_PHOTO" ]
}

@test "get_media_file_type: CID takes precedence over Apple device detection for videos" {
  setup_mock_file "test21" ".mov" "PRIORITY_TEST" "1"

  result=$(get_media_file_type "test21")
  [ "$result" = "$FILE_TYPE_LIVE_VIDEO" ]
}

@test "get_media_file_type: missing CID field defaults to empty" {
  setup_mock_file "test22" ".jpg" "" "0"
  unset file_exif_content_identifier["test22"]

  result=$(get_media_file_type "test22")
  [ "$result" = "$FILE_TYPE_REGULAR_PHOTO" ]
}

@test "get_media_file_type: missing Apple media flag defaults to 0" {
  setup_mock_file "test23" ".jpg" "" "0"
  unset file_is_apple_media["test23"]

  result=$(get_media_file_type "test23")
  [ "$result" = "$FILE_TYPE_REGULAR_PHOTO" ]
}

@test "get_media_file_type: Apple media flag as string '1' works" {
  file_src_ext["test24"]=".jpg"
  file_exif_content_identifier["test24"]=""
  file_is_apple_media["test24"]="1"

  result=$(get_media_file_type "test24")
  [ "$result" = "$FILE_TYPE_APPLE_PHOTO" ]
}

@test "get_media_file_type: Apple media flag as string '0' works" {
  file_src_ext["test25"]=".jpg"
  file_exif_content_identifier["test25"]=""
  file_is_apple_media["test25"]="0"

  result=$(get_media_file_type "test25")
  [ "$result" = "$FILE_TYPE_REGULAR_PHOTO" ]
}
