# ====================================================================================================
# encode_base64url <string>
#
# Encodes input as base64url (RFC 4648) for safe use as keys, filenames, etc.
# Removes padding for compactness.
# Example: encode_base64url "foo/bar"
# ====================================================================================================
encode_base64url() {
  # Usage: encode_base64url <string>
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: use 'tr' with bracket expressions
    printf '%s' "$1" | base64 | tr '[+/]' '[-_]'
  else
    # Linux: use 'tr' with literal characters
    printf '%s' "$1" | base64 | tr '+/' '-_'
  fi | tr -d '='
}

# ====================================================================================================
# decode_base64url <base64url_string>
#
# Decodes a base64url-encoded string (RFC 4648, no padding).
# Example: decode_base64url "Zm9vLWJhcg"
# ====================================================================================================
decode_base64url() {
  local input="$1"
  # Add padding if needed
  local pad=$(( (4 - ${#input} % 4) % 4 ))
  input="${input}$(printf '=%.0s' $(seq 1 $pad))"
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: use 'tr' with bracket expressions
    echo "$input" | tr '[-_]' '[+/]' | base64 -d
  else
    # Linux: use 'tr' with literal characters
    echo "$input" | tr '-_' '+/' | base64 -d
  fi
}

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

  if [[ $JUNJO_INTERACTIVE -ne 1 ]]; then
    return 0
  fi

  while true; do
    echo -n "$message [y/n]: "
    read -r response
    case "$response" in
      [yY])
        echo
        return 0
        ;;
      [nN])
        return 1
        ;;
    esac
  done
}

# ====================================================================================================
# press_any_key
# Shows 'Press any key to continue...' and waits for a single keypress.
# ====================================================================================================
press_any_key() {
  if [[ $JUNJO_INTERACTIVE -ne 1 ]]; then
    return 0
  fi
  echo -n "Press any key to continue... "
  # Reads one character, no Enter required
  read -n 1 -s
  echo
}

# ====================================================================================================
# strip_ansi <text>
# Removes ANSI escape color codes from the input text for accurate width calculations.
# Example: strip_ansi $colored_text
# ====================================================================================================
strip_ansi() {
  echo -n "$1" | sed -E 's/\x1B\[[0-9;]*[mK]//g'
}

## ====================================================================================================
# draw_box <lines...>
# Draws a Unicode box around the provided lines, with optional color codes.
# Handles color codes for alignment by stripping them for width calculation.
# Example: draw_box "Line 1" "Line 2" "Line 3"
# ====================================================================================================
draw_box() {
  local lines=("$@")
  local maxlen=0
  local padding=2   # spaces on each side

  # find the longest line (without color codes)
  for line in "${lines[@]}"; do
    local plain_line
    plain_line=$(strip_ansi "$line")
    (( ${#plain_line} > maxlen )) && maxlen=${#plain_line}
  done

  local width=$((maxlen + padding * 2))

  # top border
  printf "┌"; printf '─%.0s' $(seq 1 $width); echo "┐"

  # content
  for line in "${lines[@]}"; do
    local colored_line
    colored_line=$(color_by_colon "$line")
    local plain_line
    plain_line=$(strip_ansi "$line")
    # Print left border and left padding
    printf "│%*s" $padding ""
    # Print colored line using echo -ne, then pad to maxlen
    echo -ne "$colored_line"
    local pad_len=$((maxlen - ${#plain_line}))
    printf "%*s" $pad_len ""
    # Print right padding and right border
    printf "%*s│\n" $padding ""
  done

  # bottom border
  printf "└"; printf '─%.0s' $(seq 1 $width); echo "┘"
}


# ====================================================================================================
# confirm_box <lines...>
# Shows a box with all lines except the last, then prompts for confirmation with the last line.
# Returns 0 if confirmed, 1 otherwise.
# ====================================================================================================
confirm_box() {
  local lines=("$@")
  local n=${#lines[@]}
  if (( n < 2 )); then
    echo "confirm_box requires at least two arguments: box lines and a prompt." >&2
    return 1
  fi
  local box_lines=("${lines[@]:0:n-1}")
  local prompt="${lines[n-1]}"
  draw_box "${box_lines[@]}"
  confirm "$prompt"
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

# ====================================================================================================
# pad <text> <char> <count>
# Pads <text> on the left with <char> until the total length is <count>.
# If <text> is longer than <count>, returns <text> unchanged.
# Example: pad 7 "0" 3 → "007"
# ====================================================================================================
pad() {
  local text="$1"
  local char="$2"
  local count="$3"
  local len=${#text}
  if (( len >= count )); then
    printf "%s" "$text"
    return
  fi
  local pad_len=$((count - len))
  local pad_str=""
  for ((i=0; i<pad_len; i++)); do
    pad_str+="$char"
  done
  printf "%s%s" "$pad_str" "$text"
}

# ====================================================================================================
# progress <current> <total> [type]
# If type is "/" or omitted, returns "current/total" (no padding)
# If type is "%", returns percentage with two decimals, e.g. "12.34%"
# ====================================================================================================
progress() {
  local current="$1"
  local total="$2"
  local type="${3:-/}"
  if [[ "$type" == "%" ]]; then
    if (( total == 0 )); then
      printf "0.00%%"
      return
    fi
    local percent
    percent=$(awk "BEGIN { printf \"%.2f\", ($current/$total)*100 }")
    printf "%s%%" "$percent"
  else
    local width=${#total}
    local padded_current
    padded_current=$(pad "$current" " " "$width")
    printf "%s/%s" "$padded_current" "$total"
  fi
}

# ====================================================================================================
# epoch_ms_date_fmt <epoch_ms> <format>
# Converts epoch in milliseconds to formatted date string (cross-platform).
# Parameters:
#   epoch_ms - Epoch time in milliseconds
#   format   - Date format string for 'date' command
# Returns:
#   Formatted date string
# Example:
#   epoch_ms_date_fmt 1692182400000 "%Y-%m-%d %H:%M:%S"
# ====================================================================================================
epoch_ms_date_fmt() {
  local epoch_ms="$1"
  local fmt="$2"
  local epoch_s=$((epoch_ms / 1000))
  if [[ "$(uname)" == "Darwin" ]]; then
    date -r "$epoch_s" "$fmt"
  else
    date -d @"$epoch_s" "$fmt"
  fi
}