junjo_start() {

  # Step 1: Scan media folder
  scan_media_folder

  # Step 2: Create a plan to organize the media files
  create_organizing_plan

  # Step 3: Sort media files
  # sort_media_files

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
}