
# ====================================================================================================
# process_live_media
#
# Main orchestration function for processing live media files (Live Photos and their
# corresponding videos). Handles duplicate detection, scoring, and identifies missing
# components of Live Photo pairs.
#
# This function performs the following operations in sequence:
#   1. Process all live photos and group by content ID
#   2. Process all live videos and group by content ID
#   3. Determine the best duplicate candidate for live photos
#   4. Determine the best duplicate candidate for live videos
#   5. Find live photos that are missing their video pair
#   6. Find live videos that are missing their photo pair
#
# Example usage:
#   process_live_media
# ====================================================================================================

process_live_media() {
  process_live_photos
  process_live_videos
  determine_best_live_photo_duplicate_candidate
  determine_best_live_video_duplicate_candidate
  find_live_photo_missing_video
  find_live_video_missing_photo
}

# ====================================================================================================
# process_live_photos
#
# Processes all live photo files by grouping them by content ID (CID) and detecting
# duplicates. For each live photo file, determines if it's the first occurrence for
# its CID or a duplicate.
#
# Uses the following global arrays:
#   - live_photo_files[@]    → Array of file IDs for live photos
#   - file_src[@]            → Array mapping file IDs to source file paths
#   - file_cid[@]            → Array mapping file IDs to content IDs
#   - live_photo_by_cid[@]   → Array mapping CIDs to the first live photo file ID
#
# Calls add_to_live_photo_duplicates() when duplicates are found.
#
# Example usage:
#   process_live_photos
# ====================================================================================================

