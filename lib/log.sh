# ==============================================================================
# LOG
# Logging system with tree-structured output, timestamps and categorization.
# ==============================================================================#
#
# FEATURES:
# - Raw logging (no timestamp)
# - Timestamped logging with categories (main, scan, sort)
# - Tree-structured output with Unicode box-drawing characters
# - Automatic log file management and initialization
# - Configurable verbosity levels
#
# EXAMPLE USAGE:
#   # Initialize logging system
#   init_log
#
#   # Basic logging
#   log_raw "Starting application"
#   log "Processing files" "$MAIN_LOG"
#   log "Found 150 media files" "$SCAN_LOG"
#
#   # Tree-structured logging
#   log_tree_start "Processing: IMG_1234.jpg"
#     log_tree "Type: Apple Live Photo"
#     log_tree "Device: iPhone 13 Pro"
#     log_tree_start "EXIF Metadata"
#       log_tree "Date Original: 2023-07-15 14:30:22"
#       log_tree "Image Size: 4032x3024"
#     log_tree_end "Metadata complete"
#   log_tree_end "File processing complete"
#
# EXAMPLE OUTPUT:
#   [2025-08-04 14:30:15] Processing files
#   [2025-08-04 14:30:16] ├── Processing: IMG_1234.jpg
#   [2025-08-04 14:30:16] │   ├── Type: Apple Live Photo
#   [2025-08-04 14:30:16] │   ├── Device: iPhone 13 Pro
#   [2025-08-04 14:30:16] │   ├── EXIF Metadata
#   [2025-08-04 14:30:17] │   │   ├── Date Original: 2023-07-15 14:30:22
#   [2025-08-04 14:30:17] │   │   ├── Image Size: 4032x3024
#   [2025-08-04 14:30:17] │   │   └── Metadata complete
#   [2025-08-04 14:30:17] │   └── File processing complete
#
# LOG CATEGORIES:
#   MAIN_LOG="main"  - General application logging
#   SCAN_LOG="scan"  - Media file scanning operations
#   SORT_LOG="sort"  - File sorting and organization operations
#
# ==============================================================================

# Log categories
readonly MAIN_LOG=" MAIN"
readonly SCAN_LOG=" SCAN"
readonly PLAN_LOG=" PLAN"
readonly SORT_LOG=" SORT"
readonly DEBUG_LOG="DEBUG"
readonly ERROR_LOG="ERROR"
readonly ABORT_LOG="ABORT"

# Log file paths (to be set in init_log)
export JUNJO_LOG_FILE=""
export JUNJO_SCAN_LOG_FILE=""
export JUNJO_PLAN_LOG_FILE=""
export JUNJO_SORT_LOG_FILE=""

# Log tree
declare -i LOG_TREE_INDENT_LEVEL=0

# Initialize logging system
init_log() {
  # Set up runtime log file paths
  JUNJO_LOG_FILE="${JUNJO_LOG_DIR%/}/$JUNJO_LOG_FILE_NAME"
  JUNJO_SCAN_LOG_FILE="${JUNJO_LOG_DIR%/}/$JUNJO_SCAN_LOG_FILE_NAME"
  JUNJO_PLAN_LOG_FILE="${JUNJO_LOG_DIR%/}/$JUNJO_PLAN_LOG_FILE_NAME"
  JUNJO_SORT_LOG_FILE="${JUNJO_LOG_DIR%/}/$JUNJO_SORT_LOG_FILE_NAME"

  # Create log directory if it doesn't exist
  if [[ ! -d "$JUNJO_LOG_DIR" ]]; then
    mkdir -p "$JUNJO_LOG_DIR" || {
      echo "Error: Failed to create log directory: $JUNJO_LOG_DIR" >&2
      return 1
    }
  fi

  # Clear previous log files
  > "$JUNJO_LOG_FILE" || {
    echo "Error: Failed to initialize log file: $JUNJO_LOG_FILE" >&2
    return 1
  }

  > "$JUNJO_SCAN_LOG_FILE" || {
    echo "Error: Failed to initialize log file: $JUNJO_SCAN_LOG_FILE" >&2
    return 1
  }

  > "$JUNJO_PLAN_LOG_FILE" || {
    echo "Error: Failed to initialize log file: $JUNJO_PLAN_LOG_FILE" >&2
    return 1
  }

  > "$JUNJO_SORT_LOG_FILE" || {
    echo "Error: Failed to initialize log file: $JUNJO_SORT_LOG_FILE" >&2
    return 1
  }
}

