junjo_start() {

  # Step 1: Get list of files to analyze
  local files
  create_file_list files

  # If no files found, exit early
  if [[ ${#files[@]} -eq 0 ]]; then
    log_abort "No files matching filters found in '$JUNJO_SCAN_DIR'."
    exit 0
  fi

  if ! confirm_box \
    "" \
    "We are about to analyze ${#files[@]} files found in the directory:" \
    "  ${COLOR_BRIGHT_BLACK}${JUNJO_SCAN_DIR}${COLOR_RESET}" \
    "" \
    "This may take some time depending on the number of files" \
    "and their file sizes." \
    "" \
    "If you are running Junjo without verbose (-v) output," \
    "you can still view the scan log in verbose detail using:" \
    "  ${COLOR_BRIGHT_BLACK}less -R +F ${JUNJO_SCAN_LOG_FILE}${COLOR_RESET}" \
    "" \
    "Proceed with analyzing ${#files[@]} files?" \
  ; then
    log_abort "User opted not proceed with analyzing files."
    exit 0
  fi

  # Step 2: Analyze the files
  analyze_media_files "${files[@]}"

  # Step 3: Create a plan to organize the media files
  create_organizing_plan

  # Step 4: Sort media files
  sort_media_files
}

check_dependencies() {
  # Check for required dependencies and report all missing at once
  local missing=()
  local install_instructions=()

  # Detect OS/distro and package manager
  local os="$(uname)"
  local pkg=""
  local distro=""
  if [[ "$os" == "Darwin" ]]; then
    pkg="brew"
    distro="macOS"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        pkg="apt-get"
        distro="Ubuntu/Debian"
        ;;
      fedora)
        pkg="dnf"
        distro="Fedora"
        ;;
      centos|rhel)
        pkg="yum"
        distro="CentOS/RHEL"
        ;;
      arch)
        pkg="pacman"
        distro="Arch Linux"
        ;;
      opensuse*)
        pkg="zypper"
        distro="openSUSE"
        ;;
      alpine)
        pkg="apk"
        distro="Alpine Linux"
        ;;
      gentoo)
        pkg="emerge"
        distro="Gentoo"
        ;;
      *)
        pkg=""
        distro="$ID"
        ;;
    esac
  fi

  # Bash version
  if ((BASH_VERSINFO[0] < 4)); then
    missing+=("Bash >= 4.0")
    case "$pkg" in
      brew) install_instructions+=("brew install bash") ;;
      apt-get) install_instructions+=("sudo apt-get install bash") ;;
      dnf) install_instructions+=("sudo dnf install bash") ;;
      yum) install_instructions+=("sudo yum install bash") ;;
      pacman) install_instructions+=("sudo pacman -S bash") ;;
      zypper) install_instructions+=("sudo zypper install bash") ;;
      apk) install_instructions+=("sudo apk add bash") ;;
      emerge) install_instructions+=("sudo emerge app-shells/bash") ;;
      *) install_instructions+=("Install bash using your package manager") ;;
    esac
  fi

  # exiftool
  if ! command -v exiftool >/dev/null 2>&1; then
    missing+=("exiftool")
    case "$pkg" in
      brew) install_instructions+=("brew install exiftool") ;;
      apt-get) install_instructions+=("sudo apt-get install libimage-exiftool-perl") ;;
      dnf) install_instructions+=("sudo dnf install perl-Image-ExifTool") ;;
      yum) install_instructions+=("sudo yum install perl-Image-ExifTool") ;;
      pacman) install_instructions+=("sudo pacman -S perl-image-exiftool") ;;
      zypper) install_instructions+=("sudo zypper install perl-Image-ExifTool") ;;
      apk) install_instructions+=("sudo apk add perl-image-exiftool") ;;
      emerge) install_instructions+=("sudo emerge dev-perl/Image-ExifTool") ;;
      *) install_instructions+=("Install exiftool using your package manager") ;;
    esac
  fi

  # jq
  if ! command -v jq >/dev/null 2>&1; then
    missing+=("jq")
    case "$pkg" in
      brew) install_instructions+=("brew install jq") ;;
      apt-get) install_instructions+=("sudo apt-get install jq") ;;
      dnf) install_instructions+=("sudo dnf install jq") ;;
      yum) install_instructions+=("sudo yum install jq") ;;
      pacman) install_instructions+=("sudo pacman -S jq") ;;
      zypper) install_instructions+=("sudo zypper install jq") ;;
      apk) install_instructions+=("sudo apk add jq") ;;
      emerge) install_instructions+=("sudo emerge app-misc/jq") ;;
      *) install_instructions+=("Install jq using your package manager") ;;
    esac
  fi

  # gdate (coreutils)
  if ! command -v gdate >/dev/null 2>&1; then
    missing+=("gdate (coreutils)")
    case "$pkg" in
      brew) install_instructions+=("brew install coreutils") ;;
      apt-get) install_instructions+=("sudo apt-get install coreutils") ;;
      dnf) install_instructions+=("sudo dnf install coreutils") ;;
      yum) install_instructions+=("sudo yum install coreutils") ;;
      pacman) install_instructions+=("sudo pacman -S coreutils") ;;
      zypper) install_instructions+=("sudo zypper install coreutils") ;;
      apk) install_instructions+=("sudo apk add coreutils") ;;
      emerge) install_instructions+=("sudo emerge sys-apps/coreutils") ;;
      *) install_instructions+=("Install coreutils using your package manager") ;;
    esac
  fi

  if (( ${#missing[@]} > 0 )); then
    echo "Missing dependencies:" >&2
    for dep in "${missing[@]}"; do
      echo "  $dep" >&2
    done
    echo "To install missing dependencies on $distro, run:" >&2
    for instr in "${install_instructions[@]}"; do
      echo "  $instr" >&2
    done
    exit 1
  fi
}

init_output_dir() {
  # If output directory is not empty,
  # ask user whether to overwrite the directory.
  # Existing files in the directory will be overwritten.
  if [[ -d "$JUNJO_OUTPUT_DIR" && "$(ls -A "$JUNJO_OUTPUT_DIR")" ]]; then
    log_raw "It appears that the output directory '$JUNJO_OUTPUT_DIR' is not empty."
    log_raw "If a file being copied or moved has the same name as one already in the directory, the existing file will be replaced."

    if ! confirm "Would you like to proceed?"; then
      log_abort "User opted not to proceed."
      exit 1
    fi
  fi

  # If output directory exists,
  # check if output directory is writable.
  if [[ -d "$JUNJO_OUTPUT_DIR" ]]; then
    if [[ ! -w "$JUNJO_OUTPUT_DIR" ]]; then
      log_error "Output directory '$JUNJO_OUTPUT_DIR' is not writable."
      exit 1
    fi
  fi

  # If output directory is not created,
  # ask user whether to create it.
  if [[ ! -d "$JUNJO_OUTPUT_DIR" ]]; then

    if ! confirm_box \
     "Output directory '$JUNJO_OUTPUT_DIR' does not exist. " \
     "Create output directory now?"; then
      log_abort "User opted not to create output directory."
      exit 1
    fi

    # Create the output directory with error handling
    mkdir -p "$JUNJO_OUTPUT_DIR" || {
      log_error "Failed to create output directory '$JUNJO_OUTPUT_DIR'."
      exit 1
    }
  fi
}

show_log_monitoring_tips() {
  draw_box \
    "" \
    "If you are running Junjo without verbose (-v) output," \
    "you can still view the logs in verbose detail using:" \
    "  Scan log: less -R +F $JUNJO_SCAN_LOG_FILE" \
    "  Plan log: less -R +F $JUNJO_PLAN_LOG_FILE" \
    "  Sort log: less -R +F $JUNJO_SORT_LOG_FILE" \
    "" \
    "Here are some tips on how to navigate the logs with \"less -R +F\":" \
    "  Ctrl-C : pause log streaming" \
    "  Shift-F: resume log streaming" \
    "  /      : search forward, e.g. /IMG_9224.JPG" \
    "  ?      : search backward, e.g. ?IMG_9224.JPG" \
    "  &      : display only lines that match, e.g. & IMG_9224.JPG" \
    "  &!     : display lines that do not match, e.g. & IMG_9224.JPG" \
    "  n/N    : next/previous match" \
    "  g/G    : top/end of file" \
    ""

  press_any_key
}