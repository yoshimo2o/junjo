debug_string() {
  local msg=""
  if [[ $# -eq 1 ]]; then
    log_debug "\n$(___string "$1")"
  else
    msg="$1"; shift
    log_debug "${msg}\n$(___string "$@")"
  fi
}

debug_array() {
  local msg=""
  if [[ $# -eq 1 ]]; then
    log_debug "\n$(___array "$1")"
  else
    msg="$1"; shift
    log_debug "${msg}\n$(___array "$@")"
  fi
}

debug_map() {
  local msg=""
  if [[ $# -eq 1 ]]; then
    log_debug "\n$(___map "$1")"
  else
    msg="$1"; shift
    log_debug "${msg}\n$(___map "$@")"
  fi
}

debug_date() {
  local msg=""
  if [[ $# -eq 1 ]]; then
    log_debug "\n$(___date "$1")"
  else
    msg="$1"; shift
    log_debug "${msg}\n$(___date "$@")"
  fi
}

___string() {
  # Usage: ___str "string input here"
  local input="$1"
  local len=${#input}
  printf '"%s" (length=%d)' "$input" "$len"
}

___array() {
  # Usage: ___array "${array[@]}"
  local arr=("$@")
  local out=""
  local i
  for ((i=0; i<${#arr[@]}; i++)); do
    out+="[${i}] => \"${arr[$i]}\"\n"
  done
  out+="(length=${#arr[@]})"
  printf "%s" "${out%\n}"
}

___map() {
  # Usage: ___map ${!assoc_array[@]} -- ${assoc_array[@]}
  local keys=()
  local vals=()
  local found_sep=0
  for arg in "$@"; do
    if [[ $found_sep -eq 0 && $arg == -- ]]; then
      found_sep=1
      continue
    fi
    if [[ $found_sep -eq 0 ]]; then
      keys+=("$arg")
    else
      vals+=("$arg")
    fi
  done
  local out=""
  local i
  for ((i=0; i<${#keys[@]}; i++)); do
    out+="[${keys[$i]}] => \"${vals[$i]}\"\n"
  done
  out+="(length=${#keys[@]})"
  printf "%s" "${out%\n}"
}

___date() {
  # Usage: ___date "date_string"
  local input="$1"
  local iso=""
  local epoch_ms=""

  # Try to parse as Unix epoch (seconds or ms)
  if [[ "$input" =~ ^[0-9]{13}$ ]]; then
    # Milliseconds epoch
    epoch_ms="$input"
    iso=$(date -u -j -f "%s" "$((input/1000))" "+%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null)
  elif [[ "$input" =~ ^[0-9]{10}$ ]]; then
    # Seconds epoch
    epoch_ms="$((input * 1000))"
    iso=$(date -u -j -f "%s" "$input" "+%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null)
  elif echo "$input" | grep -Eq '^[0-9]{4}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$'; then
    # EXIF format: YYYY:MM:DD HH:MM:SS(.sss)
    local exif_date="${input/:/-}" # replace first : with -
    exif_date="${exif_date/:/-}"   # replace second : with -
    iso=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "${exif_date%%.*}" "+%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null)
    epoch_ms=$(date -j -f "%Y-%m-%d %H:%M:%S" "${exif_date%%.*}" "+%s" 2>/dev/null)
    epoch_ms="$((epoch_ms * 1000))"
  else
    # Try to parse as ISO or other common formats
    iso=$(date -u -j -f "%Y-%m-%dT%H:%M:%S" "$input" "+%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null)
    if [[ -z "$iso" ]]; then
      iso=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$input" "+%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null)
    fi
    if [[ -n "$iso" ]]; then
      epoch_ms=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${iso:0:19}" "+%s" 2>/dev/null)
      epoch_ms="$((epoch_ms * 1000))"
    fi
  fi

  # Fallback if parsing failed
  [[ -z "$iso" ]] && iso="Invalid or unknown format"
  [[ -z "$epoch_ms" ]] && epoch_ms="Invalid or unknown format"

  printf "  Input: \"%s\"\nISO8601: \"%s\"\n  Epoch: \"%s\"" "$input" "$iso" "$epoch_ms"
}