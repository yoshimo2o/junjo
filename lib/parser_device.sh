
# ====================================================================================================
# get_friendly_device_name <fid>
#
# Determines a user-friendly device name from EXIF metadata and Google Takeout metadata.
# This function analyzes various metadata sources to generate a human-readable device name
# for media files. It prioritizes EXIF camera data but falls back to Google Takeout metadata
# when EXIF data is unavailable or incomplete.
#
# Parameters:
#   1. fid → File ID to get friendly device name for
#
# Return:
#   Outputs friendly device name to stdout
#
# Example scenarios:
#   - Apple device:       "iPhone 15 Pro Max"
#   - Android device:     "Samsung SM-F926B"
#   - Camera:             "Canon EOS R5"
#   - Takeout fallback:   "Android Phone"
#   - Upload fallback:    "Mobile"
#   - Unknown:            "Unknown"
#
# Example usage:
#   device_name="$(get_friendly_device_name "$fid")"
#   echo "Device: $device_name"
# ====================================================================================================

get_friendly_device_name() {

  local fid="$1"

  # Get metadata needed to construct friendly device name
  local device_make="${file_exif_make[$fid]:-}"
  local device_model="${file_exif_model[$fid]:-}"
  local lens_make="${file_exif_lens_make[$fid]:-}"
  local lens_model="${file_exif_lens_model[$fid]:-}"
  local device_type="${file_takeout_device_type["$fid"]:-}"
  local upload_origin="${file_takeout_upload_origin["$fid"]:-}"

  # Construct device_name
  local device_name

  # If this is an Apple device, just use the models.
  #   e.g. iPhone 7 Plus, iPhone SE, iPhone 15 Pro Max
  if [[ "$device_make" == "Apple" ]]; then
    device_name="$device_model"

  # Edge case to handle certain iPhone 4 photos where make and model are not available
  # but lens make and lens model is available (see: samples/iphone4-lens-make-fallback)
  #   e.g. iPhone 4 back camera 3.85mm f/2.8 -> iPhone 4
  elif [[ "$lens_make" == "Apple" ]] && [[ -n "$lens_model" ]]; then
    if [[ "$lens_model" =~ ^((iPhone|iPad)[^[:space:]]*([[:space:]]+[^[:space:]]+)*)[[:space:]]+(back|front) ]]; then
      device_name="${BASH_REMATCH[1]}"
    else
      device_name="Apple Unknown" # Fallback if lens model doesn't match expected pattern
    fi

  # If this is not an Apple device, use the device make and model, e.g.
  #   e.g. a) Make + Model
  #             Make:  Sony
  #             Model: XQ-DQ54
  #               => Sony XQ-DQ54
  #        b) Normalized Make + Model
  #             Make:  Samsung Electronics -> Samsung
  #             Model: SM-F926B
  #               => Samsung SM-F926B
  #        c) Normalized Make + Normalized Model
  #             Make:  CANON      -> Canon
  #             Model: Canon Ixus -> Ixus
  #               => Canon Ixus
  elif [[ -n "$device_make" && -n "$device_model" ]]; then

    # Normalize make, e.g.
    #   OLYMPUS DIGITAL CAMERA -> Olympus
    #   LG ELECTRONICS -> LG
    #   CANON -> Canon
    local normalized_make=$(normalize_device_make "$device_make")

    # Normalize model, e.g.
    #   Canon Ixus -> Ixus
    if [[ -n "$normalized_make" && "${device_model^^}" == "${normalized_make^^}"* ]]; then
      # Remove the make from the model
      local normalized_model="${device_model:${#normalized_make}}"
      normalized_model="${normalized_model# }" # Remove leading spaces
      device_name="${normalized_make} ${normalized_model}"
    elif [[ -n "$normalized_make" ]]; then
      device_name="${normalized_make} $device_model"
    fi

  # If only device model is available, use it as device name
  elif [[ -z "$device_make" && -n "$device_model" ]]; then
    device_name="$device_model"

  # If no make and model available from exif metadata,
  # use the device type from takeout metadata.
  #   e.g. IOS_PHONE -> iPhone
  #        IOS_TABLET -> iPad
  #        ANDROID_PHONE -> Android Phone
  #        ANDROID_TABLET -> Android Tablet
  elif [[ -n "$device_type" ]]; then
    case "$device_type" in
      IOS_PHONE)
        device_name="iPhone";;
      IOS_TABLET)
        device_name="iPad";;
      ANDROID_PHONE)
        device_name="Android Phone";;
      ANDROID_TABLET)
        device_name="Android Tablet";;
    esac

  # If all else fails, use upload origin to give it a generic device name.
  elif [[ -n "$upload_origin" ]]; then
    case "$upload_origin" in
      mobile)
        device_name="Mobile";;
      desktop)
        device_name="Desktop";;
      web)
        device_name="Web";;
    esac

  # If nothing else works, fallback to "Unknown".
  else
    device_name="Unknown"
  fi

  # Trim whitespace around device_name
  device_name="${device_name#"${device_name%%[![:space:]]*}"}"
  device_name="${device_name%"${device_name##*[![:space:]]}"}"

  echo "$device_name"
  return 0
}


