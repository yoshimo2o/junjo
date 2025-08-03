#!/usr/bin/env bats

# ====================================================================================================
# BATS tests for extract_takeout_metadata() function in parser_takeout.sh
# ====================================================================================================

setup() {
  # Source the parser_takeout.sh file to get access to the function
  source "${BATS_TEST_DIRNAME}/../lib/parser_takeout.sh"

  # Set up sample file paths
  SAMPLES_DIR="${BATS_TEST_DIRNAME}/../samples"
}

# ====================================================================================================
# Test photoTakenTime extraction
# ====================================================================================================

@test "extract_takeout_metadata: extracts photoTakenTime.timestamp correctly" {
  local test_file="${SAMPLES_DIR}/google-takeout-photo-taken-time/IMAGE005.JPG.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$photo_taken_time" = "1026484386" ]
}

# ====================================================================================================
# Test geoDataExif extraction
# ====================================================================================================

@test "extract_takeout_metadata: extracts geoDataExif with valid coordinates" {
  local test_file="${SAMPLES_DIR}/google-takeout-missing-geo/IMG_9806.MOV.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  # Should contain geoDataExif JSON since coordinates are non-zero
  [[ "$geo_data" == *"latitude"* ]]
  [[ "$geo_data" == *"25.0333"* ]]
  [[ "$geo_data" == *"121.564"* ]]
}

# ====================================================================================================
# Test deviceType extraction
# ====================================================================================================

@test "extract_takeout_metadata: extracts deviceType for iOS device" {
  local test_file="${SAMPLES_DIR}/google-takeout-direct-match/IMG_9087.HEIC.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$device_type" = "IOS_PHONE" ]
}

@test "extract_takeout_metadata: extracts deviceType for Android device" {
  local test_file="${SAMPLES_DIR}/whatsapp-android/IMG-20150916-WA0002.jpg.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$device_type" = "ANDROID_PHONE" ]
}

# ====================================================================================================
# Test deviceFolder extraction
# ====================================================================================================

@test "extract_takeout_metadata: extracts deviceFolder from WhatsApp upload" {
  local test_file="${SAMPLES_DIR}/whatsapp-android/IMG-20150916-WA0002.jpg.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$device_folder" = "WhatsApp Images" ]
}

@test "extract_takeout_metadata: returns empty deviceFolder when not present" {
  local test_file="${SAMPLES_DIR}/google-takeout-direct-match/IMG_9087.HEIC.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$device_folder" = "" ]
}

# ====================================================================================================
# Test upload_origin detection
# ====================================================================================================

@test "extract_takeout_metadata: detects mobile upload origin" {
  local test_file="${SAMPLES_DIR}/google-takeout-duplication-match/IMG_3238.JPG.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$upload_origin" = "mobile" ]
}

@test "extract_takeout_metadata: detects desktop upload origin" {
  local test_file="${SAMPLES_DIR}/google-takeout-photo-taken-time/IMAGE005.JPG.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$upload_origin" = "desktop" ]
}

@test "extract_takeout_metadata: detects web upload origin" {
  local test_file="${SAMPLES_DIR}/facebook/69550_183690131648458_3287312_n.jpg.supplement.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$upload_origin" = "web" ]
}

# ====================================================================================================
# Test error handling
# ====================================================================================================

@test "extract_takeout_metadata: returns error for non-existent file" {
  local photo_taken_time geo_data device_type device_folder upload_origin

  run extract_takeout_metadata "/nonexistent/file.json" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$status" -eq 1 ]
}

@test "extract_takeout_metadata: handles malformed JSON gracefully" {
  # Create a temporary malformed JSON file
  local temp_file=$(mktemp)
  echo '{ invalid json' > "$temp_file"

  local photo_taken_time geo_data device_type device_folder upload_origin

  run extract_takeout_metadata "$temp_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$status" -eq 1 ]

  # Clean up
  rm "$temp_file"
}

# ====================================================================================================
# Test comprehensive extraction from a complex file
# ====================================================================================================

@test "extract_takeout_metadata: extracts all metadata from WhatsApp Android file" {
  local test_file="${SAMPLES_DIR}/whatsapp-android/IMG-20150916-WA0002.jpg.supplemental-metadata.json"
  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$test_file" photo_taken_time geo_data device_type device_folder upload_origin

  # Verify all extracted values
  [ "$photo_taken_time" = "1442440705" ]
  [[ "$geo_data" == *"52.037662499999996"* ]]  # Contains latitude from geoDataExif
  [ "$device_type" = "ANDROID_PHONE" ]
  [ "$device_folder" = "WhatsApp Images" ]
  [ "$upload_origin" = "mobile" ]
}

# ====================================================================================================
# Test edge cases
# ====================================================================================================

@test "extract_takeout_metadata: handles missing photoTakenTime gracefully" {
  # Create a temporary JSON file without photoTakenTime
  local temp_file=$(mktemp)
  cat > "$temp_file" << 'EOF'
{
  "title": "test.jpg",
  "googlePhotosOrigin": {
    "mobileUpload": {
      "deviceType": "IOS_PHONE"
    }
  }
}
EOF

  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$temp_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$photo_taken_time" = "" ]
  [ "$device_type" = "IOS_PHONE" ]
  [ "$upload_origin" = "mobile" ]

  # Clean up
  rm "$temp_file"
}

@test "extract_takeout_metadata: handles missing geo data gracefully" {
  # Create a temporary JSON file without geo data
  local temp_file=$(mktemp)
  cat > "$temp_file" << 'EOF'
{
  "title": "test.jpg",
  "photoTakenTime": {
    "timestamp": "1234567890"
  },
  "googlePhotosOrigin": {
    "mobileUpload": {
      "deviceType": "IOS_PHONE"
    }
  }
}
EOF

  local photo_taken_time geo_data device_type device_folder upload_origin

  extract_takeout_metadata "$temp_file" photo_taken_time geo_data device_type device_folder upload_origin

  [ "$photo_taken_time" = "1234567890" ]
  [ "$geo_data" = "" ]
  [ "$device_type" = "IOS_PHONE" ]
  [ "$upload_origin" = "mobile" ]

  # Clean up
  rm "$temp_file"
}
