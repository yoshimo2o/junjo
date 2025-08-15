create_organizing_plan() {
  # Step 1: Compute file destinations
  log_plan "Computing file destinations."
  if compute_file_destinations; then
    log_plan "Successfully computed file destinations."
  else
    log_plan_error "Failed to compute file destinations."
    return 1
  fi

  # Step 2: Resolve naming conflicts in file destinations
  log_plan "Resolving naming conflicts in file destinations."
  if resolve_destination_naming_conflicts; then
    log_plan "Naming conflict resolution completed successfully."
  else
    log_plan_error "Naming conflict resolution failed."
    return 1
  fi

  # Step 3: Create an action plan to organize the files
  log_plan "Creating an action plan to organize the files."
  if create_action_plan; then
    log_plan "Action plan creation completed successfully."
  else
    log_plan_error "Action plan creation failed."
    return 1
  fi
}

compute_file_destinations() {
  local index=1
  local total=${#file_src[@]}
  # debug_map "compute_file_destinations()->file_src" ${!file_src[@]} -- ${file_src[@]}

  for fid in "${!file_src[@]}"; do
    log_plan_tree_start "[$(progress "$index" "$total" "/")] Computing destination for file: ${file_src["$fid"]}"

    compute_file_destination "$fid"

    log_plan_tree_end "Destination: ${file_dest[$fid]} $(\
      [[ ${file_dest_has_naming_conflict[$fid]} -eq 1 ]] \
        && echo '(Has Conflict)')"

    index=$(($index + 1))
  done
}

compute_file_destination() {
  local fid="$1"
  local dest \
    dest_dir \
    dest_name \
    dest_stem \
    dest_root_stem \
    dest_ext \
    dest_compound_ext \
    dest_dupe_marker

  # Compute destination directory
  compute_destination_directory "$fid" dest_dir

  # Compute destination file
  dest="${dest_dir}${file_src_root_stem[$fid]}${file_src_compound_ext[$fid]}"

  # Extract destination file components
  extract_file_components "$dest" \
    dest_dir \
    dest_name \
    dest_stem \
    dest_root_stem \
    dest_ext \
    dest_compound_ext \
    dest_dupe_marker

  # Add the components to the global array database
  file_dest["$fid"]="$dest"
  file_dest_dir["$fid"]="$dest_dir"
  file_dest_name["$fid"]="$dest_name"
  file_dest_stem["$fid"]="$dest_stem"
  file_dest_root_stem["$fid"]="$dest_root_stem"
  file_dest_ext["$fid"]="$dest_ext"
  file_dest_compound_ext["$fid"]="$dest_compound_ext"
  file_dest_dupe_marker["$fid"]="$dest_dupe_marker"

  # Compute destination id (did)
  # Assume case-insensitive file system by uppercasing everything.
  # e.g. "foo/bar/IMG_1234.jpg" == "FOO/BAR/IMG_1234.JPG"
  local did="$(compute_file_id "${dest^^}")"

  # debug_string "compute_file_destination()->fid" "$fid"
  # debug_string "compute_file_destination()->fid" "$did"
  # debug_string "compute_file_destination()->dest" "$dest"
  # debug_string "compute_file_destination()->dest_dir" "$dest_dir"
  # debug_string "compute_file_destination()->dest_name" "$dest_name"
  # debug_string "compute_file_destination()->dest_stem" "$dest_stem"
  # debug_string "compute_file_destination()->dest_root_stem" "$dest_root_stem"
  # debug_string "compute_file_destination()->dest_ext" "$dest_ext"
  # debug_string "compute_file_destination()->dest_compound_ext" "$dest_compound_ext"
  # debug_string "compute_file_destination()->dest_dupe_marker" "$dest_dupe_marker"

  # If this is the initial file with this destination
  if [[ -z "${file_dest_entries["$did"]}" ]]; then

    # Add this initial file file destination entries
    file_dest_entries["$did"]="$fid"

    # Mark this intiial file has having no naming conflict
    file_dest_has_naming_conflict["$fid"]=0
  else
    # If this is the first time a naming conflict has been detected
    if [[ -z "${file_dest_conflicts["$did"]}" ]]; then

      # Get the fid of the initial file that has this destination
      initial_fid="${file_dest_entries["$did"]}"

      # Add the fid of that initial file to the conflict list
      file_dest_conflicts["$did"]="$initial_fid"

      # Mark the initial file as having naming conflict
      file_dest_has_naming_conflict["$initial_fid"]=1
    fi

    # Append the fid of the current file to the conflict list
    file_dest_conflicts["$did"]+="|${fid}"

    # Mark the current file as having naming conflict
    file_dest_has_naming_conflict["$fid"]=1
  fi

  # Verbose log the file destination details
  log_plan_tree_ "Source File ID      : ${fid}"
  log_plan_tree_ "Source Folder       : ${file_src_dir["$fid"]}"
  log_plan_tree_ "Source Filename     : ${file_src_name["$fid"]}"
  log_plan_tree_ "Destination File ID : ${did}"
  log_plan_tree_ "Destination Folder  : ${file_dest_dir["$fid"]}"
  log_plan_tree_ "Destination Name    : ${file_dest_name["$fid"]}"
  log_plan_tree_ "Has Conflict        : ${file_dest_has_naming_conflict["$fid"]}"
}

# Computes the destination directory based on the configured structure
# The computed path comes with trailing slash.
compute_destination_directory() {
  local fid="$1"
  local -n dest_dir_ref="$2"
  local timestamp_epoch="${file_timestamp_epoch["$fid"]}"
  # debug_string "compute_destination_directory()->fid" "$fid"
  # debug_string "compute_destination_directory()->dest_dir_ref" "$dest_dir_ref"
  # debug_string "compute_destination_directory()->timestamp_epoch" "$timestamp_epoch"

  # Compute the destination directory based on the configured structure
  dest_dir_ref=""
  for structure in "${JUNJO_OUTPUT_DIR_STRUCTURE[@]}"; do
    case "$structure" in
      "$GROUP_BY_DEVICE")
          # See `get_friendly_device_name()` for details on device name construction.
          #   e.g. Exact Model   : "iPhone 7 Plus/", "Samsung SM-F926B/", "Sony XQ-DQ54/", etc.
          #        Device Type   : "iPhone/", "iPad/", "Android Phone/", "Android Tablet/"
          #        Upload Origin : "Mobile/", "Desktop/", "Web/"
          #        Unknown       : "Unknown/"
          local device_name="${file_device_name["$fid"]}"
          # debug_string "compute_destination_directory()->device_name" "$device_name"
          dest_dir_ref+="${device_name}/"
        ;;
      "$GROUP_BY_SOFTWARE")
          # See `get_most_likely_software_name()` for details on software name construction.
          #   e.g. App Folder        : "WhatsApp Images/", "Photoshop Express/"
          #        Known Patterns    : "WhatsApp/", "Facebook/",
          #        Observed Patterns : "WhatsApp (Possibly)/", "Telegram (Possibly)/", "Downloads/"
          #        Other Categories  : "Screenshots/", "Screen Recordings/"
          local software_name="${file_software_name["$fid"]}"
          # debug_string "compute_destination_directory()->software_name" "$software_name"
          if [[ -n "$software_name" ]]; then
            dest_dir_ref+="${software_name}/"
          fi
        ;;
      "$GROUP_BY_YEAR")
        # YYYY, e.g. "2025/"
        local year="$(epoch_ms_date_fmt "$timestamp_epoch" +%Y)"
        # debug_string "compute_destination_directory()->year" "$year"
        dest_dir_ref+="${year}/"
        ;;
      "$GROUP_BY_MONTH")
        # MM, e.g. "12/"
        local month="$(epoch_ms_date_fmt "$timestamp_epoch" +%m)"
        # debug_string "compute_destination_directory()->month" "$month"
        dest_dir_ref+="${month}/"
        ;;
      "$GROUP_BY_DAY")
        # DD, e.g. "31/"
        local day="$(epoch_ms_date_fmt "$timestamp_epoch" +%d)"
        # debug_string "compute_destination_directory()->day" "$day"
        dest_dir_ref+="${day}/"
        ;;
      "$GROUP_BY_YEAR_MONTH")
        # YYYY-MM, e.g. "2025-12/"
        local year_month="$(epoch_ms_date_fmt "$timestamp_epoch" +%Y-%m)"
        # debug_string "compute_destination_directory()->year_month" "$year_month"
        dest_dir_ref+="${year_month}/"
        ;;
      "$GROUP_BY_YEAR_MONTH_DAY")
        # YYYY-MM-DD, e.g. "2025-12-31/"
        local year_month_day="$(epoch_ms_date_fmt "$timestamp_epoch" +%Y-%m-%d)"
        # debug_string "compute_destination_directory()->year_month_day" "$year_month_day"
        dest_dir_ref+="${year_month_day}/"
        ;;
      "$GROUP_BY_DUPLICATES")
          # If fid is marked as duplicate and not preferred, append folder (single if)
          if [[ "${file_has_duplicates[$fid]}" -eq 1 && "${file_is_preferred_duplicate[$fid]}" != 1 ]]; then
            dest_dir_ref+="Duplicates/"
          fi
        ;;
      "$GROUP_BY_LIVE_PHOTO_MISSING_VIDEO_PAIR")
          # Ignore if there is a software name
          # This is for situations where live photos are sent
          # through primarily messaging apps.
          local software_name="${file_software_name["$fid"]}"
          if [[ -n "$software_name" ]]; then
            return
          fi

          # If fid is in live_photo_missing_video[cid], append folder
          local cid="${file_exif_cid["$fid"]}"
          if [[ -n "$cid" \
                && -n "${live_photo_missing_video[$cid]+set}" \
                && "${live_photo_missing_video[$cid]}" -eq 1 ]]; then
            dest_dir_ref+="Live Photo Missing Video Pair/"
          fi
        ;;
      "$GROUP_BY_LIVE_VIDEO_MISSING_PHOTO_PAIR")
          # If fid is in live_video_missing_photo[cid], append folder
          local cid="${file_exif_cid["$fid"]}"
          if [[ -n "$cid" \
                && -n "${live_video_missing_photo[$cid]+set}" \
                && "${live_video_missing_photo[$cid]}" -eq 1 ]]; then
            dest_dir_ref+="Live Video Missing Photo Pair/"
          fi
        ;;
    esac
  done
}

