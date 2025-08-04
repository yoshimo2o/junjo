check_dependencies() {
  # Check for required dependencies
  if ((BASH_VERSINFO[0] < 4)); then
    log_error "Bash 4.0 or newer required."
    exit 1
  fi

  if ! command -v exiftool >/dev/null 2>&1; then
    log_error "exiftool is not installed. Please install exiftool to continue."
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is not installed. Please install jq to continue."
    exit 1
  fi
}

# ====================================================================================================
# wrap_text <text> <width> [indent]
#
# Wraps text at specified character width with optional indentation for continuation lines.
#
# Parameters:
#   text   - The text to wrap
#   width  - Maximum characters per line
#   indent - Optional number of spaces for continuation lines (default: 0)
#
# Returns:
#   Wrapped text with newlines and optional indentation
#
# Example:
#   wrap_text "This is a very long string that needs to be wrapped" 30 4
#   wrap_text "$fid" 30 6
#   wrap_text "$fid" 30
#
# ====================================================================================================
wrap_text() {
  local text="$1"
  local width="$2"
  local indent_count="${3:-0}"

  local indent=""
  if [[ $indent_count -gt 0 ]]; then
    printf -v indent "%*s" "$indent_count" ""
  fi

  local result=""
  local temp_text="$text"

  while [[ ${#temp_text} -gt $width ]]; do
    result+="${temp_text:0:$width}"$'\n'"$indent"
    temp_text="${temp_text:$width}"
  done
  result+="$temp_text"

  echo "$result"
}