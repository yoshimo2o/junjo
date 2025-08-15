is_destination_usable() {
  local did="$1"
  local fid="$2"

  if [[ -z "${file_dest_entries["$did"]}" ]] || [[ "${file_dest_entries["$did"]}" == "$fid" ]]; then
    return 0  # true
  else
    return 1  # false
  fi
}

# Computes the destination directory based on the configured structure
# The computed path comes with trailing slash.
compute_destination_directory() {
  local fid="$1"
  local -n dest_dir_ref="$2"
  local timestamp_epoch="${file_timestamp_epoch["$fid"]}"
  # debug_string "compute_destination_directory()->fid" "$fid"
  # debug_string "compute_destination_directory()->dest_dir_ref" "$dest_dir_ref"
  # debug_string "compute_destination_directory()->timestamp_epoch" "$timestamp_epoch"

  # Compute the destination directory based on the configured structure
  dest_dir_ref=""
  for structure in "${JUNJO_OUTPUT_DIR_STRUCTURE[@]}"; do
    case "$structure" in
      "$GROUP_BY_DEVICE")
          # See `get_friendly_device_name()` for details on device name construction.
          #   e.g. 1. Exact Model   : "iPhone 7 Plus/", "Samsung SM-F926B/", "Sony XQ-DQ54/", etc.
          #        2. Device Type   : "iPhone/", "iPad/", "Android Phone/", "Android Tablet/"
          #        3. Upload Origin : "Mobile/", "Desktop/", "Web/"
          #        4. Unknown       : "Unknown/"
          local device_name="${file_device_name["$fid"]}"
          # debug_string "compute_destination_directory()->device_name" "$device_name"
          dest_dir_ref+="${device_name}/"
        ;;
      "$GROUP_BY_SOFTWARE")
          # See `get_most_likely_software_name()` for details on software name construction.
          #   e.g. 1. App Folder       : "WhatsApp Images/", "Photoshop Express/"
          #        2. Known Patterns   : "WhatsApp/", "Facebook/",
          #        3. Guessed Patterns : "Telegram (Possibly)/", "Downloads (Possibly)/"
          #        4. Other Categories : "Screenshots/", "Screen Recordings/"
          local software_name="${file_software_name["$fid"]}"
          # debug_string "compute_destination_directory()->software_name" "$software_name"
          if [[ -n "$software_name" ]]; then
            dest_dir_ref+="${software_name}/"
          fi
        ;;
      "$GROUP_BY_YEAR")
        # YYYY, e.g. "2025/"
        local year="$(epoch_ms_date_fmt "$timestamp_epoch" +%Y)"
        # debug_string "compute_destination_directory()->year" "$year"
        dest_dir_ref+="${year}/"
        ;;
      "$GROUP_BY_MONTH")
        # MM, e.g. "12/"
        local month="$(epoch_ms_date_fmt "$timestamp_epoch" +%m)"
        # debug_string "compute_destination_directory()->month" "$month"
        dest_dir_ref+="${month}/"
        ;;
      "$GROUP_BY_DAY")
        # DD, e.g. "31/"
        local day="$(epoch_ms_date_fmt "$timestamp_epoch" +%d)"
        # debug_string "compute_destination_directory()->day" "$day"
        dest_dir_ref+="${day}/"
        ;;
      "$GROUP_BY_YEAR_MONTH")
        # YYYY-MM, e.g. "2025-12/"
        local year_month="$(epoch_ms_date_fmt "$timestamp_epoch" +%Y-%m)"
        # debug_string "compute_destination_directory()->year_month" "$year_month"
        dest_dir_ref+="${year_month}/"
        ;;
      "$GROUP_BY_YEAR_MONTH_DAY")
        # YYYY-MM-DD, e.g. "2025-12-31/"
        local year_month_day="$(epoch_ms_date_fmt "$timestamp_epoch" +%Y-%m-%d)"
        # debug_string "compute_destination_directory()->year_month_day" "$year_month_day"
        dest_dir_ref+="${year_month_day}/"
        ;;
      "$GROUP_BY_DUPLICATES")
          # TODO: Include the preferred duplicate's filename in the folder.
          # If fid is marked as duplicate and not preferred, append folder
          if [[ "${file_has_duplicates[$fid]}" -eq 1 && "${file_is_preferred_duplicate[$fid]}" != 1 ]]; then
            dest_dir_ref+="Duplicates/"
          fi
        ;;
      "$GROUP_BY_LIVE_PHOTO_MISSING_VIDEO_PAIR")
          # Ignore if there is a software name
          # This is for situations where live photos are sent
          # through primarily messaging apps.
          local software_name="${file_software_name["$fid"]}"
          if [[ -n "$software_name" ]]; then
            return
          fi

          # If fid is in live_photo_missing_video[cid], append folder
          local cid="${file_exif_cid["$fid"]}"
          if [[ -n "$cid" \
                && -n "${live_photo_missing_video[$cid]+set}" \
                && "${live_photo_missing_video[$cid]}" -eq 1 ]]; then
            dest_dir_ref+="Live Photo Missing Video Pair/"
          fi
        ;;
      "$GROUP_BY_LIVE_VIDEO_MISSING_PHOTO_PAIR")
          # If fid is in live_video_missing_photo[cid], append folder
          local cid="${file_exif_cid["$fid"]}"
          if [[ -n "$cid" \
                && -n "${live_video_missing_photo[$cid]+set}" \
                && "${live_video_missing_photo[$cid]}" -eq 1 ]]; then
            dest_dir_ref+="Live Video Missing Photo Pair/"
          fi
        ;;
    esac
  done
}