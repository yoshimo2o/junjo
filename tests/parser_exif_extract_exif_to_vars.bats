#!/usr/bin/env bats

# Test file for extract_exif_to_vars function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_exif.sh"
}

teardown() {
  # Clean up any test variables
  unset cid make model width height
  unset dto software create_date
}

# ====================================================================================================
# Tests for extract_exif_to_vars basic functionality
# ====================================================================================================

@test "extract_exif_to_vars: extracts single field" {
  local make

  extract_exif_to_vars "$BATS_TEST_DIRNAME/../samples/google-takeout-direct-match/IMG_9087.HEIC" \
    "Make" -- make

  [ "$?" -eq 0 ]
  [[ -v make ]]
  [ "$make" = "Apple" ]
}

@test "extract_exif_to_vars: extracts multiple fields" {
  local make model width height

  extract_exif_to_vars "$BATS_TEST_DIRNAME/../samples/google-takeout-direct-match/IMG_9224.JPG" \
    "Make" "Model" "ImageWidth" "ImageHeight" -- \
    make model width height

  [ "$?" -eq 0 ]
  [[ -v make ]]
  [[ -v model ]]
  [[ -v width ]]
  [[ -v height ]]

  # Check actual values
  [ "$make" = "Apple" ]
  [ "$model" = "iPhone 7 Plus" ]
  [ "$width" = "4032" ]
  [ "$height" = "3024" ]
}

@test "extract_exif_to_vars: handles missing fields gracefully" {
  local dto software create_date width height

  extract_exif_to_vars "$BATS_TEST_DIRNAME/../samples/google-takeout-photo-taken-time/IMAGE005.JPG" \
    "DateTimeOriginal" "Software" "CreateDate" "ImageWidth" "ImageHeight" -- \
    dto software create_date width height

  [ "$?" -eq 0 ]
  [[ -v dto ]]
  [[ -v software ]]
  [[ -v create_date ]]
  [[ -v width ]]
  [[ -v height ]]

  # Check actual values - IMAGE005.JPG has no date fields but has other metadata
  [ "$dto" = "" ]
  [ "$software" = "Picasa" ]
  [ "$create_date" = "" ]
  [ "$width" = "320" ]
  [ "$height" = "240" ]
}