# ====================================================================================================
# normalize_device_make <device_make>
#
# Normalizes manufacturer names into friendlier format.
#
# Parameters:
#   1. device_make → Raw device manufacturer name from EXIF data
##
# Returns:
#   Outputs normalized manufacturer name.
#
# Examples:
#   - "CANON" → "Canon"
#   - "LG ELECTRONICS" → "LG"
#   - "DJI Corporation Inc." → "DJI"
#
# Example usage:
#   normalized_make="$(normalize_device_make "$device_make")"
#   echo "Normalized: $normalized_make"
# ====================================================================================================

normalize_device_make() {
  local device_make="$1"
  local result=""

  # Default: capitalize first letter, lowercase the rest, e.g.
  #   CANON -> Canon
  if [[ -n "$device_make" ]]; then
    result="$(echo "$device_make" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"
  fi

  # Search & replace patterns (substring match, case-insensitive)
  # This mainly shortens the device_make names, e.g.
  #   LG ELECTRONICS -> LG
  #   OLYMPUS DIGITAL CAMERA -> Olympus
  # or to keep capitalization consistent (as it was ucfirst'ed in the logic before), e.g.
  #   Dji -> DJI
  #   Htc -> HTC
  declare -A make_map=(
    ["APPLE"]="Apple"
    ["ASUS"]="Asus"
    ["BLACKBERRY"]="BlackBerry"
    ["BLACKMAGIC"]="Blackmagic"
    ["BLACKVIEW"]="Blackview"
    ["CANON"]="Canon"
    ["CASIO"]="Casio"
    ["DJI"]="DJI"
    ["DOOGEE"]="Doogee"
    ["FUJIFILM"]="Fujifilm"
    ["GOOGLE"]="Google"
    ["HONOR"]="Honor"
    ["HTC"]="HTC"
    ["HUAWEI"]="Huawei"
    ["INFINIX"]="Infinix"
    ["ITEL"]="Itel"
    ["LEICA"]="Leica"
    ["LENOVO"]="Lenovo"
    ["LG"]="LG"
    ["MEIZU"]="Meizu"
    ["MICROSOFT"]="Microsoft"
    ["MOTOROLA"]="Motorola"
    ["NIKON"]="Nikon"
    ["NOKIA"]="Nokia"
    ["OLYMPUS"]="Olympus"
    ["OM DIGITAL"]="OM"
    ["ONEPLUS"]="OnePlus"
    ["OPPO"]="Oppo"
    ["PANASONIC"]="Panasonic"
    ["PENTAX"]="Pentax"
    ["REALME"]="Realme"
    ["RICOH"]="Ricoh"
    ["SAMSUNG"]="Samsung"
    ["SIGMA"]="Sigma"
    ["SONY"]="Sony"
    ["TCL"]="TCL"
    ["TECNO"]="Tecno"
    ["UMIDIGI"]="Umidigi"
    ["VIVO"]="Vivo"
    ["XIAOMI"]="Xiaomi"
    ["ZEISS"]="Zeiss"
    ["ZTE"]="ZTE"
  )

  for pattern in "${!make_map[@]}"; do
    if [[ "${device_make^^}" == *"$pattern"* ]]; then
      result="${make_map[$pattern]}"
      break
    fi
  done

  echo "$result"
}