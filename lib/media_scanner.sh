
# ====================================================================================================
# analyze_media_file <media_file>
#
# Performs comprehensive analysis of a media file and populates global arrays with extracted metadata.
# This function serves as the main entry point for analyzing individual media files, extracting and
# organizing metadata from multiple sources including file system, EXIF data, and Google Takeout.
#
# Parameters:
#   media_file - Path to the media file to analyze
#
# Global Arrays Populated:
#   File Source Properties:
#     - file_src[fid]                    → Full path to the source file
#     - file_src_dir[fid]                → Directory containing the file
#     - file_src_name[fid]               → Full filename with extension
#     - file_src_stem[fid]               → Filename without extension
#     - file_src_root_stem[fid]          → Filename without extension and duplicate markers
#     - file_src_ext[fid]                → File extension (e.g., ".JPG")
#     - file_src_compound_ext[fid]       → Compound extension (e.g., ".HEIC.MOV")
#     - file_src_dupe_marker[fid]        → Duplicate marker (e.g., "1" from "IMG_001(1).JPG")
#     - file_src_create_date[fid]        → File system creation date
#     - file_src_modify_date[fid]        → File system modification date
#
#   Google Takeout Metadata:
#     - file_takeout_meta_file[fid]      → Path to associated JSON metadata file
#     - file_takeout_meta_file_name[fid] → Name of the JSON metadata file
#     - file_takeout_meta_file_match_strategy[fid] → Matching strategy used ("direct", "truncation", "duplication")
#     - file_takeout_photo_taken_time[fid] → Photo taken timestamp from Google Takeout
#     - file_takeout_geo_data[fid]       → Geographic location data (JSON format)
#     - file_takeout_device_type[fid]    → Device type (e.g., "IOS_PHONE", "ANDROID_PHONE")
#     - file_takeout_device_folder[fid]  → Source folder/app name
#     - file_takeout_upload_origin[fid]  → Upload origin ("mobile", "desktop", "web")
#
#   EXIF Metadata:
#     - file_exif_cid[fid]               → Content Identifier from EXIF
#     - file_exif_make[fid]              → Camera/device manufacturer
#     - file_exif_model[fid]             → Camera/device model
#     - file_exif_lens_make[fid]         → Lens manufacturer
#     - file_exif_lens_model[fid]        → Lens model
#     - file_exif_image_width[fid]       → Image width in pixels
#     - file_exif_image_height[fid]      → Image height in pixels
#     - file_exif_image_size[fid]        → Image dimensions (e.g., "4032x3024")
#     - file_exif_date_time_original[fid] → Original date/time from EXIF
#     - file_exif_create_date[fid]       → Creation date from EXIF
#     - file_exif_track_create_date[fid] → Track creation date (for videos)
#     - file_exif_media_create_date[fid] → Media creation date
#     - file_exif_user_comment[fid]      → User comment from EXIF
#
#   Analysis Results:
#     - file_is_apple_media[fid]         → "1" if Apple device, "0" otherwise
#     - file_timestamp[fid]              → Best available timestamp (formatted)
#     - file_timestamp_source[fid]       → Source of the timestamp (e.g., "PhotoTakenTime", "EXIF")
#     - file_device_name[fid]            → Friendly device name
#     - file_software_name[fid]          → Software/app name that created the file
#
#   File Type Arrays (adds file to appropriate category):
#     - live_photo_files[fid]            → Apple Live Photos
#     - live_video_files[fid]            → Apple Live Photo videos
#     - apple_photo_files[fid]           → Apple device photos
#     - apple_video_files[fid]           → Apple device videos
#     - regular_photo_files[fid]         → Regular photos
#     - regular_video_files[fid]         → Regular videos
#     - regular_image_files[fid]         → Regular images
#     - screenshot_files[fid]            → Screenshots
#     - screen_recording_files[fid]      → Screen recordings
#     - unknown_files[fid]               → Files of unknown type
#
# Returns:
#   0 on success, non-zero on error
#
# Example:
#   analyze_media_file "/path/to/IMG_1234.jpg"
#   fid=$(get_media_file_id "/path/to/IMG_1234.jpg")
#   echo "Device: ${file_device_name[$fid]}"
#   echo "Timestamp: ${file_timestamp[$fid]}"
#
# ====================================================================================================

