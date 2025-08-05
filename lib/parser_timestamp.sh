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
  local fid="$1"
  local -n ts="$2"
  local -n ts_epoch="$3"
  local -n ts_source="$4"

  local photo_taken_time="${file_takeout_photo_taken_time["$fid"]:-}"
  local datetime_original="${file_exif_date_time_original["$fid"]:-}"
  local create_date="${file_exif_create_date["$fid"]:-}"
  local track_create_date="${file_exif_track_create_date["$fid"]:-}"
  local media_create_date="${file_exif_media_create_date["$fid"]:-}"
  local file_create_date="${file_create_date["$fid"]:-}"
  local file_modify_date="${file_modify_date["$fid"]:-}"

  if [[ -n "$photo_taken_time" ]]; then
    ts="$photo_taken_time"
    ts_source="PhotoTakenTime"
  elif [[ -n "$datetime_original" ]]; then
    ts="$datetime_original"
    ts_source="DateTimeOriginal"
  elif [[ -n "$create_date" ]]; then
    ts="$create_date"
    ts_source="CreateDate"
  elif [[ -n "$track_create_date" ]]; then
    ts="$track_create_date"
    ts_source="TrackCreateDate"
  elif [[ -n "$media_create_date" ]]; then
    ts="$media_create_date"
    ts_source="MediaCreateDate"
  elif [[ -n "$file_create_date" ]]; then
    ts="$file_create_date"
    ts_source="FileCreateDate"
  elif [[ -n "$file_modify_date" ]]; then
    ts="$file_modify_date"
    ts_source="FileModifyDate"
  fi

  # Normalize the selected timestamp
  ts=$(normalize_timestamp "$ts")
  ts_epoch=$(exif_ts_to_epoch_ms "$ts")
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

# Converts a normalized Exif timestamp (YYYY:MM:DD HH:MM:SS.sss) to epoch milliseconds
# Usage: ts_epoch_with_ms=$(exif_ts_to_epoch_ms "$ts")
exif_ts_to_epoch_ms() {
  local ts="$1"
  local ts_sec_part ts_ms_part ts_epoch_sec
  if [[ "$ts" =~ ^([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\.([0-9]{1,3})$ ]]; then
    ts_sec_part="${BASH_REMATCH[1]}"
    # Efficient right-pad ms to 3 digits
    ts_ms_part="${BASH_REMATCH[2]}00"
    ts_ms_part="${ts_ms_part:0:3}"
  else
    ts_sec_part="$ts"
    ts_ms_part="000"
  fi
  ts_epoch_sec=$(date -u -d "$ts_sec_part" +%s 2>/dev/null || date -u -j -f "%Y:%m:%d %H:%M:%S" "$ts_sec_part" +%s 2>/dev/null)
  printf "%d" $((10#$ts_epoch_sec * 1000 + 10#$ts_ms_part))
}