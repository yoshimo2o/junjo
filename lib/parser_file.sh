
# ====================================================================================================
# get_media_file_id <media_file>
#
# Generates a unique file ID for a media file path using Base64 encoding.
# This provides collision-free IDs suitable for use as associative array keys.
#
# Parameters:
#   1. media_file  → The media file path to generate an ID for
#
# Return:
#   The Base64-encoded file ID
#
# Example usage:
#   file_id="$(get_media_file_id "/path/to/IMG_1234.jpg")"
#   echo "File ID: $file_id"
# ====================================================================================================

get_media_file_id() {
  local media_file="$1"
  printf '%s\n' "$(encode_base64url "$media_file")"
}

# ====================================================================================================
# get_media_file_path_components <media_file>
#                                <&media_file_dir>
#                                <&media_file_name>
#                                <&media_file_stem>
#                                <&media_file_root_stem>
#                                <&media_file_ext>
#                                <&media_file_compound_ext>
#                                <&media_file_dupe_marker>
#
# Splits a media file path into components:
#   1. media_file_dir          → Directory with trailing slash if not empty, e.g.
#                                  "./" or "rel/path/" or "/abs/path/"
#   2. media_file_name         → Basename, e.g. "IMG_9999(1).HEIC.MOV"
#   3. media_file_stem         → Filename without extension, e.g. "IMG_9999(1)"
#   6. media_file_root_stem    → Root stem without duplicate markers , e.g.
#                                  "IMG_9999(1)" -> "IMG_9999"
#   5. media_file_ext          → Base extension with leading dot, e.g. ".MOV"
#   4. media_file_compound_ext → Compound extension with leading dot, e.g. ".HEIC.MOV"
#   7. media_file_dupe_marker  → Duplicate marker if exists, e.g. "1"
#
# The original case of the parts are preserved.
#
# Example scenarios:
#   - Simple extension:
#       "IMG_0001.JPG"        → media_file_stem="IMG_0001"
#                               media_file_root_stem="IMG_0001"
#                               media_file_ext=".JPG"
#                               media_file_compound_ext=".JPG"
#   - Compound extension:
#       "IMG_9999.HEIC.MOV"   → media_file_stem="IMG_9999"
#                               media_file_root_stem="IMG_9999"
#                               media_file_ext=".MOV"
#                               media_file_compound_ext=".HEIC.MOV"
#   - Duplicate markers:
#       "IMG_1234(1).JPG.MP4" → media_file_stem="IMG_1234(1)"
#                               media_file_root_stem="IMG_1234"
#                               media_file_ext=".JPG.MP4"
#                               media_file_compound_ext=".MP4"
#
# Example usage:
#   local file_dir \
#         file_name \
#         file_stem \
#         file_root_stem \
#         file_ext \
#         file_compound_ext \
#         file_dupe_marker
#
#   get_media_file_parts "IMG_4999.HEIC.MOV" \
#     file_dir \
#     file_name \
#     file_stem \
#     file_root_stem \
#     file_ext \
#     file_compound_ext \
#     file_dupe_marker
#
#   printf "Dir: %s, Name: %s, Stem: %s, Root: %s, Ext: %s, Compound: %s, Dupe: %s\n" \
#     "$file_dir" \
#     "$file_name" \
#     "$file_stem" \
#     "$file_root_stem" \
#     "$file_ext" \
#     "$file_compound_ext" \
#     "$file_dupe_marker"
# ====================================================================================================

