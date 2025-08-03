source "$JUNJO_LIB_DIR/parser_file.sh"
source "$JUNJO_LIB_DIR/parser_takeout.sh"

# ====================================================================================================
# get_best_available_timestamp <media_file>
#                              <&timestamp>
#                              <&timestamp_source>
#
# Extracts the best available timestamp from a media file
# using ExifTool and Google Takeout JSON metadata.
#
# Priority order:
#   1. PhotoTakenTime (from Google Takeout Metadata, most reliable)
#   2. DateTimeOriginal
#   3. CreateDate
#   4. TrackCreateDate
#   5. MediaCreateDate
#   6. FileCreateDate (file creation time, if available)
#   7. FileModifyDate (file modification time, always available)
#
# Arguments:
#   $1: media_file         → Path to the media file
#   $2: timestamp          → Variable to store the normalized timestamp
#   $3: timestamp_source   → Variable to store the timestamp source field name
#
# Output values:
#   - timestamp: Normalized to "YYYY:MM:DD HH:MM:SS.sss" format
#     - UNIX epochs converted from seconds to Exif timestamp format (UTC)
#     - Milliseconds padded with .000 if missing
#     - Timezone info (Z or +08:00) stripped (if taken from MediaCreateDate)
#   - timestamp_source: The Exif field name used (e.g. PhotoTakenTime, DateTimeOriginal, etc.)
#
# Example usage:
#   local timestamp timestamp_source
#
#   get_best_available_timestamp "IMG_4999.HEIC.MOV" \
#     timestamp \
#     timestamp_source
# ====================================================================================================

get_best_available_timestamp() {
  local media_file="$1"
  local -n ts="$2"
  local -n ts_source="$3"

  fid=$(get_media_file_id "$media_file")

  # If fid exists, this function is being called from analyze_media_file.
  # We should already have the photo taken time cached if the meta file exists.
  if [[ -n "$fid" && -n "${file_takeout_photo_taken_time[$fid]}" ]]; then
      ts=$(normalize_timestamp "${file_takeout_photo_taken_time[$fid]}")
      ts_source="PhotoTakenTime"
      return 0
  else
    # If fid is not available, this function is being called directly.
    # Try to locate takeout metadata file and extract photo taken time.
    local takeout_meta_file photo_taken_time
    if locate_takeout_meta_file "$media_file" takeout_meta_file && \
       extract_takeout_metadata "$takeout_meta_file" photo_taken_time && \
       [[ -n "$photo_taken_time" ]]; then
      ts=$(normalize_timestamp "$photo_taken_time")
      ts_source="PhotoTakenTime"
      return 0
    fi
  fi

  # Extract timestamps from exif metadata
  local datetime_original \
        create_date \
        track_create_date \
        media_create_date \
        file_create_date \
        file_modify_date

  # If fid exists, use already extracted EXIF data from global arrays
  if [[ -n "$fid" ]]; then
    datetime_original="${file_exif_date_time_original[$fid]:-}"
    create_date="${file_exif_create_date[$fid]:-}"
    track_create_date="${file_exif_track_create_date[$fid]:-}"
    media_create_date="${file_exif_media_create_date[$fid]:-}"
    file_create_date="${file_create_date[$fid]:-}"
    file_modify_date="${file_modify_date[$fid]:-}"
  else
    # Extract from EXIF if fid is not available
    extract_exif_to_vars "$media_file" \
      "DateTimeOriginal" \
      "CreateDate" \
      "TrackCreateDate" \
      "MediaCreateDate" \
      "FileCreateDate" \
      "FileModifyDate" \
      -- \
      datetime_original \
      create_date \
      track_create_date \
      media_create_date \
      file_create_date \
      file_modify_date
  fi

  if [[ -n "$datetime_original" ]]; then
    ts=$(normalize_timestamp "$datetime_original")
    ts_source="DateTimeOriginal"
  elif [[ -n "$create_date" ]]; then
    ts=$(normalize_timestamp "$create_date")
    ts_source="CreateDate"
  elif [[ -n "$track_create_date" ]]; then
    ts=$(normalize_timestamp "$track_create_date")
    ts_source="TrackCreateDate"
  elif [[ -n "$media_create_date" ]]; then
    ts=$(normalize_timestamp "$media_create_date")
    ts_source="MediaCreateDate"
  elif [[ -n "$file_create_date" ]]; then
    ts=$(normalize_timestamp "$file_create_date")
    ts_source="FileCreateDate"
  elif [[ -n "$file_modify_date" ]]; then
    ts=$(normalize_timestamp "$file_modify_date")
    ts_source="FileModifyDate"
  fi
}

# ====================================================================================================
# normalize_timestamp <raw_timestamp>
#
# Normalizes a timestamp string to Exif timestamp format with consistent millisecond precision.
#
# Transformation rules:
#   - UNIX epoch (10+ digits) → "YYYY:MM:DD HH:MM:SS.000" (UTC conversion)
#   - Exif timestamp format   → Ensures ".sss" milliseconds are present
#   - Timezone removal        → Strips "Z" suffix and "+/-HH:MM" offsets
#   - Invalid input           → Returns empty string
#
# Arguments:
#   $1: raw_timestamp → Raw timestamp string to normalize
#
# Output:
#   Normalized timestamp in "YYYY:MM:DD HH:MM:SS.sss" format, or empty string if invalid
#
# Example transformations:
#   - UNIX epoch:
#       1504360420                  → "2017:09:02 07:13:40.000"
#   - Exif timestamp with timezone:
#       "2017:09:02 07:13:40Z"      → "2017:09:02 07:13:40.000"
#   - Exif timestamp with offset:
#       "2017:09:02 07:13:40+08:00" → "2017:09:02 07:13:40.000"
#   - Already normalized:
#       "2017:09:02 07:13:40.123"   → "2017:09:02 07:13:40.123"
#
# Usage:
#   normalized=$(normalize_timestamp "$raw_timestamp")
# ====================================================================================================

normalize_timestamp() {
  local raw="$1"
  local clean

  # If it's a Unix timestamp (all digits, 10+ chars), convert to Exif timestamp format
  if [[ "$raw" =~ ^[0-9]{10,}$ ]]; then
    # Use date to convert to UTC, then format as YYYY:MM:DD HH:MM:SS.000
    if date -u -r "$raw" "+%Y:%m:%d %H:%M:%S.000" &>/dev/null; then
      date -u -r "$raw" "+%Y:%m:%d %H:%M:%S.000"
    else
      # BSD/macOS fallback
      date -u -jf %s "$raw" "+%Y:%m:%d %H:%M:%S.000" 2>/dev/null
    fi
    return
  fi

  clean="${raw%%[+-]??:??}" # strip timezone like +08:00
  clean="${clean%Z}"        # strip trailing Z

  if [[ "$clean" =~ ([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\.([0-9]+) ]]; then
    printf "%s.%03d" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]:0:3}"
  elif [[ "$clean" =~ ([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
    printf "%s.000" "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}
