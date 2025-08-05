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
  local index=0
  local total=${#file_src[@]}

  for fid in "${!file_src[@]}"; do
    log_plan "[$(progress "$index" "$total" "/")] Computing destination for file: $media_file"

    compute_file_destination "$fid"

    log_plan_tree_start "Computed destination for file: $media_file"
      log_plan_tree     "Source      : ${file_src[$fid]}"
      log_plan_tree_end "Destination : ${file_dest[$fid]} $(\
        [[ ${file_dest_has_naming_conflict[$fid]} -eq 1 ]] \
          && echo ' (Has Conflict)')"
    index=$(($index + 1))
  done
}

compute_file_destination() {
  local fid="$1"
  local dest_dir \
    dest_name \
    dest_stem \
    dest_root_stem \
    dest_ext \
    dest_compound_ext \
    dest_dupe_marker

  # Compute destination components
  compute_file_destination_components "$fid" \
    dest \
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

  # Compute did (destination id)
  # Uppercase everything to ensure files with the same filenames
  # but with different cases are treated as the same
  # e.g. "IMG_1234.jpg" == "IMG_1234.JPG"
  local did="$(get_media_file_id "${dest^^}")"

  # If this is the initial file with this destination
  if [[ -z "$file_dest_entries["$did"]" ]]; then

    # Add this initial file file destination entries
    file_dest_entries["$did"]="$fid"

    # Mark this intiial file has having no naming conflict
    file_dest_has_naming_conflict["$fid"]=0
  else
    # If this is the first time a naming conflict
    # for this destination is detected
    if [[ -z "${file_dest_conflicts["$did"]}" ]]; then

      # Get the fid of the initial file that has this destination
      initial_fid=${file_dest_entries["$did"]}

      # Add the fid of that initial file to the conflict list
      file_dest_conflicts["$did"]="${initial_fid}"

      # Mark the initial file as having naming conflict
      file_dest_has_naming_conflict["$fid"]=1
    fi

    # Append the fid of the current file to the conflict list
    file_dest_conflicts["$did"]+="|${fid}"

    # Mark the current file as having naming conflict
    file_dest_has_naming_conflict["$fid"]=1
  fi
}

resolve_destination_naming_conflicts() {
  local index=0
  local total=${#file_dest_conflicts[@]}

  # Loop through all destination conflicts
  for did in "${!file_dest_conflicts[@]}"; do

    # Get list of fids that have a naming conflict for this destination
    local fids=(${file_dest_conflicts["$did"]//|/ })

    # Log the current progress
    local file_dest="${file_dest[${fids[0]}]}"
    log_plan_tree_start "[$(progress "$index" "$total" "/")] Resolving naming conflicts for destination: ${file_dest}"

    # Create fid_timestamp_pairs for sorting
    local fid_timestamp_pairs=()
    for fid in "${fids[@]}"; do
      fid_timestamp_pairs+=("${file_timestamp_epoch[$fid]} $fid")
    done
    [[ $DEBUG ]] && debug_array "Pre-sorted timestamp pairs:" "${fid_timestamp_pairs[@]}"

    # Sort fids by their timestamp (earliest to latest)
    local fids_sorted=($( \
        printf '%s\n' "${fid_timestamp_pairs[@]}" \
        | sort -n \
        | awk '{print $2}' \
    ))
    [[ $DEBUG ]] && debug_array "Sorted fids:" "${fids_sorted[@]}"

    # Add duplicate marker to the rest of the fids.
    # Starts with 0 because it will be incremented to 1 before use.
    local dupe_marker=0

    # We're starting with the second fid on the list,
    local index_fids=1;
    local total_fids=${#fids_sorted[@]};

    for ((i=0; i<${#fids_sorted[@]}; i++)); do
      local fid="${fids_sorted[i]}"

      # Get the old values
      local src_dir="${file_src_dir[$fid]}"
      local src_name="${file_src_name[$fid]}"
      local dest_compound_ext="${file_dest_compound_ext[$fid]}"
      local dest_dupe_marker="${file_dest_dupe_marker[$fid]}"
      local dest_root_stem="${file_dest_root_stem[$fid]}"
      local dest_stem="${file_dest_stem[$fid]}"
      local dest_name="${file_dest_name[$fid]}"
      local dest_dir="${file_dest_dir[$fid]}"
      local dest="${file_dest[$fid]}"

      if [[ $i -gt 0 ]]; then

        # Compute the new values
        local new_dest_dupe_marker \
          new_dest_stem \
          new_dest_name \
          new_dest \
          new_did

        while :; do
          # Create a new filename with an incremented duplicate marker
          (( $dupe_marker++ ))
          new_dest_dupe_marker="$dupe_marker"
          new_dest_stem="${dest_root_stem} ("$new_dest_dupe_marker")"
          new_dest_name="${new_dest_stem}${dest_compound_ext}"
          new_dest="${dest_dir}${new_dest_name}"

          # If the filename does not have any conflicts, use it.
          if [[ -z "${file_dest_entries["$new_did"]}" ]]; then
            break
          fi
        done

        # Set the new values
        file_dest_dupe_marker["$fid"]="$i"
        file_dest_stem["$fid"]="$new_dest_stem"
        file_dest_name["$fid"]="$new_dest_name"
      fi

      # Mark file has no longer in conflict
      file_dest_has_naming_conflict["$fid"]=0

      # Get total fids_sorted
      file_dest["$fid"]="$new_dest"
      new_did="$(get_media_file_id "${new_dest^^}")"

      local progress_label=$(progress "$index_fids" "$total_fids" "/")

      # Verbose log the resolution of the naming conflict
      log_plan_tree_start_ "Conflict details ${progress_label}:"
        log_plan_tree_     "Source Folder      : ${src_dir}"
        log_plan_tree_     "Source Filename    : ${src_name}"
        log_plan_tree_     "Destination Folder : ${dest_dir}"
        log_plan_tree_     "Conflict Filename  : ${dest_name}"
        log_plan_tree_end_ "Resolved Filename  : ${new_dest_name}"

      # If this is not the last file in the conflict list,
      # use log_plan_tree, else use log_plan_tree_end
      local message="Conflict resolution ${progress_label}: ${dest_name} => ${new_dest_name}"
      if [[ $i -lt $(( ${total_fids} - 1 )) ]]; then
        log_plan_tree "$message"
      else
        log_plan_tree_end "$message"
      fi

      (( index_fids++ ))
    done

    log_plan_tree_end
    (( index++ ))
  done
}

create_action_plan() {
  # TODO: Implement logic to create an action plan
}