process_live_photos() {
  local index=1
  local total=${#live_photo_files[@]}
  if (( total == 0 )); then
    log "No live photos found."
    return
  fi

  # Show a log informing users that we are processing the X amount of live photos.
  log "Processing $total live photos."

  for fid in "${!live_photo_files[@]}"; do
    local media_file="${file_src[$fid]}"
    local cid="${file_exif_cid[$fid]}"

    log "[$(progress "$index" "$total" "/")] Processing live photo: $media_file"

    log_scan_tree_start "File: $media_file"
      log_scan_tree "FID: $fid"
      log_scan_tree "CID: $cid"

    # If this is the first time we've found a live photo for this CID, store its fid.
    if [[ -z "${live_photo_by_cid[$cid]}" ]]; then
      live_photo_by_cid[$cid]=$fid
      log_scan_tree_end "Duplicate: No"
    else
      # If we already have a live photo for this CID, add to duplicates.
      add_to_live_photo_duplicates "$cid" "$fid"
      log_scan_tree_end "Duplicate: Yes"
    fi

    index=$((index + 1))
  done
}

# ====================================================================================================
# process_live_videos
#
# Processes all live video files by grouping them by content ID (CID) and detecting
# duplicates. For each live video file, determines if it's the first occurrence for
# its CID or a duplicate.
#
# Uses the following global arrays:
#   - live_video_files[@]    → Array of file IDs for live videos
#   - file_src[@]            → Array mapping file IDs to source file paths
#   - file_cid[@]            → Array mapping file IDs to content IDs
#   - live_video_by_cid[@]   → Array mapping CIDs to the first live video file ID
#
# Calls add_to_live_video_duplicates() when duplicates are found.
#
# Example usage:
#   process_live_videos
# ====================================================================================================

process_live_videos() {
  local index=1
  local total=${#live_video_files[@]}
  if (( total == 0 )); then
    log "No live videos found."
    return
  fi

  # Show a log informing users that we are processing the X amount of live photos.
  log "Processing $total live videos."

  for fid in "${!live_video_files[@]}"; do
    local media_file="${file_src[$fid]}"
    local cid="${file_exif_cid[$fid]}"

    log "[$(progress "$index" "$total" "/")] Processing live video: $media_file"

    log_scan_tree_start "File: $media_file"
      log_scan_tree "FID: $fid"
      log_scan_tree "CID: $cid"

    # If this is the first time we've found a live video for this CID, store its fid.
    if [[ -z "${live_video_by_cid[$cid]}" ]]; then
      live_video_by_cid[$cid]=$fid
      log_scan_tree_end "Duplicate: No"
    else
      # If we already have a live video for this CID, add to duplicates.
      add_to_live_video_duplicates "$cid" "$fid"
      log_scan_tree_end "Duplicate: Yes"
    fi

    index=$((index + 1))
  done
}

# ====================================================================================================
# add_to_live_photo_duplicates <cid> <fid>
#
# Adds a live photo file to the duplicates tracking system for a given content ID.
# When the first duplicate is found, also handles marking the previously found
# "first" file as having duplicates and sets it as the preferred duplicate.
#
# Parameters:
#   1. cid → Content ID for the live photo
#   2. fid → File ID of the duplicate live photo
#
# Updates the following global arrays:
#   - live_photo_duplicates[@]        → Pipe-separated list of duplicate file IDs per CID
#   - file_has_duplicates[@]          → Marks files as having duplicates
#   - file_is_preferred_duplicate[@]  → Marks files as preferred duplicates
#
# Example usage:
#   add_to_live_photo_duplicates "content_id_123" "file_id_456"
# ====================================================================================================

add_to_live_photo_duplicates() {
  local cid="$1"
  local fid="$2"

  # If the CID already exists in live_photo_duplicates, append the fid.
  if [[ -n "${live_photo_duplicates[$cid]}" ]]; then
    live_photo_duplicates[$cid]+="|$fid"

  else
    # If this is the first time we've found a duplicate for this CID,
    # handle also the first found live photo.

    # Get the first live photo fid for this CID
    local first_live_photo_fid="${live_photo_by_cid[$cid]}"

    # Add both the first found file and the new duplicate to the duplicates list
    live_photo_duplicates[$cid]="$first_live_photo_fid|$fid"

    file_has_duplicates["$first_live_photo_fid"]=1

    # Mark the first found file as preferred duplicate (initially)
    file_is_preferred_duplicate["$first_live_photo_fid"]=1
  fi

  # Mark file as having duplicates
  file_has_duplicates["$fid"]=1
}

# ====================================================================================================
# add_to_live_video_duplicates <cid> <fid>
#
# Adds a live video file to the duplicates tracking system for a given content ID.
# When the first duplicate is found, also handles marking the previously found
# "first" file as having duplicates and sets it as the preferred duplicate.
#
# Parameters:
#   1. cid → Content ID for the live video
#   2. fid → File ID of the duplicate live video
#
# Updates the following global arrays:
#   - live_video_duplicates[@]        → Pipe-separated list of duplicate file IDs per CID
#   - file_has_duplicates[@]          → Marks files as having duplicates
#   - file_is_preferred_duplicate[@]  → Marks files as preferred duplicates
#
# Example usage:
#   add_to_live_video_duplicates "content_id_123" "file_id_456"
# ====================================================================================================

add_to_live_video_duplicates() {
  local cid="$1"
  local fid="$2"

  # If the CID already exists in live_video_duplicates, append the fid.
  if [[ -n "${live_video_duplicates[$cid]}" ]]; then
    live_video_duplicates[$cid]+="|$fid"

  else
    # If this is the first time we've found a duplicate for this CID,
    # handle also the first found live video.

    # Get the first live video fid for this CID
    local first_live_video_fid="${live_video_by_cid[$cid]}"

    # Add both the first found file and the new duplicate to the duplicates list
    live_video_duplicates[$cid]="$first_live_video_fid|$fid"

    file_has_duplicates["$first_live_video_fid"]=1

    # Mark the first found file as preferred duplicate (initially)
    file_is_preferred_duplicate["$first_live_video_fid"]=1
  fi

  # Mark file as having duplicates
  file_has_duplicates["$fid"]=1
}

# ====================================================================================================
# determine_best_live_photo_duplicate_candidate
#
# Analyzes all live photo duplicates and determines the best candidate for each
# content ID based on a scoring system. Updates the preferred duplicate markers
# to reflect the highest-scoring file.
#
# Scoring criteria:
#   - Has takeout metadata: +100 points
#   - Filename starts with "IMG": +100 points
#   - Has duplicate marker: -N points (where N is the marker value)
#
# Updates the following global arrays:
#   - file_duplicate_score[@]           → Stores calculated scores for each file
#   - live_photo_by_cid[@]              → Updates to point to best duplicate per CID
#   - file_is_preferred_duplicate[@]    → Updates preferred duplicate markers
#
# Example usage:
#   determine_best_live_photo_duplicate_candidate
# ====================================================================================================

determine_best_live_photo_duplicate_candidate() {

  log "Determining best live photo duplicate candidates."

  # Go through each CID in live_photo_duplicates
  for cid in "${!live_photo_duplicates[@]}"; do

    # Split the fids into an array
    IFS='|' read -r -a fids <<< "${live_photo_duplicates[$cid]}"

    local index=1
    local total=${#fids[@]}

    log "Processing CID: $cid with $total live photo duplicates."

    # Go through each of the fids and score the quality of the live photo
    local best_fid=""
    log_scan_tree_start "CID: $cid"
    for fid in "${fids[@]}"; do

      local score=0

      log_scan_tree_start "[$(progress "$index" "$total" "/")] Scoring live photo duplicate: ${file_src[$fid]}"

      # If this file has takeout metadata, increase the score.
      if [[ -n "${file_takeout_meta_file[$fid]}" ]]; then
        score=$((score + 100))
        log_scan_tree "Has Takeout metadata: +100"
      fi

      # If this file's filename starts with "IMG", increase the score.
      if [[ "${file_src_root_stem[$fid]}" =~ ^IMG ]]; then
        score=$((score + 100))
        log_scan_tree "Filename starts with IMG: +100"
      fi

      # If this file's filename has duplicate marker, decrease the score
      # by the value of the dupe marker.
      if [[ ${file_src_dupe_marker[$fid]} > 0 ]]; then
        local -i dupe_marker="${file_src_dupe_marker[$fid]}"
        score=$((score - dupe_marker))
        log_scan_tree "Has duplicate marker: -$dupe_marker"
      fi

      log_scan_tree_end "Final Score: $score"

      # Assign the score
      file_duplicate_score[$fid]=$score

      # If this is the first fid, set it as the best_fid
      if [[ -z "$best_fid" ]]; then
        best_fid="$fid"
      fi

      # If the current fid's score is higher than the best_fid's score, update
      if [[ $score -gt ${file_duplicate_score[$best_fid]} ]]; then
        best_fid="$fid"
      fi

      index=$((index + 1))
    done
    log_scan_tree_end "Best candidate: ${file_src[$best_fid]} (Score: ${file_duplicate_score[$best_fid]})"

    # After scoring all duplicates, update the mappings to point to the best candidate
    # Remove the current preferred fid duplicate marker (the old primary)
    local current_primary_fid="${live_photo_by_cid[$cid]}"
    file_is_preferred_duplicate["$current_primary_fid"]=0

    # Update the main mapping to point to the best duplicate
    live_photo_by_cid[$cid]=$best_fid

    # Set the best fid as preferred duplicate
    file_is_preferred_duplicate["$best_fid"]=1

    log "Best candidate: ${file_src[$best_fid]} (Score: ${file_duplicate_score[$best_fid]})"
  done
}

# ====================================================================================================
# determine_best_live_video_duplicate_candidate
#
# Analyzes all live video duplicates and determines the best candidate for each
# content ID based on a scoring system. Updates the preferred duplicate markers
# to reflect the highest-scoring file.
#
# Scoring criteria:
#   - Filename starts with "IMG": +100 points
#   - Has duplicate marker: -N points (where N is the marker value)
#
# Note: Live videos do not have takeout metadata, so that criterion is not applied.
#
# Updates the following global arrays:
#   - file_duplicate_score[@]           → Stores calculated scores for each file
#   - live_video_by_cid[@]              → Updates to point to best duplicate per CID
#   - file_is_preferred_duplicate[@]    → Updates preferred duplicate markers
#
# Example usage:
#   determine_best_live_video_duplicate_candidate
# ====================================================================================================

determine_best_live_video_duplicate_candidate() {

  log "Determining best live video duplicate candidates."

  # Go through each CID in live_video_duplicates
  for cid in "${!live_video_duplicates[@]}"; do

    # Split the fids into an array
    IFS='|' read -r -a fids <<< "${live_video_duplicates[$cid]}"

    local index=1
    local total=${#fids[@]}

    log "Processing CID: $cid with $total live video duplicates."

    # Go through each of the fids and score the quality of the live video
    local best_fid=""
    log_scan_tree_start "CID: $cid"
    for fid in "${fids[@]}"; do

      local score=0

      log_scan_tree_start "[$(progress "$index" "$total" "/")] Scoring live photo duplicate: ${file_src[$fid]}"

      # Note: Live video has no takeout metadata.

      # If this file's filename starts with "IMG", increase the score.
      if [[ "${file_src_root_stem[$fid]}" =~ ^IMG ]]; then
        score=$((score + 100))
        log_scan_tree "Filename starts with IMG: +100"
      fi

      # If this file's filename has duplicate marker, decrease the score
      # by the value of the dupe marker.
      if [[ ${file_src_dupe_marker[$fid]} > 0 ]]; then
        local -i dupe_marker="${file_src_dupe_marker[$fid]}"
        score=$((score - dupe_marker))
        log_scan_tree "Has duplicate marker: -$dupe_marker"
      fi

      log_scan_tree_end "Final Score: $score"

      # Assign the score
      file_duplicate_score[$fid]=$score

      # If this is the first fid, set it as the best_fid
      if [[ -z "$best_fid" ]]; then
        best_fid="$fid"
      fi

      # If the current fid's score is higher than the best_fid's score, update
      if [[ $score -gt ${file_duplicate_score[$best_fid]} ]]; then
        best_fid="$fid"
      fi

      index=$((index + 1))
    done
    log_scan_tree_end "Best candidate: ${file_src[$best_fid]} (Score: ${file_duplicate_score[$best_fid]})"

    # After scoring all duplicates, update the mappings to point to the best candidate
    # Remove the current preferred fid duplicate marker (the old primary)
    local current_primary_fid="${live_video_by_cid[$cid]}"
    file_is_preferred_duplicate["$current_primary_fid"]=0

    # Update the main mapping to point to the best duplicate
    live_video_by_cid[$cid]=$best_fid

    # Set the best fid as preferred duplicate
    file_is_preferred_duplicate["$best_fid"]=1

    log "Best candidate: ${file_src[$best_fid]} (Score: ${file_duplicate_score[$best_fid]})"
  done
}

# ====================================================================================================
# find_live_photo_missing_video
#
# Identifies live photos that are missing their corresponding video component.
# A live photo is considered missing its video if there's no live video with
# the same content ID.
#
# Uses the following global arrays:
#   - live_photo_by_cid[@]        → Maps CIDs to live photo file IDs
#   - live_video_by_cid[@]        → Maps CIDs to live video file IDs
#   - live_photo_missing_video[@] → Marks CIDs where live photos have missing videos
#
# Example usage:
#   find_live_photo_missing_video
# ====================================================================================================

find_live_photo_missing_video() {
  log "Identifying live photos with missing video pair."
  for cid in "${!live_photo_by_cid[@]}"; do
    if [[ -z "${live_video_by_cid[$cid]}" ]]; then
      live_photo_missing_video[$cid]=1
      log_scan_tree_start "CID: $cid"
        log_scan_tree "File: ${live_photo_by_cid[$cid]}"
        log_scan_tree_end "Missing Video Pair: Yes"
      log "Live photo missing video pair: ${file_src[${live_photo_by_cid[$cid]}]} (CID: $cid)"
    fi
  done
  log_scan "Total live photos missing video pairs: ${#live_photo_missing_video[@]}"
}

# ====================================================================================================
# find_live_video_missing_photo
#
# Identifies live videos that are missing their corresponding photo component.
# A live video is considered missing its photo if there's no live photo with
# the same content ID.
#
# Uses the following global arrays:
#   - live_video_by_cid[@]        → Maps CIDs to live video file IDs
#   - live_photo_by_cid[@]        → Maps CIDs to live photo file IDs
#   - live_video_missing_photo[@] → Marks CIDs where live videos have missing photos
#
# Example usage:
#   find_live_video_missing_photo
# ====================================================================================================

find_live_video_missing_photo() {
  log "Identifying live videos with missing photo pair."
  for cid in "${!live_video_by_cid[@]}"; do
    if [[ -z "${live_photo_by_cid[$cid]}" ]]; then
      live_video_missing_photo[$cid]=1
      log_scan_tree_start "CID: $cid"
        log_scan_tree "File: ${live_video_by_cid[$cid]}"
        log_scan_tree_end "Missing Photo Pair: Yes"
      log "Live video missing photo pair: ${file_src[${live_video_by_cid[$cid]}]} (CID: $cid)"
    fi
  done
  log_scan "Total live videos missing photo pairs: ${#live_video_missing_photo[@]}"
}