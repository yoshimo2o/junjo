# ====================================================================================================
# scan_media_folder
#
# Scans a directory for media files based on configuration settings and initiates analysis.
# This function handles file discovery using configurable include/exclude patterns and
# depth settings, then passes discovered files to the analysis pipeline.
#
# Configuration Variables Used:
#   - JUNJO_SCAN_DIR           → Directory to scan for media files
#   - JUNJO_SCAN_RECURSIVE     → Enable recursive scanning (1) or single level (0)
#   - JUNJO_INCLUDE_FILES[]    → Array of filename patterns to include (e.g., "*.jpg")
#   - JUNJO_EXCLUDE_FILES[]    → Array of filename patterns to exclude (e.g., ".*")
#
# Process Flow:
#   1. Configure find command depth based on recursive setting
#   2. Build include/exclude arguments from pattern arrays
#   3. Execute find command to locate matching files
#   4. Log scan parameters and file count
#   5. Exit early if no files found, otherwise start analysis
#
# Returns:
#   0 on success, exits with 0 if no files found
# ====================================================================================================
scan_media_folder() {

  # Set find depth option based on recursive flag
  if [[ $JUNJO_SCAN_RECURSIVE -eq 1 ]]; then
    find_depth=""
  else
    find_depth="-maxdepth 1"
  fi

  # Build include_args from JUNJO_INCLUDE_FILES array
  include_args=""
  if [[ ${#JUNJO_INCLUDE_FILES[@]} -gt 0 ]]; then
    include_args="\\("
    for i in "${!JUNJO_INCLUDE_FILES[@]}"; do
      if [[ $i -gt 0 ]]; then
        include_args+=" -o"
      fi
      include_args+=" -iname \"${JUNJO_INCLUDE_FILES[$i]}\""
    done
    include_args+=" \\)"
  fi

  # Build exclude_args from JUNJO_EXCLUDE_FILES array
  exclude_args=""
  if [[ ${#JUNJO_EXCLUDE_FILES[@]} -gt 0 ]]; then
    for pattern in "${JUNJO_EXCLUDE_FILES[@]}"; do
      [[ -n "$pattern" ]] && exclude_args+=" ! -iname \"$pattern\""
    done
  fi

  # Inform user we're about to scan the directory
  log_tree_start "Starting folder scan with parameters:"
    log_tree "Directory: $(realpath "$JUNJO_SCAN_DIR")"
    log_tree "Recursive: $([ $JUNJO_SCAN_RECURSIVE -eq 1 ] && echo 'Yes' || echo 'No')"
    log_tree "Include patterns: ${JUNJO_INCLUDE_FILES[*]}"
    log_tree_end "Exclude patterns: ${JUNJO_EXCLUDE_FILES[*]}"

  # Get the list of files to analyze
  mapfile -t files < <(eval "find \"$JUNJO_SCAN_DIR\" $find_depth -type f $include_args $exclude_args")

  # If no files found, exit early
  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No scannable files found in '$JUNJO_SCAN_DIR'."
    exit 0
  fi

  # Inform user the number of files found
  log "Found ${#files[@]} files to analyze in '$JUNJO_SCAN_DIR'."

  # If interactive mode is enabled, ask users to confirm before proceeding
  if [[ $JUNJO_INTERACTIVE -eq 1 ]]; then
    log_raw ""
    if ! confirm "Do you want to analyze these files?"; then
      exit 0
    fi
    log_raw ""
  fi

  # Analyze the files
  analyze_media_files "${files[@]}"
}

# ====================================================================================================
# analyze_media_files <media_file1> [media_file2] [...]
#
# Processes an array of media files through comprehensive analysis pipeline.
# This function orchestrates the analysis of multiple files, providing progress tracking
# and coordinating individual file analysis through analyze_media_file().
#
# Parameters:
#   media_files  → Variable number of media file paths to analyze
#
# Process Flow:
#   1. Log analysis start with file count
#   2. Iterate through each media file with progress tracking
#   3. Call analyze_media_file() for detailed metadata extraction
#   4. Update progress counter and log completion status
#   5. Prepare for live photo/video processing (currently commented)
#
# Global Arrays Modified:
#   All file metadata arrays are populated via analyze_media_file() calls:
#   - file_src[], file_exif_*, file_takeout_*, file_timestamp[], etc.
#   - File type categorization arrays: live_photo_files[], apple_photo_files[], etc.
#
# Configuration Variables Used:
#   - JUNJO_SCAN_DIR  → Used in logging messages
#
# Returns:
#   0 on success
#
# Example usage:
#   files=("/path/to/img1.jpg" "/path/to/video.mov" "/path/to/photo.heic")
#   analyze_media_files "${files[@]}"
# ====================================================================================================
# Analyze an array of files
analyze_media_files() {
  local media_files=("$@")

  # For each file, we will extract all the information we need for analysis and sorting
  local index=1
  local total=${#media_files[@]}

  # Inform user we're starting the analysis
  log "Starting analysis of $total files in '$JUNJO_SCAN_DIR'."

  for media_file in "${media_files[@]}"; do
    local fid
    log "[$(progress "$index" "$total" "/")] Analyzing file: $media_file"
    analyze_media_file "$media_file" fid
    index=$((index + 1))
  done

  # Process live photos and videos
  # process_live_media()
}

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
  local -n fid_ref="$2"

  # Generate a unique file ID based on the file path's Base64 encoding
  # This ID is used as the key for all global arrays to store file metadata
  fid="$(get_media_file_id "$media_file")"

  # Analyze file components
  local file_dir \
        file_name \
        file_stem \
        file_root_stem \
        file_ext \
        file_compound_ext \
        file_dupe_marker

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

  if [[ -n "$takeout_meta_file" ]]; then
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