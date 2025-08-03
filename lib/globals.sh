# Properties of each file keyed by file id (fid)
declare -A file_src
declare -A file_src_dir
declare -A file_src_name
declare -A file_src_stem
declare -A file_src_compound_ext
declare -A file_src_ext
declare -A file_src_root_stem
declare -A file_dest
declare -A file_dest_dir
declare -A file_dest_name
declare -A file_dest_stem
declare -A file_dest_compound_ext
declare -A file_dest_ext
declare -A file_type # See file_types for possible values
declare -A file_cid
declare -A file_make
declare -A file_model
declare -A file_timestamp
declare -A file_timestamp_source
declare -A file_device_name
declare -A file_takeout_meta_file
declare -A file_takeout_meta_file_name
declare -A file_takeout_meta_file_match_strategy
declare -A file_takeout_photo_taken_time
declare -A file_takeout_geo_data
declare -A file_takeout_device_type
declare -A file_takeout_device_folder
declare -A file_takeout_upload_origin
declare -A file_has_duplicates

# File types enumerations
declare -A file_types=(
  ["AP"]="Apple Photo"
  ["AV"]="Apple Video"
  ["LP"]="Apple Live Photo"
  ["LV"]="Apple Live Video"
  ["RP"]="Regular Photo"
  ["RV"]="Regular Video"
  ["RI"]="Regular Image"
  ["SS"]="Screenshot"
  ["SR"]="Screen Recording"
  ["?"]="Unknown"
)

# List of files by file type keyed by fid
declare -A apple_photo_files
declare -A apple_video_files
declare -A live_photo_files
declare -A live_video_files
declare -A regular_photo_files
declare -A regular_video_files

# List of live photo and video fids keyed by cid
declare -A live_photo_by_cid
declare -A live_video_by_cid
declare -A live_photo_dupes
declare -A live_video_dupes
declare -A live_photo_missing_video
declare -A live_video_missing_photo