# Analyze a single file
analyze_media_file() {
  local media_file="$1"
  local -n fid_ref=""

  # Generate a unique file ID based on the file path's Base64 encoding
  # This ID is used as the key for all global arrays to store file metadata
  fid="$(get_media_file_id "$media_file")"

  # Analyze file components
  local file_dir file_name file_stem file_root_stem file_ext file_compound_ext file_dupe_marker

  get_media_file_path_components "$media_file" \
    file_dir \
    file_name \
    file_stem \
    file_root_stem \
    file_ext \
    file_compound_ext \
    file_dupe_marker

  file_src["$fid"]="$media_file"
  file_src_dir["$fid"]="$file_dir"
  file_src_name["$fid"]="$file_name"
  file_src_stem["$fid"]="$file_stem"
  file_src_root_stem["$fid"]="$file_root_stem"
  file_src_ext["$fid"]="$file_ext"
  file_src_compound_ext["$fid"]="$file_compound_ext"
  file_src_dupe_marker["$fid"]="$file_dupe_marker"

  # Analyze Google Takeout metadata (if available)
  local takeout_meta_file \
        takeout_meta_file_name \
        takeout_meta_file_match_strategy

  locate_takeout_meta_file "$media_file" \
    takeout_meta_file \
    takeout_meta_file_name \
    takeout_meta_file_match_strategy

  file_takeout_meta_file["$fid"]="$takeout_meta_file"
  file_takeout_meta_file_name["$fid"]="$takeout_meta_file_name"
  file_takeout_meta_file_match_strategy["$fid"]="$takeout_meta_file_match_strategy"

  if [[ -n "$takeout_meta_file" ]] then
    local takeout_meta_photo_taken_time \
          takeout_meta_geo_data \
          takeout_meta_device_type \
          takeout_meta_device_folder \
          takeout_meta_upload_origin

    extract_takeout_metadata "$takeout_meta_file" \
      takeout_meta_photo_taken_time \
      takeout_meta_geo_data \
      takeout_meta_device_type \
      takeout_meta_device_folder \
      takeout_meta_upload_origin

    file_takeout_photo_taken_time["$fid"]="$takeout_meta_photo_taken_time"
    file_takeout_geo_data["$fid"]="$takeout_meta_geo_data"
    file_takeout_device_type["$fid"]="$takeout_meta_device_type"
    file_takeout_device_folder["$fid"]="$takeout_meta_device_folder"
    file_takeout_upload_origin["$fid"]="$takeout_meta_upload_origin"
  fi

  # Analyze EXIF metadata
  local cid \
        device_make \
        device_model \
        lens_make \
        lens_model \
        image_width \
        image_height \
        image_size \
        date_time_original \
        create_date \
        track_create_date \
        media_create_date \
        user_comment \
        file_create_date \
        file_modify_date

  extract_exif_metadata "$media_file" \
    cid \
    device_make \
    device_model \
    lens_make \
    lens_model \
    image_width \
    image_height \
    image_size \
    date_time_original \
    create_date \
    track_create_date \
    media_create_date \
    user_comment \
    file_create_date \
    file_modify_date

  file_exif_cid["$fid"]="$cid"
  file_exif_make["$fid"]="$device_make"
  file_exif_model["$fid"]="$device_model"
  file_exif_lens_make["$fid"]="$lens_make"
  file_exif_lens_model["$fid"]="$lens_model"
  file_exif_image_width["$fid"]="$image_width"
  file_exif_image_height["$fid"]="$image_height"
  file_exif_image_size["$fid"]="$image_size"
  file_exif_date_time_original["$fid"]="$date_time_original"
  file_exif_create_date["$fid"]="$create_date"
  file_exif_track_create_date["$fid"]="$track_create_date"
  file_exif_media_create_date["$fid"]="$media_create_date"
  file_exif_user_comment["$fid"]="$user_comment"
  file_src_create_date["$fid"]="$file_create_date"
  file_src_modify_date["$fid"]="$file_modify_date"

  # Also determine if this is an Apple media file
  file_is_apple_media["$fid"]=$(
    [[ "$device_make" == *"Apple"* ]] || [[ "$lens_make" == *"Apple"* ]] || \
    [[ "$device_model" == "iPhone"* || "$device_model" == "iPad"* || "$device_model" == "iOS"* ]] || \
    [[ "$lens_model" == "iPhone"* || "$lens_model" == "iPad"* || "$lens_model" == "iOS"* ]] \
    && echo "1" || echo "0"
  )

  # Analyze timestamps
  local timestamp \
        timestamp_source

  get_best_available_timestamp "$media_file" \
    timestamp \
    timestamp_source

  file_timestamp["$fid"]="$timestamp"
  file_timestamp_source["$fid"]="$timestamp_source"

  # Analyze file type
  local file_type
  file_type=$(get_media_file_type "$fid")

  # Add files to our lists that is mapped by file type
  case "$file_type" in
    "$FILE_TYPE_LIVE_PHOTO")
      live_photo_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_LIVE_VIDEO")
      live_video_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_APPLE_PHOTO")
      apple_photo_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_APPLE_VIDEO")
      apple_video_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_REGULAR_PHOTO")
      regular_photo_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_REGULAR_VIDEO")
      regular_video_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_REGULAR_IMAGE")
      regular_image_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_SCREENSHOT")
      screenshot_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_SCREEN_RECORDING")
      screen_recording_files["$fid"]="$media_file"
      ;;
    "$FILE_TYPE_UNKNOWN")
      unknown_files["$fid"]="$media_file"
      ;;
  esac

  # Analyze device info
  device_name=$(get_friendly_device_name "$fid")
  file_device_name["$fid"]="$device_name"

  # Analyze software info
  software_name=$(get_most_likely_software_name "$fid")
  file_software_name["$fid"]="$software_name"

  fid_ref="$fid"
  return 0
}