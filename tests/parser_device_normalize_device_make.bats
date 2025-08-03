#!/usr/bin/env bats

# Test file for normalize_device_make function

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_device.sh"
}

teardown() {
  # Clean up any test variables
  unset result
}

# ====================================================================================================
# Tests for the examples mentioned in the function comments
# ====================================================================================================

@test "normalize_device_make: CANON -> Canon" {
  result=$(normalize_device_make "CANON")
  [ "$result" = "Canon" ]
}

@test "normalize_device_make: LG ELECTRONICS -> LG" {
  result=$(normalize_device_make "LG ELECTRONICS")
  [ "$result" = "LG" ]
}

@test "normalize_device_make: DJI Corporation Inc. -> DJI" {
  result=$(normalize_device_make "DJI Corporation Inc.")
  [ "$result" = "DJI" ]
}
