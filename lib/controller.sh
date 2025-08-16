junjo_start() {
  clear
  show_app_banner

  # Step 0: Onboarding
  show_log_monitoring_tips
  show_configuration_summary
  init_output_dir

  # Step 1: Get list of files to analyze
  local files
  create_file_list files

  # If no files found, exit early
  if [[ ${#files[@]} -eq 0 ]]; then
    log_abort "No files matching filters found in '$JUNJO_SCAN_DIR'."
    exit 0
  fi

  # Step 2: Analyze the files
  show_scan_dialog
  analyze_media_files "${files[@]}"

  # Step 3: Create a plan to organize the media files
  show_plan_dialog
  create_organizing_plan

  # Step 4: Sort media files
  show_sort_dialog
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

show_app_banner() {
  log_raw ""
  log_raw ""
  log_raw "$COLOR_BOLD_BLUE"
  log_raw '888 8888 8888 888 8e  888  e88 88e '
  log_raw '888 8888 8888 888 88b 888 d888 888b'
  log_raw '888 Y888 888P 888 888 888 Y888 888P'
  log_raw '888  "88 88"  888 888 888  "88 88" '
  log_raw '88P                   88P          '
  log_raw '8"                    8"           '
  log_raw "$COLOR_RESET"
  log_raw ""
}

show_configuration_summary() {
  log_raw "$COLOR_BOLD_BLUE"
  log_raw "Junjo Configuration Summary"
  log_raw "$COLOR_RESET"
  log_raw "Log directory: $JUNJO_LOG_DIR"
  log_raw "├── Main log: $JUNJO_LOG_FILE_NAME"
  log_raw "├── Scan log: $JUNJO_SCAN_LOG_FILE_NAME"
  log_raw "├── Plan log: $JUNJO_PLAN_LOG_FILE_NAME"
  log_raw "└── Sort log: $JUNJO_SORT_LOG_FILE_NAME"
  log_raw "Scan directory: $JUNJO_SCAN_DIR"
  log_raw "├── Directory: $(realpath "$JUNJO_SCAN_DIR")"
  log_raw "├── Recursive scan: $(yes_or_no $JUNJO_SCAN_RECURSIVE)"
  log_raw "├── Include files: ${JUNJO_INCLUDE_FILES[*]}"
  log_raw "└── Exclude files: ${JUNJO_EXCLUDE_FILES[*]}"
  log_raw "Output directory: $JUNJO_OUTPUT_DIR"
  log_raw "Grouping structure:"
  # Loop through JUNJO_OUTPUT_DIR_STRUCTURE and output with log_raw
  for idx in "${!JUNJO_OUTPUT_DIR_STRUCTURE[@]}"; do
    item="${JUNJO_OUTPUT_DIR_STRUCTURE[$idx]}"
    if [[ $idx -lt $((${#JUNJO_OUTPUT_DIR_STRUCTURE[@]} - 1)) ]]; then
      log_raw "├── ${GROUPING_DESCRIPTIONS[$item]}"
    else
      log_raw "└── ${GROUPING_DESCRIPTIONS[$item]}"
    fi
  done
  log_raw "Operations:"
  log_raw "├── Copy or move files: ${JUNJO_FILE_OPERATION^}"
  log_raw "├── Set EXIF timestamp: $(yes_or_no $JUNJO_SET_EXIF_TIMESTAMP)"
  log_raw "├── Set EXIF geodata: $(yes_or_no $JUNJO_SET_EXIF_GEODATA)"
  log_raw "├── Set file create time: $(yes_or_no $JUNJO_SET_FILE_CREATE_TIME)"
  log_raw "└── Set file modify time: $(yes_or_no $JUNJO_SET_FILE_MODIFY_TIME)"
  log_raw ""

  if ! confirm_box \
    "We will be running Junjo based on the configuration set above." \
    "Proceed with the configuration above?"; then
    log_abort "User stopped at configuration checking."
    exit 1
  fi
}

show_scan_dialog() {
  if ! confirm_box \
    "" \
    "${COLOR_BOLD_BLUE}SCAN & ANALYZE${COLOR_RESET}" \
    "" \
    "We are about to analyze ${#files[@]} media files found in the directory:" \
    "  ${COLOR_BRIGHT_BLACK}${JUNJO_SCAN_DIR}${COLOR_RESET}" \
    "" \
    "This operation involves:" \
    " - Extracting file path components" \
    " - Extracting Google Takeout metadata" \
    " - Extracting EXIF metadata" \
    " - Determining the most reliable photo/video taken time" \
    " - Determining the device used to capture the photo/video" \
    " - Determining the software used to create the photo/video" \
    " - Identifying the file media type" \
    " - Pairing live photo and video files" \
    " - Finding live photos/videos with duplicates" \
    " - Finding live photos with missing video pair" \
    " - Finding live videos with missing photo pair" \
    "" \
    "This may take some time depending on the number of media files" \
    "and their file sizes." \
    "" \
    "If you are running Junjo without verbose (-v) output," \
    "you can still view the full detailed scan log using:" \
    "  ${COLOR_BRIGHT_BLACK}less -R +F ${JUNJO_SCAN_LOG_FILE}${COLOR_RESET}" \
    "" \
    "Proceed with analyzing ${#files[@]} files?" \
  ; then
    log_abort "User did not proceed with analyzing files."
    exit 0
  fi
}

show_plan_dialog() {
  if ! confirm_box \
    "" \
    "${COLOR_BOLD_YELLOW}PLAN & STRATEGIZE${COLOR_RESET}" \
    "" \
    "We are about to create a plan to organize your media files." \
    "" \
    "This operation involves:" \
    " - Computing file destination using sub-directory" \
    "   grouping rules configured in your config file." \
    " - Identifying duplicate files." \
    " - Scoring duplicates to determine which is the preferred file." \
    " - Checking if its possible to remove duplicate markers from filename." \
    " - Resolving potential naming conflicts." \
    " - Resolving filename mismatches between live photo/video pairs" \
    " - Create a list of planned actions to be performed on the file." \
    "" \
    "This may take some time depending on the number of media files" \
    "and their file sizes." \
    "" \
    "If you are running Junjo without verbose (-v) output," \
    "you can still view the full detailed plan log using:" \
    "  ${COLOR_BRIGHT_BLACK}less -R +F ${JUNJO_PLAN_LOG_FILE}${COLOR_RESET}" \
    "" \
    "Proceed with creating an organizing plan for ${#files[@]} media files?" \
  ; then
    log_abort "User did not to proceed with creating an organizing plan."
    exit 0
  fi
}

show_sort_dialog() {
  if ! confirm_box \
    "" \
    "${COLOR_BOLD_GREEN}SORT & ORGANIZE${COLOR_RESET}" \
    "" \
    "We are about to begin organizing the files in your folder." \
    "" \
    "This operation involves:" \
    " - [${COLOR_GREEN}$(check_if "$([[ $JUNJO_FILE_OPERATION == $FILE_OPERATION_COPY ]] && echo 1 || echo 0)")${COLOR_RESET}] Copying files to their computed destination folders" \
    " - [${COLOR_GREEN}$(check_if "$([[ $JUNJO_FILE_OPERATION == $FILE_OPERATION_MOVE ]] && echo 1 || echo 0)")${COLOR_RESET}] Moving files to their computed destination folders" \
    " - [${COLOR_GREEN}$(check_if $JUNJO_SET_EXIF_TIMESTAMP)${COLOR_RESET}] Setting timestamp on EXIF metadata ${COLOR_BRIGHT_BLACK}(using most reliable timestamp found)${COLOR_RESET}" \
    " - [${COLOR_GREEN}$(check_if $JUNJO_SET_EXIF_GEODATA)${COLOR_RESET}] Setting geodata on EXIF metadata ${COLOR_BRIGHT_BLACK}(from Google Takeout metadata)${COLOR_RESET}" \
    " - [${COLOR_GREEN}$(check_if $JUNJO_SET_FILE_CREATE_TIME)${COLOR_RESET}] Setting the file creation time ${COLOR_BRIGHT_BLACK}(using most reliable timestamp found)${COLOR_RESET}" \
    " - [${COLOR_GREEN}$(check_if $JUNJO_SET_FILE_MODIFY_TIME)${COLOR_RESET}] Setting the file modification time ${COLOR_BRIGHT_BLACK}(using most reliable timestamp found)${COLOR_RESET}" \
    "" \
    "You can review the organizing plan by inspecting the plan log file:" \
    "  ${COLOR_BRIGHT_BLACK}less -R +F ${JUNJO_PLAN_LOG_FILE}${COLOR_RESET}" \
    "" \
    "If you are running Junjo without verbose (-v) output," \
    "you can still view the full detailed sort log using:" \
    "  ${COLOR_BRIGHT_BLACK}less -R +F ${JUNJO_SORT_LOG_FILE}${COLOR_RESET}" \
    "" \
    "${COLOR_BOLD_RED}CAUTION! WRITE OPERATION AHEAD!${COLOR_RESET}" \
    "" \
    "If you are performing a move operation, please make sure that:" \
    " - You have reviewed the organizing plan" \
    " - You are satisfied with the organizing plan" \
    " - You have a backup of the source folder" \
    "" \
    "Proceed with organizing ${#files[@]} files?" \
  ; then
    log_abort "User did not to proceed with organizing files."
    exit 0
  fi
}