# --------------------------------------------------------------------------
# Logging functions
# --------------------------------------------------------------------------

log() {
  local message="$1"
  local category="$2"
  local -i force_verbose="${3:-0}"
  local timestamp="$(generate_log_timestamp_prefix)"
  local log_file="$JUNJO_LOG_FILE" \
    color_primary \
    color_secondary
  local -i output_to_console=1
  local -i format_message=1
  local -i output_to_stderr=0

  # Different log behaviour for differnet log categories
  case "$category" in
    "$SCAN_LOG")
      log_file="$JUNJO_SCAN_LOG_FILE"
      color_primary="$COLOR_BOLD_BLUE"
      color_secondary="$COLOR_BRIGHT_BLUE"
      output_to_console=$(( JUNJO_LOG_VERBOSE == 1 ))
      ;;
    "$PLAN_LOG")
      log_file="$JUNJO_PLAN_LOG_FILE"
      color_primary="$COLOR_BOLD_YELLOW"
      color_secondary="$COLOR_BRIGHT_YELLOW"
      output_to_console=$(( JUNJO_LOG_VERBOSE == 1 ))
      ;;
    "$SORT_LOG")
      log_file="$JUNJO_SORT_LOG_FILE"
      color_primary="$COLOR_BOLD_GREEN"
      color_secondary="$COLOR_BRIGHT_GREEN"
      output_to_console=$(( JUNJO_LOG_VERBOSE == 1 ))
      ;;
    "$DEBUG_LOG")
      log_file="$JUNJO_LOG_FILE"
      color_primary="$COLOR_BOLD_MAGENTA"
      color_secondary="$COLOR_BRIGHT_MAGENTA"
      output_to_console=$(( DEBUG ? 1 : 0 ))
      format_message=0
      ;;
    "$ERROR_LOG")
      color_primary="$COLOR_BOLD_RED"
      color_secondary="$COLOR_BRIGHT_RED"
      output_to_stderr=1
      ;;
    "$ABORT_LOG")
      color_primary="$COLOR_BOLD_RED"
      color_secondary="$COLOR_BRIGHT_RED"
      output_to_stderr=1
      ;;
    *)
      category="$MAIN_LOG" # Default to main log
      color_primary="$COLOR_BOLD_CYAN"
      color_secondary="$COLOR_BRIGHT_CYAN"
  esac

  # Format message
  local formatted_message=${message}
  if (( format_message == 1 )); then
    formatted_message=$(color_by_colon "${message}")
  fi

  # Show log message on screen if the category is main
  # or if verbose mode is enabled
  if (( output_to_console == 1 || force_verbose == 1 )); then
    local log_message="${color_primary}${category} ${color_secondary}${timestamp}${COLOR_RESET} ${formatted_message}"
    if (( output_to_stderr == 1 )); then
      echo -e "$log_message" >&2
    else
      echo -e "$log_message"
    fi
  fi

  # Append the log message to the appropriate log file (no color)
  if (( $JUNJO_LOG_WRITE_COLORED_LOGS == 1 )); then
    echo -e "${color_secondary}${timestamp}${COLOR_RESET} ${formatted_message}" >> "$log_file"
  else
    echo "${timestamp} ${message}" >> "$log_file"
  fi
}

color_by_colon() {
  local msg="$1"
  local msg_before_colon
  local msg_after_colon

  if [[ "$msg" == *:* ]]; then
    msg_before_colon="${msg%%:*}:"
    msg_after_colon="${msg#*:}"
    # msg_after_colon="${msg_after_colon# }" # trim leading space

    # Split message by the first ':' and color the part after it with Bright Black
    printf '%s' "${msg_before_colon}${COLOR_BRIGHT_BLACK}${msg_after_colon}${COLOR_RESET}"
  else
    # If no colon, return the message as is
    printf '%s' "$msg"
  fi
}

# Log with no extra formatting
log_raw() {
  local message="$1"
  echo -e "$(color_by_colon "${message}")"
  echo "$1" >> "$JUNJO_LOG_FILE"
}

