# Media type constants
readonly MEDIA_TYPE_APPLE_PHOTO="AP"
readonly MEDIA_TYPE_APPLE_VIDEO="AV"
readonly MEDIA_TYPE_LIVE_PHOTO="LP"
readonly MEDIA_TYPE_LIVE_VIDEO="LV"
readonly MEDIA_TYPE_REGULAR_PHOTO="RP"
readonly MEDIA_TYPE_REGULAR_VIDEO="RV"
readonly MEDIA_TYPE_REGULAR_IMAGE="RI"
readonly MEDIA_TYPE_SCREENSHOT="SS"
readonly MEDIA_TYPE_SCREEN_RECORDING="SR"
readonly MEDIA_TYPE_UNKNOWN="?"

# Media types enumerations
declare -A media_types=(
  ["$MEDIA_TYPE_APPLE_PHOTO"]="Apple Photo"
  ["$MEDIA_TYPE_APPLE_VIDEO"]="Apple Video"
  ["$MEDIA_TYPE_LIVE_PHOTO"]="Apple Live Photo"
  ["$MEDIA_TYPE_LIVE_VIDEO"]="Apple Live Video"
  ["$MEDIA_TYPE_REGULAR_PHOTO"]="Regular Photo"
  ["$MEDIA_TYPE_REGULAR_VIDEO"]="Regular Video"
  ["$MEDIA_TYPE_REGULAR_IMAGE"]="Regular Image"
  ["$MEDIA_TYPE_SCREENSHOT"]="Screenshot"
  ["$MEDIA_TYPE_SCREEN_RECORDING"]="Screen Recording"
  ["$MEDIA_TYPE_UNKNOWN"]="Unknown"
)

# Directory grouping
readonly GROUP_BY_DEVICE="device"
readonly GROUP_BY_SOFTWARE="software"
readonly GROUP_BY_YEAR="year"
readonly GROUP_BY_MONTH="month"
readonly GROUP_BY_DAY="day"
readonly GROUP_BY_YEAR_MONTH="year_month"
readonly GROUP_BY_YEAR_MONTH_DAY="year_month_day"
readonly GROUP_BY_DUPLICATES="duplicates"
readonly GROUP_BY_LIVE_PHOTO_MISSING_VIDEO_PAIR="live_photo_missing_video_pair"
readonly GROUP_BY_LIVE_VIDEO_MISSING_PHOTO_PAIR="live_video_missing_photo_pair"

declare -A GROUPING_DESCRIPTIONS=(
  ["$GROUP_BY_DEVICE"]="Group by device: iPhone 13, Android, Desktop, etc. (if detected)"
  ["$GROUP_BY_SOFTWARE"]="Group by software: WhatsApp, Facebook, etc. (if detected)"
  ["$GROUP_BY_YEAR"]="Group by year: 2025, 2024, etc."
  ["$GROUP_BY_MONTH"]="Group by month: 08, 09, 10, 11, etc."
  ["$GROUP_BY_DAY"]="Group by day: 28, 29, 30, etc."
  ["$GROUP_BY_YEAR_MONTH"]="Group by YYYY-MM: 2025-11, 2017-18, etc."
  ["$GROUP_BY_YEAR_MONTH_DAY"]="Group by YYYY-MM-DD: 2025-11-30, 2017-08-02, etc."
  ["$GROUP_BY_DUPLICATES"]="Group by duplicates: Duplicates of IMG_3118.JPG, etc."
  ["$GROUP_BY_LIVE_PHOTO_MISSING_VIDEO_PAIR"]="Group by live photo missing video pair"
  ["$GROUP_BY_LIVE_VIDEO_MISSING_PHOTO_PAIR"]="Group by live video missing photo pair"
)

# Actions
readonly ACTION_COPY_FILE="copy"
readonly ACTION_MOVE_FILE="move"
readonly ACTION_SET_FILE_CREATE_TIME="set_file_create_time"
readonly ACTION_SET_FILE_MODIFY_TIME="set_file_modify_time"
readonly ACTION_SET_EXIF_TIME="set_exif_time"
readonly ACTION_SET_EXIF_GEODATA="set_exif_geodata"

# Operations
readonly FILE_OPERATION_COPY="copy"
readonly FILE_OPERATION_MOVE="move"
readonly FILE_OPERATION_REMOVE="remove"