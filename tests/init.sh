# Set up JUNJO_LIB_DIR for the library files
export JUNJO_DIR="$BATS_TEST_DIRNAME/.."
export JUNJO_LIB_DIR="$JUNJO_DIR/lib"

# Load the library functions
source "$JUNJO_LIB_DIR/constants.sh"
source "$JUNJO_LIB_DIR/globals.sh"
source "$JUNJO_LIB_DIR/functions.sh"
source "$JUNJO_LIB_DIR/log.sh"
source "$JUNJO_LIB_DIR/debug.sh"
source "$JUNJO_LIB_DIR/controller.sh"
source "$JUNJO_LIB_DIR/media_scanner.sh"
source "$JUNJO_LIB_DIR/media_planner.sh"
source "$JUNJO_LIB_DIR/parser_file.sh"
source "$JUNJO_LIB_DIR/parser_takeout.sh"
source "$JUNJO_LIB_DIR/parser_exif.sh"
source "$JUNJO_LIB_DIR/parser_timestamp.sh"
source "$JUNJO_LIB_DIR/parser_device.sh"
source "$JUNJO_LIB_DIR/parser_software.sh"
source "$JUNJO_LIB_DIR/parser_live.sh"
source "$JUNJO_LIB_DIR/planner_destination.sh"
source "$JUNJO_LIB_DIR/planner_action.sh"
source "$JUNJO_DIR/config.defaults.ini"

# Check for required dependencies.
# If dependencies are missing, stop.
check_dependencies

# Init log.
# If unable to write logs, stop.
init_log || exit 1