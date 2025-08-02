log_error() {
  local message="$1"
  echo "Error: $message" >&2
}

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