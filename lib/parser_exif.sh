# ====================================================================================================
# extract_exif_metadata <media_file> \
#                       <&cid> \
#                       <&device_make> \
#                       <&device_model> \
#                       <&lens_make> \
#                       <&lens_model> \
#                       <&image_width> \
#                       <&image_height> \
#                       <&image_size> \
#                       <&date_time_original> \
#                       <&create_date> \
#                       <&track_create_date> \
#                       <&media_create_date> \
#                       <&creator_tool> \
#                       <&user_comment> \
#                       <&file_create_date> \
#                       <&file_modify_date>
#
# Extracts useful EXIF metadata from a media file for analysis and processing.
#
# Arguments:
#   $1: Path to the media file
#   $2-16: Variable names to store results (by reference)
#
# Output values:
#   cid                 ContentIdentifier to determine if this is a Live Photo or Live Video
#   device_make         Camera/device make, e.g. Apple, Sony
#   device_model        Camera/device model, e.g. iPhone 7 Plus, XQ-DQ54
#   lens_make           Lens manufacturer, e.g. Apple
#   lens_model          Lens model, e.g. iPhone 7 Plus back dual camera 3.99mm f/1.8
#   image_width         Image width in pixels
#   image_height        Image height in pixels
#   image_size          Image size as "WIDTHxHEIGHT"
#   date_time_original  Original date/time when photo was taken
#   create_date         Creation date/time
#   track_create_date   Track creation date/time (for videos)
#   media_create_date   Media creation date/time
#   user_comment        User comment field
#   file_create_date    File creation date/time
#   file_modify_date    File modification date/time
#
# Example usage:
#   local cid \
#         device_make \
#         device_model \
#         lens_make \
#         lens_model \
#         image_width \
#         image_height \
#         image_size \
#         date_time_original \
#         create_date \
#         track_create_date \
#         media_create_date \
#         creator_tool \
#         user_comment \
#         file_create_date \
#         file_modify_date
#   extract_exif_metadata "IMG_4999.HEIC" \
#     cid \
#     device_make \
#     device_model \
#     lens_make \
#     lens_model \
#     image_width \
#     image_height \
#     image_size \
#     date_time_original \
#     create_date \
#     track_create_date \
#     media_create_date \
#     creator_tool \
#     user_comment \
#     file_create_date \
#     file_modify_date
# ====================================================================================================

extract_exif_metadata() {
  local media_file="$1"
  local -n cid_ref="$2"
  local -n device_make_ref="$3"
  local -n device_model_ref="$4"
  local -n lens_make_ref="$5"
  local -n lens_model_ref="$6"
  local -n image_width_ref="$7"
  local -n image_height_ref="$8"
  local -n image_size_ref="$9"
  local -n date_time_original_ref="${10}"
  local -n create_date_ref="${11}"
  local -n track_create_date_ref="${12}"
  local -n media_create_date_ref="${13}"
  local -n creator_tool_ref="${14}"
  local -n user_comment_ref="${15}"
  local -n file_create_date_ref="${16}"
  local -n file_modify_date_ref="${17}"

  local _cid \
        _device_make \
        _device_model \
        _lens_make \
        _lens_model \
        _image_width \
        _image_height \
        _image_size \
        _date_time_original \
        _create_date \
        _track_create_date \
        _media_create_date \
        _creator_tool \
        _user_comment \
        _file_create_date \
        _file_modify_date

  extract_exif_to_vars "$media_file" \
    "ContentIdentifier" \
    "Make" \
    "Model" \
    "LensMake" \
    "LensModel" \
    "ImageWidth" \
    "ImageHeight" \
    "ImageSize" \
    "DateTimeOriginal" \
    "CreateDate" \
    "TrackCreateDate" \
    "MediaCreateDate" \
    "CreatorTool" \
    "UserComment" \
    "FileCreateDate" \
    "FileModifyDate" \
    -- \
    _cid \
    _device_make \
    _device_model \
    _lens_make \
    _lens_model \
    _image_width \
    _image_height \
    _image_size \
    _date_time_original \
    _create_date \
    _track_create_date \
    _media_create_date \
    _creator_tool \
    _user_comment \
    _file_create_date \
    _file_modify_date \

  # Set return values via nameref
  cid_ref="$_cid"
  device_make_ref="$_device_make"
  device_model_ref="$_device_model"
  lens_make_ref="$_lens_make"
  lens_model_ref="$_lens_model"
  image_width_ref="$_image_width"
  image_height_ref="$_image_height"
  image_size_ref="$_image_size"
  date_time_original_ref="$_date_time_original"
  create_date_ref="$_create_date"
  track_create_date_ref="$_track_create_date"
  media_create_date_ref="$_media_create_date"
  creator_tool_ref="$_creator_tool"
  user_comment_ref="$_user_comment"
  file_create_date_ref="$_file_create_date"
  file_modify_date_ref="$_file_modify_date"
}

# ====================================================================================================
# extract_exif_to_vars <media_file> <field1> <field2> ... -- <var1> <var2> ...
#
# Extracts EXIF fields from a media file and assigns values directly to named variables.
# Uses "--" to separate field names from variable names.
#
# Arguments:
#   $1: Path to the media file
#   $2-N: EXIF field names (without leading "-")
#   --: Separator
#   N+1-M: Variable names to assign to (by reference)
#
# Example usage:
#   local cid make model lens
#   extract_exif_to_vars "image.jpg" \
#     "ContentIdentifier" "Make" "Model" "LensModel" -- \
#     cid make model lens
# ====================================================================================================

extract_exif_to_vars() {
  local media_file="$1"
  shift

  local fields=()
  local vars=()
  local parsing_fields=true

  # Parse arguments: fields before --, vars after --
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
      parsing_fields=false
      shift
      continue
    fi

    if [[ "$parsing_fields" == true ]]; then
      fields+=("$1")
    else
      vars+=("$1")
    fi
    shift
  done

  # Build the exiftool command with all field names
  local cmd_args=("-s3" "-f")
  for field in "${fields[@]}"; do
    cmd_args+=("-$field")
  done
  cmd_args+=("$media_file")

  # Execute exiftool and read results into array
  local exif_values
  mapfile -t exif_values < <(exiftool "${cmd_args[@]}" 2>/dev/null)

  # Assign values to variables using nameref
  local i
  for ((i=0; i<${#vars[@]}; i++)); do
    if [[ i -lt ${#exif_values[@]} ]]; then
      local value="${exif_values[i]:-}"
      [[ "$value" == "-" ]] && value=""
      local -n var_ref="${vars[i]}"
      var_ref="$value"
    fi
  done
}