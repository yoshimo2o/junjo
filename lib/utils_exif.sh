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