is_destination_usable() {
  local did="$1"
  local fid="$2"

  if [[ -z "${file_dest_entries["$did"]}" ]] || [[ "${file_dest_entries["$did"]}" == "$fid" ]]; then
    return 0  # true
  else
    return 1  # false
  fi
}

resolve_destination_naming_conflicts() {
  # Log the list of conflict groups
  __log_conflict_groups
  # debug_map "resolve_destination_naming_conflicts()->file_dest_conflicts" ${!file_dest_conflicts[@]} -- ${file_dest_conflicts[@]}

  # Go through all the conflict groups
  local index_groups=1
  local total_groups=${#file_dest_conflicts[@]}
  for did in "${!file_dest_conflicts[@]}"; do

    # Get list of fids that have a naming conflict for this destination
    local fids=(${file_dest_conflicts["$did"]//|/ })

    # Log the current progress
    log_plan_tree_start "Conflict Group $(progress "$index_groups" "$total_groups" "/"): \"$(parse_file_id "$did")\""
    log_plan_tree "Folder: ${file_dest_dir["${fids[0]}"]}"

    # Create fid_timestamp_pairs for sorting
    local fid_timestamp_pairs=()
    for fid in "${fids[@]}"; do
      fid_timestamp_pairs+=("${file_timestamp_epoch["$fid"]} $fid")
    done
    # debug_array "Pre-sorted timestamp pairs:" "${fid_timestamp_pairs[@]}"

    # Sort fids by their timestamp (earliest to latest)
    local fids_sorted=($( \
        printf '%s\n' "${fid_timestamp_pairs[@]}" \
        | sort -n \
        | awk '{print $2}' \
    ))
    # debug_array "Sorted fids:" "${fids_sorted[@]}"

    # Log the list of sorted conflict files
    __log_sorted_conflict_files

    # Add duplicate marker to the rest of the fids.
    local dupe_marker=0

    # Counters use for reporting progress
    local index_files=1;
    local total_files=${#fids_sorted[@]};

    for ((i=0; i<${#fids_sorted[@]}; i++)); do
      local fid="${fids_sorted[$i]}"

      # Get the old values
      local media_type="${file_media_type["$fid"]}"
      local src_dir="${file_src_dir["$fid"]}"
      local src_name="${file_src_name["$fid"]}"
      local src="${file_src["$fid"]}"
      local dest_compound_ext="${file_dest_compound_ext["$fid"]}"
      local dest_dupe_marker="${file_dest_dupe_marker["$fid"]}"
      local dest_root_stem="${file_dest_root_stem["$fid"]}"
      local dest_stem="${file_dest_stem["$fid"]}"
      local dest_name="${file_dest_name["$fid"]}"
      local dest_dir="${file_dest_dir["$fid"]}"
      local dest="${file_dest["$fid"]}"

      # If the conflict has already been handled, skip it.
      # This can happen if the file was already processed in a previous run,
      # e.g. when handling the live video counterpart of a live photo.
      if [[ "${file_dest_conflict_handled["$fid"]}" -eq 1 ]]; then
        # TODO: Test this and reword log.
        log_plan_tree "File ID ${fid} has already been handled. Skipping."
        break
      fi

      # Compute the new values
      local new_did \
        new_dest \
        new_dest_name \
        new_dest_stem \
        new_dest_dupe_marker

      while :; do
        # For the first file, no duplicate marker is needed.
        if [[ $dupe_marker -eq 0 ]]; then
          new_dest_dupe_marker=""
        # For subsequent files, set duplicate marker.
        else
          new_dest_dupe_marker="${dupe_marker}"
        fi

        # debug_string "resolve_destination_naming_conflict()->dupe_marker" "${dupe_marker}"
        # debug_string "resolve_destination_naming_conflict()->new_dest_dupe_marker" "${new_dest_dupe_marker}"
        # debug_string "resolve_destination_naming_conflict()->new_dest_stem" "${new_dest_stem}"

        # Compute the rest of the properties
        __compute_new_dest_properties

        # Set the earliest file found to the file_dest_entries
        if [[ $dupe_marker -eq 0 ]]; then
          file_dest_entries["$new_did"]="$fid"
        fi

        # Increment dupe marker for the next round
        (( dupe_marker++ ))

        case "$media_type" in
          # Special handling for live photos/videos
          # Both photo and video pairs should share the same stem
          "$MEDIA_TYPE_LIVE_PHOTO"|"$MEDIA_TYPE_LIVE_VIDEO")

            # Get live pair's properties
            local cid="${file_exif_cid["$fid"]}"
            local live_pair_fid
            if [ "$media_type" == "$MEDIA_TYPE_LIVE_PHOTO" ]; then
              live_pair_fid="${live_video_by_cid["$cid"]}"
            elif [ "$media_type" == "$MEDIA_TYPE_LIVE_VIDEO" ]; then
              live_pair_fid="${live_photo_by_cid["$cid"]}"
            fi
            local live_pair_src="${file_src["$live_pair_fid"]}"
            local live_pair_dest_name="${file_dest_name["$live_pair_fid"]}"
            local live_pair_compound_ext="${file_dest_compound_ext["$live_pair_fid"]}"

            # If the current dupe marker could not be used for the live pair,
            # we need to find an alternative dupe marker that will work.
            while :; do
              # Check if using the new dest stem is going to create a conflict
              local live_pair_new_dupe_marker="${new_dest_dupe_marker}"
              local live_pair_new_dest_stem="${new_dest_stem}"
              local live_pair_new_dest_name="${live_pair_new_dest_stem}${live_pair_compound_ext}"
              local live_pair_new_dest="${dest_dir}${live_pair_new_dest_name}"
              local live_pair_new_did="$(compute_file_id "${live_pair_new_dest^^}")"

              # debug_string "resolve_destination_naming_conflict()->live_pair_new_dupe_marker" "${live_pair_new_dupe_marker}"
              # debug_string "resolve_destination_naming_conflict()->live_pair_new_dest_stem" "${live_pair_new_dest_stem}"
              # debug_string "resolve_destination_naming_conflict()->live_pair_new_dest_name" "${live_pair_new_dest_name}"
              # debug_string "resolve_destination_naming_conflict()->live_pair_new_dest" "${live_pair_new_dest}"
              # debug_string "resolve_destination_naming_conflict()->live_pair_new_did" "${live_pair_new_did}"

              # If both filename and live pair filename has no conflicts, use them.
              if is_destination_usable "$new_did" "$fid" && \
                 is_destination_usable "$live_pair_new_did" "$live_pair_fid"; then
                __set_new_dest_values
                __set_new_live_pair_dest_values
                __log_conflict_resolution 1
                break
              else
                # Else, increment the dupe marker and try again.
                # Note: We are incrementing the $new_dest_dupe_marker internally
                #       without affecting the original $dupe_marker as we want to
                #       separate concerns between non-live and live media files.
                if [[ -z ${new_dest_dupe_marker} ]]; then
                  new_dest_dupe_marker=1
                else
                  new_dest_dupe_marker=$(( ${new_dest_dupe_marker} + 1 ))
                fi
                __compute_new_dest_properties
              fi
            done
            break
            ;;

          # Handling for other media types
          *)
            # If the filename does not have any conflicts, use it.
            if is_destination_usable "$new_did" "$fid"; then
              __set_new_dest_values
              __log_conflict_resolution
              break
            fi
            ;;
        esac
      done

      # Go to the next conflict file
      (( index_files++ ))
    done

    # End the log tree for conflict group
    log_plan_tree_end

    # Go to the next conflict group
    (( index_groups++ ))
  done
}

# Subroutine of resolve_destination_naming_conflicts()
__compute_new_dest_properties() {
  if [[ -z $new_dest_dupe_marker ]]; then
    new_dest_stem="${dest_root_stem}"
  else
    new_dest_stem="${dest_root_stem}(${new_dest_dupe_marker})"
  fi
  new_dest_name="${new_dest_stem}${dest_compound_ext}"
  new_dest="${dest_dir}${new_dest_name}"
  new_did="$(compute_file_id "${new_dest^^}")"
}

# Subroutine of resolve_destination_naming_conflicts()
__set_new_dest_values() {
  # Set new dest values
  file_dest_dupe_marker["$fid"]="$new_dest_dupe_marker"
  file_dest_stem["$fid"]="$new_dest_stem"
  file_dest_name["$fid"]="$new_dest_name"
  file_dest["$fid"]="${new_dest}"

  # Mark file has handled
  file_dest_conflict_handled["$fid"]=1

  # Add to file_dest_entries
  file_dest_entries["$new_did"]="$fid"
}

# Subroutine of resolve_destination_naming_conflicts()
__set_new_live_pair_dest_values() {
  # Set new dest values for the live pair
  file_dest_dupe_marker["$live_pair_fid"]="${live_pair_new_dupe_marker}"
  file_dest_stem["$live_pair_fid"]="${live_pair_new_dest_stem}"
  file_dest_name["$live_pair_fid"]="${live_pair_new_dest_name}"
  file_dest["$live_pair_fid"]="${live_pair_new_dest}"

  # Mark the live pair file as handled
  file_dest_conflict_handled["$live_pair_fid"]=1

  # Add live photo to file_dest_entries
  file_dest_entries["$live_pair_new_did"]="$live_pair_fid"
}

# Subroutine of resolve_destination_naming_conflicts()
__log_conflict_groups() {
  local index=1
  local total=${#file_dest_conflicts[@]}

  log_plan_tree_start "Found ${total} conflict groups."

  for did in "${!file_dest_conflicts[@]}"; do
    local count=$(IFS='|' read -ra arr <<< "${file_dest_conflicts["$did"]}"; echo "${#arr[@]}")
    local message="Conflict Group $(progress "$index" "$total" "/"): \"$(parse_file_id "$did")\" ($count conflicts)"

    if [[ $index -lt $total ]]; then
      log_plan_tree "${message}"
      (( index++ ))
    else
      log_plan_tree_end "${message}"
    fi
  done
}

# Subroutine of resolve_destination_naming_conflicts()
__log_sorted_conflict_files() {
  local i
  local total=${#fids_sorted[@]}

  log_plan_tree_start "Sorting conflicted files by timestamp:"

  for (( i=0; i<total; i++ )); do
    local fid="${fids_sorted[$i]}"
    local src="${file_src["$fid"]}"
    local message="Conflict File $(progress "$((i+1))" "$total" "/"): ${file_timestamp_epoch["$fid"]} ${src}"

    if (( i < total - 1 )); then
      log_plan_tree "${message}"
    else
      log_plan_tree_end "${message}"
    fi
  done
}

# Subroutine of resolve_destination_naming_conflicts()
__log_conflict_resolution() {
  local include_live_pair_summary="$1"
  local progress_label=$(progress "$index_files" "$total_files" "/")

  local resolution
  if [[ ${dest_name} == ${new_dest_name} ]]; then
    resolution="Retained"
  else
    resolution="Resolved"
  fi

  local log_plan_tree_xor="log_plan_tree_last"
  if [[ $include_live_pair_summary -eq 1 ]]; then
    log_plan_tree_xor="log_plan_tree_start"
  fi

  log_plan_tree_start "Conflict File ${progress_label}: ${src}"
  log_plan_tree         "Timestamp : ${file_timestamp["$fid"]} (${file_timestamp_epoch["$fid"]})"
  log_plan_tree         "Filename  : ${dest_name} (Conflicted) => ${new_dest_name} (Resolved)"
    $log_plan_tree_xor  "Filename Resolution"
    log_plan_tree         "Original: ${src_name}"
    log_plan_tree         "Wanted:   ${dest_name} (${total_files} conflicts)"
    log_plan_tree_end     "Final:    ${new_dest_name} (${resolution})"

  if [[ $include_live_pair_summary -eq 1 ]]; then
    local live_pair_resolution
    if [[ ${live_pair_dest_name} == ${live_pair_new_dest_name} ]]; then
      live_pair_resolution="Retained"
    else
      live_pair_resolution="Updated"
    fi

    log_plan_tree          "Live Pair Source: ${live_pair_src}"
    log_plan_tree_last     "Live Pair Filename Resolution"
      log_plan_tree          "Original: ${live_pair_dest_name}"
      log_plan_tree_end      "Final:    ${live_pair_new_dest_name} (${live_pair_resolution})"
  fi
  log_plan_tree_end
}

create_action_plan() {
  # TODO: Implement logic to create an action plan
}
