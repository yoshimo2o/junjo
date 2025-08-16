# ====================================================================================================
# get_best_available_timestamp <media_file>
#                              <&timestamp>
#                              <&timestamp_epoch>
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
#   $2: timestamp          → Variable to store the EXIF timestamp
#   $3: timestamp_epoch    → Variable to store the Epoch timestamp (ms)
#   $4: timestamp_source   → Variable to store the timestamp source field name
#
# Output values:
#   - timestamp: EXIF timestamp in "YYYY:MM:DD HH:MM:SS.sss" format
#   - timestamp_epoch: Epoch timestamp in milliseconds
#   - timestamp_source: The EXIF field name used (e.g. PhotoTakenTime, DateTimeOriginal, etc.)
#
# Example usage:
#   local ts ts_epoch ts_source
#   get_best_available_timestamp "IMG_4999.HEIC.MOV" ts ts_epoch ts_source
#   echo "EXIF timestamp: $ts"
#   echo "Epoch timestamp: $ts_epoch"
#   echo "Source: $ts_source"
# ====================================================================================================

get_best_available_timestamp() {
  local fid="$1"
  local -n timestamp_ref="$2"
  local -n timestamp_epoch_ref="$3"
  local -n timestamp_source_ref="$4"

  local photo_taken_time="${file_takeout_photo_taken_time["$fid"]:-}"
  local datetime_original="${file_exif_date_time_original["$fid"]:-}"
  local create_date="${file_exif_create_date["$fid"]:-}"
  local track_create_date="${file_exif_track_create_date["$fid"]:-}"
  local media_create_date="${file_exif_media_create_date["$fid"]:-}"
  local file_create_date="${file_create_date["$fid"]:-}"
  local file_modify_date="${file_modify_date["$fid"]:-}"

  if [[ -n "$photo_taken_time" ]]; then
    timestamp_ref="$photo_taken_time"
    timestamp_source_ref="PhotoTakenTime"
  elif [[ -n "$datetime_original" ]]; then
    timestamp_ref="$datetime_original"
    timestamp_source_ref="DateTimeOriginal"
  elif [[ -n "$create_date" ]]; then
    timestamp_ref="$create_date"
    timestamp_source_ref="CreateDate"
  elif [[ -n "$track_create_date" ]]; then
    timestamp_ref="$track_create_date"
    timestamp_source_ref="TrackCreateDate"
  elif [[ -n "$media_create_date" ]]; then
    timestamp_ref="$media_create_date"
    timestamp_source_ref="MediaCreateDate"
  elif [[ -n "$file_create_date" ]]; then
    timestamp_ref="$file_create_date"
    timestamp_source_ref="FileCreateDate"
  elif [[ -n "$file_modify_date" ]]; then
    timestamp_ref="$file_modify_date"
    timestamp_source_ref="FileModifyDate"
  fi

  # Normalize the selected timestamp
  timestamp_ref=$(to_exif_ts "$timestamp_ref")
  timestamp_epoch_ref=$(exif_ts_to_epoch_ms "$timestamp_ref")
}

