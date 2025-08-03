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
declare -A file_type

# File type constants
readonly FILE_TYPE_APPLE_PHOTO="AP"
readonly FILE_TYPE_APPLE_VIDEO="AV"
readonly FILE_TYPE_LIVE_PHOTO="LP"
readonly FILE_TYPE_LIVE_VIDEO="LV"
readonly FILE_TYPE_REGULAR_PHOTO="RP"
readonly FILE_TYPE_REGULAR_VIDEO="RV"
readonly FILE_TYPE_REGULAR_IMAGE="RI"
readonly FILE_TYPE_SCREENSHOT="SS"
readonly FILE_TYPE_SCREEN_RECORDING="SR"
readonly FILE_TYPE_UNKNOWN="?"

# File types enumerations
declare -A file_types=(
  ["$FILE_TYPE_APPLE_PHOTO"]="Apple Photo"
  ["$FILE_TYPE_APPLE_VIDEO"]="Apple Video"
  ["$FILE_TYPE_LIVE_PHOTO"]="Apple Live Photo"
  ["$FILE_TYPE_LIVE_VIDEO"]="Apple Live Video"
  ["$FILE_TYPE_REGULAR_PHOTO"]="Regular Photo"
  ["$FILE_TYPE_REGULAR_VIDEO"]="Regular Video"
  ["$FILE_TYPE_REGULAR_IMAGE"]="Regular Image"
  ["$FILE_TYPE_SCREENSHOT"]="Screenshot"
  ["$FILE_TYPE_SCREEN_RECORDING"]="Screen Recording"
  ["$FILE_TYPE_UNKNOWN"]="Unknown"
)

# Takeout metadata keyed by file id (fid)
declare -A file_takeout_meta_file
declare -A file_takeout_meta_file_name
declare -A file_takeout_meta_file_match_strategy
declare -A file_takeout_photo_taken_time
declare -A file_takeout_geo_data
declare -A file_takeout_device_type
declare -A file_takeout_device_folder
declare -A file_takeout_upload_origin
declare -A file_has_duplicates

# Exif metadata keyed by file id (fid)
declare -A file_exif_cid
declare -A file_exif_make
declare -A file_exif_model
declare -A file_exif_lens_make
declare -A file_exif_lens_model
declare -A file_exif_image_width
declare -A file_exif_image_height
declare -A file_exif_image_size
declare -A file_exif_date_time_original
declare -A file_exif_create_date
declare -A file_exif_track_create_date
declare -A file_exif_media_create_date
declare -A file_exif_user_comment

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