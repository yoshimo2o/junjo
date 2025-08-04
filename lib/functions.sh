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
# confirm <message>
#
# Prompts the user for confirmation with a yes/no question.
# Returns 0 (true) if user confirms with 'y' or 'yes', 1 (false) otherwise.
#
# Parameters:
#   message - The confirmation message to display
#
# Returns:
#   0 if user confirms (y/yes), 1 if user declines (n/no) or invalid input
#
# Example:
#   if confirm "Do you want to continue?"; then
#     echo "User confirmed"
#   else
#     echo "User declined"
#   fi
# ====================================================================================================
confirm() {
  local message="$1"
  local response

  echo -n "$message [y/N]: "
  read -r response

  case "$response" in
    [yY]|[yY][eE][sS])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
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