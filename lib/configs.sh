# Scan configs
JUNJO_SCAN_DIR="./"
JUNJO_SCAN_RECURSIVE=0
JUNJO_IGNORE_FILES='*.json
*.txt
*.log'

# File parsing configs
readonly KNOWN_COMPOUND_EXTS=(
  ".HEIC.MOV"
  ".JPG.MOV"
  ".JPEG.MOV"
  ".HEIC.MP4"
  ".JPG.MP4"
  ".JPEG.MP4"
)

# Sort configs
JUNJO_OUTPUT_DIR="./output"
JUNJO_SORT_PLAN_FILE="junjo_sort_plan.map"

# Log configs
JUNJO_LOG_VERBOSE=0
JUNJO_LOG_DIR="./"
JUNJO_SCAN_LOG_FILE="junjo_scan.log"
JUNJO_SORT_LOG_FILE="junjo_sort.log"