# ========================================================================================================================
# locate_takeout_meta_file <media_file>
#                          <&meta_file>
#                          <&meta_file_name>
#                          <&meta_file_match_strategy>
#
# Given a media file, find the matching Google Takeout metadata file using known filename conventions.
#
# Match strategies (in order):
#   1. direct        → filename.supplemental-metadata.json
#   2. truncation    → truncated(filename + ".supplemental-metadata") + ".json"
#   3. duplication   → filename.supplemental-metadata(n).json
#
# Parameters:
#   1. media_file                → Path to the media file (e.g., "./IMG_5140(1).JPG")
#   2. &meta_file                → Reference to variable for JSON file path
#   3. &meta_file_name           → Reference to variable for JSON file name
#   4. &meta_file_match_strategy → Reference to variable for match strategy
#
# Returns:
#   0 if a match is found, 1 if no match found
#
# Example usage:
#   local takeout_meta_file takeout_meta_file_name takeout_meta_file_match_strategy
#
#   if locate_takeout_meta_file "$media_file" \
#        takeout_meta_file \
#        takeout_meta_file_name \
#        takeout_meta_file_match_strategy; then
#     echo "Found: $takeout_meta_file using $takeout_meta_file_match_strategy strategy"
#   else
#     echo "No Google Takeout metadata file found for $media_file"
#   fi
# ========================================================================================================================

locate_takeout_meta_file() {
  local media_file="$1"
  local -n meta_file="$2"
  local -n meta_file_name="$3"
  local -n meta_file_match_strategy="$4"

  local media_file_name="$(basename "$media_file")"
  local media_file_dir="$(dirname "$media_file")"

  local file=""
  local file_name=""
  local match_strategy=""

  # ---------------------------------------------------------
  # Strategy 1: Direct match
  #
  # Examples:
  #   IMG_9999.JPG
  #     → IMG_9999.JPG.supplemental-metadata.json
  #   FOOBAR (001).jpg
  #     → FOOBAR (001).jpg.supplemental-metadata.json
  #   FOO BAR (1).jpg
  #     → FOO BAR (1).jpg.supplemental-metadata.json
  # ---------------------------------------------------------
  file_name="${media_file_name}.supplemental-metadata.json"
  file="$media_file_dir/$file_name"
  if [[ -f "$file" ]]; then
    match_strategy="direct"
    meta_file="$file"
    meta_file_name="$file_name"
    meta_file_match_strategy="$match_strategy"
    return 0
  fi

  # ---------------------------------------------------------
  # Strategy 2: Truncation match
  #
  # Google appears to:
  #   1. Take "file_name + .supplemental-metadata"
  #   2. Truncate to 45 characters
  #   3. Append ".json"
  #
  # Examples:
  #   IMG_20250801_120808_LongEventTitleAtMuseumPalace.jpg
  #     → IMG_20250801_120808_LongEventTitleAtMuseumPa.json
  #
  #   ScreenRecording_20250801_120808_SampleApp.mp4
  #     → ScreenRecording_20250801_120808_SampleApp.supple.json
  #
  #   0d7b086cdcb68a4b6279fabaa0928e90.jpg
  #     → 0d7b086cdcb68a4b6279fabaa0928e90.jpg.supplemen.json
  # ---------------------------------------------------------
  local json_suffix=".json"
  local max_len=50
  local max_prefix_len=$(( max_len - ${#json_suffix} + 1))
  local truncation_prefix="${media_file_name}.supplemental-metadata"
  local truncated_prefix="${truncation_prefix:0:max_prefix_len}"
  file_name="${truncated_prefix}${json_suffix}"
  file="$media_file_dir/$file_name"

  if [[ -f "$file" ]]; then
    match_strategy="truncation"
    meta_file="$file"
    meta_file_name="$file_name"
    meta_file_match_strategy="$match_strategy"
    return 0
  fi

  # ---------------------------------------------------------
  # Strategy 3: Duplication match
  #
  # Matches files like:
  #   IMG_9999(1).JPG
  #     → IMG_9999.JPG.supplemental-metadata(1).json
  #
  #   IMG_20250801_120808(2).jpg
  #     → IMG_20250801_120808.jpg.supplemental-metadata(2).json
  # ---------------------------------------------------------
  local duplicate_pattern='^(.*)\(([0-9]+)\)\.([^.]+)$'
  if [[ "$media_file_name" =~ $duplicate_pattern ]]; then
    local base_part="${BASH_REMATCH[1]}"
    local number_suffix="${BASH_REMATCH[2]}"
    local extension=".${BASH_REMATCH[3]}"

    if [[ "$number_suffix" =~ ^[0-9]+$ ]]; then
      local original_base="${base_part}${extension}"
      local dup_prefix="${original_base}.supplemental-metadata(${number_suffix})"
      file_name="${dup_prefix}.json"

      if (( ${#file_name} > max_len )); then
        local truncated_dup_prefix="${file_name:0:max_prefix_len}"
        file_name="${truncated_dup_prefix}${json_suffix}"
      fi

      file="$media_file_dir/$file_name"
      if [[ -f "$file" ]]; then
        match_strategy="duplication"
        meta_file="$file"
        meta_file_name="$file_name"
        meta_file_match_strategy="$match_strategy"
        return 0
      fi
    fi
  fi

  return 1
}
