# ====================================================================================================
# get_most_likely_software_name <fid>
#
# Determines the software/platform that likely created the file based on its filename pattern
# and device information. Returns the most likely software name or uses device folder if available.
#
# Detection patterns:
#   - WhatsApp Android: IMG-YYYYMMDD-WA#### or VID-YYYYMMDD-WA####
#   - Facebook: ####_####_####_[nosaq] or FB_IMG_####
#   - Device folder: Uses the device folder property from Google Takeout metadata (if available).
#
# Guessed patterns:
#   - WhatsApp iOS: UUID with dashes (8-4-4-4-12 format)
#   - Telegram iOS: UUID without dashes (32 hex characters)
#   - iPhone Downloads: UUID with 2 additional numeric groups
#
# Parameters:
#   1. fid  → File ID for the media file to analyze
#
# Return:
#   Most likely software name used to create the media file, e.g.
#     e.g. WhatApp, Facebook, Downloads, etc.
##
# Example usage:
#   software="$(get_software_name "$file_id")"
#   echo "Detected software: $software"
# ====================================================================================================

get_most_likely_software_name() {

  local fid="$1"
  local device_folder="${file_device_folder["$fid"]:-}"

  # If device folder exists, use it.
  # e.g. Android Phone/WhatsApp Images/IMG-20151025-WA0014.jpg
  if [[ -n "$device_folder" ]]; then
    echo "$device_folder"
    return 0
  fi

  # If Creator Tool exif metadata exists, use it.
  # e.g. iPhone/Facebook/8BDF8051-2110-4653-8029-70A465C05DE9.jpg
  local creator_tool="${file_exif_creator_tool["$fid"]:-}"
  if [[ -n "$creator_tool" ]]; then
    echo "$creator_tool"
    return 0
  fi

  local file_root_stem="${file_src_root_stem["$fid"]}"

  # If the filename looks like a WhatsApp image or video.
  # e.g. Android Phone/WhatsApp/IMG-20151025-WA0014.jpg
  #      Android Phone/WhatsApp/VID-20151025-WA0014.mp4,
  if [[ "$file_root_stem" =~ ^(IMG|VID)-[0-9]{8}-WA[0-9]{4} ]]; then
    echo "WhatsApp"
    return 0
  fi

  # If the filename looks like Facebook media files,
  # e.g. Desktop/Facebook/69550_183690131648458_3287312_[n|o|s|a|b|q].jpg
  #      Desktop/Facebook/FB_IMG_1481417432878.jpg
  if [[ "$file_root_stem" =~ ^[0-9]+_[0-9]+_[0-9]+_[nosaq]?$ || \
        "$file_root_stem" =~ ^FB_IMG_[0-9]+$ ]]; then
    echo "Facebook"
    return 0
  fi

  local is_apple_media="${file_is_apple_media["$fid"]:-0}"

  # If the filename looks like lowercased UUID with dashes
  # it is very likely WhatsApp media files on iOS devices.
  # e.g. iPhone/WhatsApp (Possibly)/1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D.jpg
  if [[ $is_apple_media -eq 1 && "$file_root_stem" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      echo "WhatsApp (Possibly)"
      return 0
  fi

  # If the filename looks like lowercased UUID without dashes
  # it is very likely Telegram media files on iOS devices.
  # e.g. iPhone/Telegram (Possibly)/d98bb755ab6296163d9df3094ae41d73.jpg
  if [[ $is_apple_media -eq 1 && "$file_root_stem" =~ ^[0-9a-f]{32}$ ]]; then
      echo "Telegram (Possibly)"
      return 0
  fi

  # If the filename looks like a UUID with dashes and contains extra 2 numeric groups where
  # that extra numeric groups can be of any length, it is very likely a downloaded media file
  # on iPhone. Here are some examples:
  #   C588504C-4105-444E-AA60-64F9FF20F56B-11046-0000.jpg
  #   B4759D46-8D52-4478-BABD-34B575ABF11F-3537-00000.gif
  #   76F606DB-4579-4A04-9043-29115C9F4F79-422-00000.jpg
  #   25C0BCA9-DC76-430B-AA01-FAB906A596E0-90216-000.jpg
  #
  # e.g. iPhone/Downloads/C588504C-4105-444E-AA60-64F9FF20F56B-11046-0000.jpg
  #      iPad/Downloads/B4759D46-8D52-4478-BABD-34B575ABF11F-3537-00000.gif
  if [[ $is_apple_media -eq 1 && "$file_root_stem" =~ ^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}-[0-9]+-[0-9]+$ ]]; then
    echo "Downloads (Possibly)"
    return 0
  fi
}