# ====================================================================================================
# to_exif_ts <raw_timestamp>
#
# Converts a timestamp string to EXIF timestamp format with consistent millisecond precision.
# If a timezone is present, adjusts the time to UTC before formatting.
#
# Transformation rules:
#   - Epoch timestamp (10+ digits) → "YYYY:MM:DD HH:MM:SS.000" (UTC conversion)
#   - EXIF timestamp format        → Ensures ".sss" milliseconds are present
#   - Timezone present             → Converts to UTC before formatting
#   - Timezone removal             → Strips "Z" suffix and "+/-HH:MM" offsets
#   - Invalid input                → Returns empty string
#
# Arguments:
#   $1: raw_timestamp → Timestamp string to convert
#
# Output:
#   EXIF timestamp in "YYYY:MM:DD HH:MM:SS.sss" format, or empty string if invalid
#
# Example transformations:
#   - Epoch timestamp:
#       1504360420                  → "2017:09:02 07:13:40.000"
#   - EXIF timestamp with timezone:
#       "2017:09:02 07:13:40Z"      → "2017:09:02 07:13:40.000"
#       "2017:09:02 07:13:40+08:00" → "2017:09:01 23:13:40.000"   # UTC adjusted
#       "2017:09:02 07:13:40-05:00" → "2017:09:02 12:13:40.000"   # UTC adjusted
#   - Already EXIF timestamp:
#       "2017:09:02 07:13:40.123"   → "2017:09:02 07:13:40.123"
#
# Example usage:
#   ts_exif=$(to_exif_ts "1504360420")
#   echo "EXIF timestamp: $ts_exif"   # returns: 2017:09:02 07:13:40.000
#   ts_exif=$(to_exif_ts "2017:09:02 07:13:40+08:00")
#   echo "EXIF timestamp: $ts_exif"   # returns: 2017:09:01 23:13:40.000
#   ts_exif=$(to_exif_ts "2017:09:02 07:13:40.123")
#   echo "EXIF timestamp: $ts_exif"   # returns: 2017:09:02 07:13:40.123
# ====================================================================================================
to_exif_ts() {
  local raw="$1"
  local clean

  # If it's an Epoch timestamp (all digits, 10+ chars), convert to EXIF timestamp format
  if [[ "$raw" =~ ^[0-9]{10,}$ ]]; then
    # Use gdate to convert to UTC, then format as YYYY:MM:DD HH:MM:SS.000
    if gdate -u -d "@$raw" "+%Y:%m:%d %H:%M:%S.000" &>/dev/null; then
      gdate -u -d "@$raw" "+%Y:%m:%d %H:%M:%S.000"
    else
      printf ""
    fi
    return
  fi

  # If timestamp has timezone info, use gdate to convert to UTC
  if [[ "$raw" =~ ^([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?)(Z|[+-][0-9]{2}:[0-9]{2})$ ]]; then
    local ts_part="${BASH_REMATCH[1]}"
    local tz_part="${BASH_REMATCH[3]}"
    # Replace ':' with '-' in date for GNU date compatibility
    local ts_for_date="${ts_part/:/-}"
    ts_for_date="${ts_for_date/:/-}"
    ts_for_date="${ts_for_date/ /T}"
    # Use gdate to convert to UTC
    local utc_ts
    utc_ts=$(gdate -u -d "${ts_for_date}${tz_part}" "+%Y:%m:%d %H:%M:%S" 2>/dev/null)
    if [[ -n "$utc_ts" ]]; then
      ts_part="$utc_ts"
    fi
    clean="$ts_part"
  else
    clean="${raw%%[+-]??:??}" # strip timezone like +08:00
    clean="${clean%Z}"        # strip trailing Z
  fi

  if [[ "$clean" =~ ([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\.([0-9]+) ]]; then
    printf "%s.%03d" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]:0:3}"
  elif [[ "$clean" =~ ([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
    printf "%s.000" "${BASH_REMATCH[1]}"
  else
    printf ""
  fi
}

# ====================================================================================================
# exif_ts_to_epoch_ms <exif_timestamp>
#
# Converts EXIF timestamp ("YYYY:MM:DD HH:MM:SS.sss") to Epoch timestamp in milliseconds.
#
# Arguments:
#   $1: exif_timestamp → Timestamp string in EXIF format (with or without milliseconds)
#
# Output:
#   Epoch timestamp in milliseconds (as integer)
#
# Example usage:
#   epoch_ms=$(exif_ts_to_epoch_ms "$exif_ts")
# ====================================================================================================
exif_ts_to_epoch_ms() {
  local ts="$1"
  local ts_sec_part ts_ms_part ts_epoch_sec
  if [[ "$ts" =~ ^([0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\.([0-9]{1,3})$ ]]; then
    ts_sec_part="${BASH_REMATCH[1]}"
    ts_ms_part="${BASH_REMATCH[2]}00"
    ts_ms_part="${ts_ms_part:0:3}"
  else
    ts_sec_part="$ts"
    ts_ms_part="000"
  fi
  ts_epoch_sec=$(date -u -d "$ts_sec_part" +%s 2>/dev/null || date -u -j -f "%Y:%m:%d %H:%M:%S" "$ts_sec_part" +%s 2>/dev/null)
  printf "%d" $((10#$ts_epoch_sec * 1000 + 10#$ts_ms_part))
}