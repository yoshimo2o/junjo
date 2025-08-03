#!/usr/bin/env bats

# Test file for get_most_likely_software_name function
# Tests software detection based on filename patterns and device information

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/parser_software.sh"

  # Clear global arrays before each test
  unset file_device_folder
  unset file_src_root_stem
  unset file_is_apple_media

  # Initialize global associative arrays
  declare -gA file_device_folder
  declare -gA file_src_root_stem
  declare -gA file_is_apple_media
}

# ====================================================================================================
# Tests for device folder detection (highest priority)
# ====================================================================================================

@test "get_most_likely_software_name: returns device folder when available" {
  local fid="test_file_1"

  # Mock global arrays
  file_device_folder["$fid"]="WhatsApp Images"
  file_src_root_stem["$fid"]="IMG_1234"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "WhatsApp Images" ]
}

# ====================================================================================================
# Tests for WhatsApp Android detection
# ====================================================================================================

@test "get_most_likely_software_name: detects WhatsApp Android IMG pattern" {
  local fid="test_file_2"

  # Mock global arrays - IMG-20151025-WA0014.jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="IMG-20151025-WA0014"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "WhatsApp" ]
}

@test "get_most_likely_software_name: detects WhatsApp Android VID pattern" {
  local fid="test_file_3"

  # Mock global arrays - VID-20151025-WA0014.mp4
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="VID-20151025-WA0014"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "WhatsApp" ]
}

@test "get_most_likely_software_name: detects WhatsApp Android with duplicate marker" {
  local fid="test_file_4"

  # Mock global arrays - IMG-20151025-WA0014(1).jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="IMG-20151025-WA0014(1)"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "WhatsApp" ]
}

# ====================================================================================================
# Tests for Facebook detection
# ====================================================================================================

@test "get_most_likely_software_name: detects Facebook numbered pattern with suffix" {
  local fid="test_file_5"

  # Mock global arrays - 69550_183690131648458_3287312_n.jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="69550_183690131648458_3287312_n"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Facebook" ]
}

@test "get_most_likely_software_name: detects Facebook numbered pattern without suffix" {
  local fid="test_file_6"
  
  # Mock global arrays - 69550_183690131648458_3287312.jpg (pattern allows optional suffix)
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="69550_183690131648458_3287312_"
  file_is_apple_media["$fid"]=0
  
  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Facebook" ]
}

@test "get_most_likely_software_name: detects Facebook FB_IMG pattern" {
  local fid="test_file_7"

  # Mock global arrays - FB_IMG_1481417432878.jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="FB_IMG_1481417432878"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Facebook" ]
}

# ====================================================================================================
# Tests for WhatsApp iOS detection (UUID with dashes)
# ====================================================================================================

@test "get_most_likely_software_name: detects WhatsApp iOS UUID with dashes" {
  local fid="test_file_8"

  # Mock global arrays - 1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D.jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D"
  file_is_apple_media["$fid"]=1

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "WhatsApp (Possibly)" ]
}

@test "get_most_likely_software_name: does not detect WhatsApp iOS pattern on non-Apple device" {
  local fid="test_file_9"

  # Mock global arrays - UUID pattern but not Apple device
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "" ]
}

# ====================================================================================================
# Tests for Telegram iOS detection (UUID without dashes)
# ====================================================================================================

@test "get_most_likely_software_name: detects Telegram iOS UUID without dashes" {
  local fid="test_file_10"

  # Mock global arrays - 1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D.jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D"
  file_is_apple_media["$fid"]=1

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Telegram (Possibly)" ]
}

@test "get_most_likely_software_name: does not detect Telegram iOS pattern on non-Apple device" {
  local fid="test_file_11"

  # Mock global arrays - UUID pattern but not Apple device
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "" ]
}

# ====================================================================================================
# Tests for iPhone Downloads detection (UUID with 2 numeric groups)
# ====================================================================================================

@test "get_most_likely_software_name: detects iPhone Downloads pattern - example 1" {
  local fid="test_file_12"

  # Mock global arrays - C588504C-4105-444E-AA60-64F9FF20F56B-11046-0000.jpg
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="C588504C-4105-444E-AA60-64F9FF20F56B-11046-0000"
  file_is_apple_media["$fid"]=1

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Downloads (Possibly)" ]
}

@test "get_most_likely_software_name: detects iPhone Downloads pattern - example 2" {
  local fid="test_file_13"

  # Mock global arrays - B4759D46-8D52-4478-BABD-34B575ABF11F-3537-00000.gif
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="B4759D46-8D52-4478-BABD-34B575ABF11F-3537-00000"
  file_is_apple_media["$fid"]=1

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Downloads (Possibly)" ]
}

@test "get_most_likely_software_name: does not detect Downloads pattern on non-Apple device" {
  local fid="test_file_16"

  # Mock global arrays - Downloads pattern but not Apple device
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="C588504C-4105-444E-AA60-64F9FF20F56B-11046-0000"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "" ]
}

# ====================================================================================================
# Tests for precedence and edge cases
# ====================================================================================================

@test "get_most_likely_software_name: device folder takes precedence over pattern matching" {
  local fid="test_file_17"

  # Mock global arrays - has both device folder and WhatsApp pattern
  file_device_folder["$fid"]="Photoshop Express"
  file_src_root_stem["$fid"]="IMG-20151025-WA0014"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "Photoshop Express" ]
}

@test "get_most_likely_software_name: returns empty for unrecognized patterns" {
  local fid="test_file_19"

  # Mock global arrays - random filename that doesn't match any pattern
  file_device_folder["$fid"]=""
  file_src_root_stem["$fid"]="random_filename_123"
  file_is_apple_media["$fid"]=0

  result="$(get_most_likely_software_name "$fid")"
  [ "$result" = "" ]
}