get_media_file_path_components() {
  local media_file="$1"
  local -n media_file_dir_ref="$2"
  local -n media_file_name_ref="$3"
  local -n media_file_stem_ref="$4"
  local -n media_file_root_stem_ref="$5"
  local -n media_file_ext_ref="$6"
  local -n media_file_compound_ext_ref="$7"
  local -n media_file_dupe_marker_ref="$8"

  # Local working variables
  local media_file_dir \
        media_file_name \
        media_file_stem \
        media_file_root_stem \
        media_file_ext \
        media_file_compound_ext \
        media_file_dupe_marker

  # Get media file name and directory
  media_file_name=$(basename "$media_file")
  media_file_dir=$(dirname "$media_file")

  # Normalize directory with trailing slash if not empty
  #   "IMG_1440.jpg"           → ""
  #   "./IMG_1440.jpg"         → "./"
  #   "./foo/IMG_1440.jpg"     → "./foo/"
  #   "rel/path/IMG_1440.jpg"  → "rel/path/"
  #   "/abs/path/IMG_1440.jpg" → "/abs/path/"
  if [[ "$media_file_dir" == "." ]]; then
    if [[ "$media_file" == ./* ]]; then
      media_file_dir="./"
    else
      media_file_dir=""
    fi
  elif [[ -n "$media_file_dir" ]]; then
    [[ "$media_file_dir" != */ ]] && media_file_dir="${media_file_dir}/"
  fi

  # Get file stem, extension, and compound extension
  local media_file_name_uc="${media_file_name^^}"

  for ext in "${KNOWN_COMPOUND_EXTS[@]}"; do
    if [[ "$media_file_name_uc" == *"${ext^^}" ]]; then
      local suffix_len=${#ext}
      media_file_compound_ext="${media_file_name: -$suffix_len}" # preserve original case
      media_file_stem="${media_file_name:0:${#media_file_name} - $suffix_len}"
      media_file_ext=".${media_file_compound_ext##*.}" # include leading dot
      break
    fi
  done

  if [[ -z "$media_file_compound_ext" ]]; then
    # Check if file has an extension (contains a dot and dot is not at the end)
    if [[ "$media_file_name" == *.* && "$media_file_name" != *. ]]; then
      media_file_ext=".${media_file_name##*.}" # include leading dot
      media_file_stem="${media_file_name%$media_file_ext}"
      media_file_compound_ext="$media_file_ext"
    else
      # File has no extension
      media_file_ext=""
      media_file_stem="$media_file_name"
      media_file_compound_ext=""
    fi
  fi

  # Extract root stem (without duplicate markers)
  # Only match non-zero-padded numbers like (1), (2), (10) but not (01), (009)
  media_file_root_stem=$(echo "$media_file_stem" | sed -E 's/ ?\(([1-9][0-9]*)\)//g')

  # Extract duplicate marker if present (non-zero-padded only)
  if [[ "$media_file_stem" =~ \(([1-9][0-9]*)\) ]]; then
    media_file_dupe_marker="${BASH_REMATCH[1]}"
  else
    media_file_dupe_marker=""
  fi

  # Assign local variables back to reference variables
  media_file_dir_ref="$media_file_dir"
  media_file_name_ref="$media_file_name"
  media_file_stem_ref="$media_file_stem"
  media_file_root_stem_ref="$media_file_root_stem"
  media_file_ext_ref="$media_file_ext"
  media_file_compound_ext_ref="$media_file_compound_ext"
  media_file_dupe_marker_ref="$media_file_dupe_marker"
}

# ====================================================================================================
# get_media_file_type <fid>
#
# Determines the media file type based on file extension and metadata.
#
# Parameters:
#   1. fid → File ID to analyze (must exist in global arrays)
#
# Return:
#   File type constant corresponding to the detected media type (see $file_types in globals.sh)
#
# Example usage:
#   file_type=$(get_media_file_type "$fid")
#   echo "File type: $file_type"
# ====================================================================================================

get_media_file_type() {
  local fid="$1"
  local -n file_type_ref="$2"

  # Get file extension by fid
  local file_ext="${file_src_ext[$fid]}"
  local cid="${file_exif_cid[$fid]:-}"
  local is_apple="${file_is_apple_media[$fid]:-0}"

  # Determine file type based on all the information collected above
  case "${file_ext,,}" in
    .jpg|.jpeg|.heic)
      if [[ -n "$cid" ]]; then
        file_type_ref=$FILE_TYPE_LIVE_PHOTO
        return 0
      elif [[ $is_apple -eq 1 ]]; then
        file_type_ref=$FILE_TYPE_APPLE_PHOTO
        return 0
      else
        file_type_ref=$FILE_TYPE_REGULAR_PHOTO
        return 0
      fi
      ;;
    .mov|.mp4|.mpg|.mpeg|.avi|.3gp|.wmv|.webm)
      if [[ -n "$cid" ]]; then
        file_type_ref=$FILE_TYPE_LIVE_VIDEO
        return 0
      elif [[ $is_apple -eq 1 ]]; then
        file_type_ref=$FILE_TYPE_APPLE_VIDEO
        return 0
      else
        file_type_ref=$FILE_TYPE_REGULAR_VIDEO
        return 0
      fi
      ;;
    .png)
      file_type_ref=$FILE_TYPE_REGULAR_IMAGE
      return 0
      ;;
    .gif|.webp)
      file_type_ref=$FILE_TYPE_REGULAR_IMAGE
      return 0
      ;;
    *)
      file_type_ref=$FILE_TYPE_UNKNOWN
      return 0
      # TODO: Handle screenshots
      # TODO: Handle downloaded images
      ;;
  esac
}