# Global dummy variable for optional nameref parameters
declare -g ___

# Properties of each file keyed by file id (fid)
declare -A file_src
declare -A file_src_dir
declare -A file_src_name
declare -A file_src_stem
declare -A file_src_root_stem
declare -A file_src_ext
declare -A file_src_compound_ext
declare -A file_src_dupe_marker
declare -A file_src_create_date
declare -A file_src_modify_date
declare -A file_dest
declare -A file_dest_dir
declare -A file_dest_name
declare -A file_dest_stem
declare -A file_dest_root_stem
declare -A file_dest_ext
declare -A file_dest_compound_ext
declare -A file_dest_dupe_marker
declare -A file_dest_create_date
declare -A file_dest_modify_date
declare -A file_type

# Takeout metadata keyed by file id (fid)
declare -A file_takeout_meta_file
declare -A file_takeout_meta_file_name
declare -A file_takeout_meta_file_match_strategy # "direct", "truncation", "duplication"
declare -A file_takeout_photo_taken_time
declare -A file_takeout_geo_data
declare -A file_takeout_device_type # IOS_PHONE, IOS_TABLET, ANDROID_PHONE, ANDROID_TABLET
declare -A file_takeout_device_folder # "WhatsApp Images", "Photoshop Express", etc.
declare -A file_takeout_upload_origin # "mobile", "desktop", "web"

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

# Other file properties
declare -A file_timestamp
declare -A file_timestamp_source

# Device & software
declare -A file_device_name
declare -A file_software_name

# Duplicates
declare -A file_has_duplicates
declare -A file_duplicate_score
declare -A file_is_preferred_duplicate

# Naming conflicts
declare -A file_dest_has_naming_conflict # key: fid, val: 0|1
declare -A file_dest_entries             # key: did, val: fid
declare -A file_dest_conflicts           # key: did, val: fids (delimited by '|')

# Apple-specific properties
declare -A file_is_apple_media

# List of files by file type keyed by fid
declare -A apple_photo_files
declare -A apple_video_files
declare -A live_photo_files
declare -A live_video_files
declare -A regular_photo_files
declare -A regular_video_files
declare -A regular_image_files
declare -A screenshot_files
declare -A screen_recording_files
declare -A unknown_files

# List of live photo and video fids keyed by cid
declare -A live_photo_by_cid
declare -A live_video_by_cid
declare -A live_photo_missing_video
declare -A live_video_missing_photo
declare -A live_photo_duplicates
declare -A live_video_duplicates
