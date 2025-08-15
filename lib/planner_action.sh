add_plan_action() {
  local fid="$1"
  local action="$2"

  # Add to the array of plans
  plans_fid+=("$fid")
  plans_action+=("$action")

  # Get the plans index of the item that was just added
  local index=$((${#plans_fid[@]} - 1));

  # Add or append the index to the plans
  plans_by_fid["$fid"]+="${plans_by_fid["$fid"]:+|}$index"
}

add_copy_file_action() {
  local fid="$1"

  if [[ "$JUNJO_FILE_OPERATION" != "$FILE_OPERATION_COPY" ]]; then
      return 1
  fi

  add_plan_action "$fid" "$ACTION_COPY_FILE"
}

add_move_file_action() {
  local fid="$1"

  if [[ "$JUNJO_FILE_OPERATION" != "$FILE_OPERATION_MOVE" ]]; then
      return 1
  fi

  add_plan_action "$fid" "$ACTION_MOVE_FILE"
}

add_set_timestamp_to_exif_action() {
  local fid="$1"

  if [[ "$JUNJO_SET_EXIF_TIMESTAMP" -eq 0 ]]; then
    return 1
  fi

  add_plan_action "$fid" "$ACTION_SET_EXIF_TIMESTAMP"
}

add_set_geodata_to_exif_action() {
  local fid="$1"

  if [[ "$JUNJO_SET_EXIF_GEODATA" -eq 0 ]]; then
    return 1
  fi

  add_plan_action "$fid" "$ACTION_SET_EXIF_GEODATA"
}

add_set_file_create_time_action() {
  local fid="$1"

  if [[ "$JUNJO_SET_FILE_CREATE_TIME" -eq 0 ]]; then
    return 1
  fi

  file_dest_create_date[$fid]="${file_timestamp["$fid"]}"
  add_plan_action "$fid" "$ACTION_SET_FILE_CREATE_TIME"
}

add_set_file_modify_time_action() {
  local fid="$1"

  if [[ "$JUNJO_SET_FILE_MODIFY_TIME" -eq 0 ]]; then
    return 1
  fi

  file_dest_modify_date[$fid]="${file_timestamp["$fid"]}"
  add_plan_action "$fid" "$ACTION_SET_FILE_MODIFY_TIME"
}