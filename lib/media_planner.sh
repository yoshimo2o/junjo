create_organizing_plan() {
  # Step 1: Pre-compute file destinations
  log "Pre-computing file destinations."
  if precompute_file_destinations; then
    log "Successfully pre-computed file destinations."
  else
    log "Failed to pre-compute file destinations."
    return 1
  fi

  # Step 2: Resolve naming conflicts in file destinations
  log "Resolving naming conflicts in file destinations."
  if resolve_destination_naming_conflicts; then
    log "Naming conflict resolution completed successfully."
  else
    log "Naming conflict resolution failed."
    return 1
  fi

  # Step 3: Create an action plan to organize the files
  log "Creating an action plan to organize the files."
  if create_action_plan; then
    log "Action plan creation completed successfully."
  else
    log "Action plan creation failed."
    return 1
  fi
}

precompute_file_destinations() {
  local fid="$1"
  local dest_dir \
    dest_name \
    dest_stem \
    dest_root_stem \
    dest_ext \
    dest_compound_ext \
    dest_dupe_marker

  compute_file_destination "$fid" \
    dest \
    dest_dir \
    dest_name \
    dest_stem \
    dest_root_stem \
    dest_ext \
    dest_compound_ext \
    dest_dupe_marker

  file_dest["$fid"]="$dest"
  file_dest_dir["$fid"]="$dest_dir"
  file_dest_name["$fid"]="$dest_name"
  file_dest_stem["$fid"]="$dest_stem"
  file_dest_root_stem["$fid"]="$dest_root_stem"
  file_dest_ext["$fid"]="$dest_ext"
  file_dest_compound_ext["$fid"]="$dest_compound_ext"
  file_dest_dupe_marker["$fid"]="$dest_dupe_marker"

  # Compute did (destination id)
  local did="$(get_media_file_id "$dest")"

  # If this destination path already has an entry,
  # mark it has having naming conflict,
  # to be resolved later.
  if [[ -z "$file_dest_entries["$did"]" ]]; then

    # Add to file dest entries
    file_dest_entries["$did"]="$fid"
    file_dest_has_naming_conflict["$fid"]=0
  else
    # If this is the first time a conflict is detected
    if [[ -z "${file_dest_conflicts["$did"]}" ]]; then

      # Get the initial fid
      initial_fid=${file_dest_entries["$did"]}

      # Add the initial fid to the conflict list
      file_dest_conflicts["$did"]="${initial_fid}"

      # Mark the initial fid as having naming conflict
      file_dest_has_naming_conflict["$did"]=1
    fi

    # Append the current fid to the conflict list
    file_dest_conflicts["$did"]+="|${fid}"

    # Mark the current fid as having naming conflict
    file_dest_has_naming_conflict["$fid"]=1
  fi
}

resolve_destination_naming_conflicts() {
  # TODO: Implement logic to resolve naming conflicts
}

create_action_plan() {
  # TODO: Implement logic to create an action plan
}
