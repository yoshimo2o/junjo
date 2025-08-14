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

# Directory grouping
readonly GROUP_BY_DEVICE="device"
readonly GROUP_BY_SOFTWARE="software"
readonly GROUP_BY_YEAR="year"
readonly GROUP_BY_MONTH="month"
readonly GROUP_BY_DAY="day"
readonly GROUP_BY_YEAR_MONTH="year_month"
readonly GROUP_BY_YEAR_MONTH_DAY="year_month_day"
readonly GROUP_BY_LIVE_PHOTO_MISSING_VIDEO_PAIR="live_photo_missing_video_pair"
readonly GROUP_BY_LIVE_VIDEO_MISSING_PHOTO_PAIR="live_video_missing_photo_pair"

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