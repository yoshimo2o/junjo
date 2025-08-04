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
readonly MAIN_LOG="main"
readonly SCAN_LOG="scan"
readonly SORT_LOG="sort"

# Log file paths (to be set in init_log)
export JUNJO_LOG_FILE=""
export JUNJO_SCAN_LOG_FILE=""
export JUNJO_SORT_LOG_FILE=""

# Log tree
declare -i LOG_TREE_INDENT_LEVEL=0

# Initialize logging system
init_log() {
  # Set up runtime log file paths
  JUNJO_LOG_FILE="$JUNJO_LOG_DIR/$JUNJO_LOG_FILE_NAME"
  JUNJO_SCAN_LOG_FILE="$JUNJO_LOG_DIR/$JUNJO_SCAN_LOG_FILE_NAME"
  JUNJO_SORT_LOG_FILE="$JUNJO_LOG_DIR/$JUNJO_SORT_LOG_FILE_NAME"

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

  > "$JUNJO_SORT_LOG_FILE" || {
    echo "Error: Failed to initialize log file: $JUNJO_SORT_LOG_FILE" >&2
    return 1
  }
}

# Log with timestamp and category
log() {
  local message="$1"
  local category="$2"
  local timestamp="$(log_timestamp)"

  # Determine the log file based on the category
  local log_file
  case "$category" in
    "$SCAN_LOG")
      log_file="$JUNJO_SCAN_LOG_FILE"
      ;;
    "$SORT_LOG")
      log_file="$JUNJO_SORT_LOG_FILE"
      ;;
    *)
      category="$MAIN_LOG" # Default to main log
      log_file="$JUNJO_LOG_FILE"
  esac

  local log_message="${timestamp} ${message}"

  # Show log message on screen if the category is main
  # or if verbose mode is enabled
  if [[ "$category" == "$MAIN_LOG" || "$JUNJO_LOG_VERBOSE" -eq 1 ]]; then
    echo "$log_message"
  fi

  # Append the log message to the appropriate log file
  echo "$log_message" >> "$log_file"
}

# Log error message with timestamp
# Only to the main log.
log_error() {
  local message="$1"
  local timestamp="$(log_timestamp)"
  local log_message="${timestamp} Error: ${message}"

  # Show error message on screen
  echo "$log_message" >&2

  # Append the error message to the main log file
  echo "$log_message" >> "$JUNJO_LOG_FILE"
}

log_debug() {
  local message="$1"
  local timestamp="$(log_timestamp)"
  local log_message="${timestamp} Debug: ${message}"

  # Show debug message on screen if verbose mode is enabled
  if [[ "$JUNJO_LOG_VERBOSE" -eq 1 ]]; then
    echo "$log_message"
  fi

  # Append the debug message to the main log file
  echo "$log_message" >> "$JUNJO_LOG_FILE"
}

# Log without timestamp
log_raw() {
  echo "$1"
  echo "$1" >> "$JUNJO_LOG_FILE"
}

# Generate timestamp string
log_timestamp() {
  # timestamp takes 17 characters
  local timestamp="[$(date '+%Y-%m-%d %H:%M:%S')]"
  echo "$timestamp"
}

# Generate tree indentation string
log_tree_indentation() {
  local indent=""
  for ((i = 0; i < LOG_TREE_INDENT_LEVEL; i++)); do
    if [[ $i -gt 0 ]]; then
      indent+="│   "
    fi
  done
  echo -n "$indent"
}

# Start a tree section and increase indent
log_tree_start() {
  log_tree $@
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
  LOG_TREE_INDENT_LEVEL=$((LOG_TREE_INDENT_LEVEL + 1))
}

# End tree section and decrease indent
log_tree_end() {
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

  LOG_TREE_INDENT_LEVEL=$(( \
    (LOG_TREE_INDENT_LEVEL - 1) > 0 ? \
    (LOG_TREE_INDENT_LEVEL - 1) : \
    0 \
  ))
}

# Log tree branch line
log_tree_branch() {
  local message="$1"
  local prefix=""
  if [[ "$LOG_TREE_INDENT_LEVEL" -gt 0 ]]; then
    prefix="$(log_tree_indentation)├── "
  fi
  log "${prefix}${message}" "${@:2}"
}

# Log tree branch line
log_tree_branch_end() {
  local message="$1"
  local prefix=""
  if [[ "$LOG_TREE_INDENT_LEVEL" -gt 0 ]]; then
    prefix="$(log_tree_indentation)└── "
  fi
  log "${prefix}${message}" "${@:2}"
}

# Log tree continuation line
log_tree_newline() {
  local message="$1"
  local prefix=""
  if [[ "$LOG_TREE_INDENT_LEVEL" -gt 0 ]]; then
    prefix="$(log_tree_indentation)│   "
  fi
  log "${prefix}${message}" "${@:2}"
}

# Reset tree indentation to zero
log_tree_reset() {
  LOG_TREE_INDENT_LEVEL=0
}

# Sugar functions for category-specific logging
log_scan() {
  log "$@" "$SCAN_LOG"
}

log_scan_tree_start() {
  log_tree_start "$@" "$SCAN_LOG"
}

log_scan_tree() {
  log_tree "$@" "$SCAN_LOG"
}

log_scan_tree_newline() {
  log_tree_newline "$@" "$SCAN_LOG"
}

log_scan_tree_last_start() {
  log_tree_last_start "$@" "$SCAN_LOG"
}

log_scan_tree_end() {
  log_tree_end "$@" "$SCAN_LOG"
}

log_sort() {
  log "$@" "$SORT_LOG"
}

log_sort_tree_start() {
  log_tree_start "$@" "$SORT_LOG"
}

log_sort_tree() {
  log_tree "$@" "$SORT_LOG"
}

log_sort_tree_newline() {
  log_tree_newline "$@" "$SORT_LOG"
}

log_sort_tree_last_start() {
  log_tree_last_start "$@" "$SORT_LOG"
}

log_sort_tree_end() {
  log_tree_end "$@" "$SORT_LOG"
}