# Log error also outputs to stderr
log_error() {
  log "$1" "$ERROR_LOG"
}

# Log abort also outputs to stderr
log_abort() {
  log "$1" "$ABORT_LOG"
}

# Log debug only when DEBUG is set
log_debug() {
  if [[ $DEBUG ]]; then
    log "$1" "$DEBUG_LOG"
  fi
}

# --------------------------------------------------------------------------
# Timestamp
# --------------------------------------------------------------------------

# Generate timestamp prefix with milliseconds precision
generate_log_timestamp_prefix() {
  echo "[$(date +"%H:%M:%S.$(printf '%03d' $(( 10#$(date +%N) / 1000000 )) )")]"
  # echo "[$(date +"%Y-%m-%d %H:%M:%S.$(printf '%03d' $(( 10#$(date +%N) / 1000000 )) )")]"
}

generate_log_timestamp_indent() {
  echo "              "
  # echo "                         "
}

# --------------------------------------------------------------------------
# Log tree
# --------------------------------------------------------------------------

# Start a tree section and increase indent
log_tree_start() {
  log_tree "$@"
  # Increase the indentation level for the next log message
  LOG_TREE_INDENT_LEVEL=$((LOG_TREE_INDENT_LEVEL + 1))
}

# Log tree message with branch prefix
log_tree() {
  local message="$1"

  local lines
  mapfile -t lines <<< "$message"

  for idx in "${!lines[@]}"; do
    local line="${lines[$idx]}"
    if [[ $idx -eq 0 ]]; then
      log_tree_branch "$line" "${@:2}"
    else
      log_tree_newline "$line" "${@:2}"
    fi
  done
}

log_tree_last_start() {
  local message="$1"

  local lines
  mapfile -t lines <<< "$message"

  for idx in "${!lines[@]}"; do
    local line="${lines[$idx]}"
    if [[ $idx -eq 0 ]]; then
      log_tree_branch_end "$line" "${@:2}"
    else
      log_tree_newline "$line" "${@:2}"
    fi
  done

  # Increase the indentation level for the next log message
  LOG_TREE_IS_LAST_BRANCH=1
  LOG_TREE_INDENT_LEVEL=$((LOG_TREE_INDENT_LEVEL + 1))
}

# End tree section and decrease indent
log_tree_end() {
  local message="$1"

  if [[ -z "$message" ]]; then
    log_tree_stop
    return 0
  fi

  local lines
  mapfile -t lines <<< "$message"

  for idx in "${!lines[@]}"; do
    local line="${lines[$idx]}"
    if [[ $idx -eq 0 ]]; then
      log_tree_branch_end "$line" "${@:2}"
    else
      log_tree_newline "$line" "${@:2}"
    fi
  done

  log_tree_stop
}

log_tree_stop() {
  LOG_TREE_IS_LAST_BRANCH=0
  LOG_TREE_INDENT_LEVEL=$(( \
    (LOG_TREE_INDENT_LEVEL - 1) > 0 ? \
    (LOG_TREE_INDENT_LEVEL - 1) : \
    0 \
  ))
}

log_tree_indentation() {
  local indent=""
  for ((i = 0; i < LOG_TREE_INDENT_LEVEL; i++)); do
    # If this is the last branch, just space it.
    if [[ $LOG_TREE_IS_LAST_BRANCH -eq 1 && $i -eq $((LOG_TREE_INDENT_LEVEL - 1)) ]]; then
      indent+="    "
      continue;
    fi

    if [[ $i -gt 0 ]]; then
      indent+="│   "
    fi
  done
  echo -n "$indent"
}

log_tree_newline() {
  local message="$1"
  local prefix=""
  if [[ "$LOG_TREE_INDENT_LEVEL" -gt 0 ]]; then
    prefix="$(log_tree_indentation)│   "
  fi
  log "${prefix}${message}" "${@:2}"
}

log_tree_branch() {
  local message="$1"
  local prefix=""
  if [[ "$LOG_TREE_INDENT_LEVEL" -gt 0 ]]; then
    prefix="$(log_tree_indentation)├── "
  fi
  log "${prefix}${message}" "${@:2}"
}

log_tree_branch_end() {
  local message="$1"
  local prefix=""
  if [[ "$LOG_TREE_INDENT_LEVEL" -gt 0 ]]; then
    prefix="$(log_tree_indentation)└── "
  fi
  log "${prefix}${message}" "${@:2}"
}

log_tree_reset() {
  LOG_TREE_INDENT_LEVEL=0
}

# --------------------------------------------------------------------------
# Sugar functions for log_scan
# --------------------------------------------------------------------------

log_scan() {
  log "$1" "$SCAN_LOG" 1
}

log_scan_tree_start() {
  log_tree_start "$1" "$SCAN_LOG" 1
}

log_scan_tree_last_start() {
  log_tree_last_start "$1" "$SCAN_LOG" 1
}

log_scan_tree() {
  log_tree "$1" "$SCAN_LOG" 1
}

log_scan_tree_end() {
  if [[ -z "$1" ]]; then
    log_tree_end "" "$SCAN_LOG" 1
  else
    log_tree_end "$1" "$SCAN_LOG" 1
  fi
}

log_scan_() {
  log "$1" "$SCAN_LOG"
}

log_scan_tree_start_() {
  log_tree_start "$1" "$SCAN_LOG"
}

log_scan_tree_last_start_() {
  log_tree_last_start "$1" "$SCAN_LOG"
}

log_scan_tree_() {
  log_tree "$1" "$SCAN_LOG"
}

log_scan_tree_end_() {
  if [[ -z "$1" ]]; then
    log_tree_end "" "$SCAN_LOG"
  else
    log_tree_end "$1" "$SCAN_LOG"
  fi
}

# --------------------------------------------------------------------------
# Sugar functions for log_plan
# --------------------------------------------------------------------------

log_plan() {
  log "$1" "$PLAN_LOG" 1
}

log_plan_tree_start() {
  log_tree_start "$1" "$PLAN_LOG" 1
}

log_plan_tree_last() {
  log_tree_last_start "$1" "$PLAN_LOG" 1
}

log_plan_tree_last_start() {
  log_tree_last_start "$1" "$PLAN_LOG" 1
}

log_plan_tree() {
  log_tree "$1" "$PLAN_LOG" 1
}

log_plan_tree_end() {
  if [[ -z "$1" ]]; then
    log_tree_end "" "$PLAN_LOG" 1
  else
    log_tree_end "$1" "$PLAN_LOG" 1
  fi
}

log_plan_() {
  log "$1" "$PLAN_LOG"
}

log_plan_tree_start_() {
  log_tree_start "$1" "$PLAN_LOG"
}

log_plan_tree_last_() {
  log_tree_last_start "$1" "$PLAN_LOG"
}

log_plan_tree_last_start_() {
  log_tree_last_start "$1" "$PLAN_LOG"
}

log_plan_tree_() {
  log_tree "$1" "$PLAN_LOG"
}

log_plan_tree_end_() {
  if [[ -z "$1" ]]; then
    log_tree_end "" "$PLAN_LOG"
  else
    log_tree_end "$1" "$PLAN_LOG"
  fi
}


# --------------------------------------------------------------------------
# Sugar functions for log_sort
# --------------------------------------------------------------------------

log_sort() {
  log "$1" "$SORT_LOG" 1
}

log_sort_tree_start() {
  log_tree_start "$1" "$SORT_LOG" 1
}

log_sort_tree_last_start() {
  log_tree_last_start "$1" "$SORT_LOG" 1
}

log_sort_tree() {
  log_tree "$1" "$SORT_LOG" 1
}

log_sort_tree_end() {
  if [[ -z "$1" ]]; then
    log_tree_end "" "$SORT_LOG" 1
  else
    log_tree_end "$1" "$SORT_LOG" 1
  fi
}

log_sort_() {
  log "$1" "$SORT_LOG"
}

log_sort_tree_start_() {
  log_tree_start "$1" "$SORT_LOG"
}

log_sort_tree_last_start_() {
  log_tree_last_start "$1" "$SORT_LOG"
}

log_sort_tree_() {
  log_tree "$1" "$SORT_LOG"
}

log_sort_tree_end_() {
  if [[ -z "$1" ]]; then
    log_tree_end "" "$SORT_LOG"
  else
    log_tree_end "$1" "$SORT_LOG"
  fi
}