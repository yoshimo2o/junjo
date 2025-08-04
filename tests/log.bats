#!/usr/bin/env bats

# Test file for log.sh
# Tests basic logging functionality

setup() {
  # Source the required files
  source "$BATS_TEST_DIRNAME/../junjo.config"
  source "$BATS_TEST_DIRNAME/../lib/globals.sh"
  source "$BATS_TEST_DIRNAME/../lib/log.sh"

  # Set up test log directory
  export JUNJO_LOG_DIR="$BATS_TEST_TMPDIR"
  export JUNJO_LOG_VERBOSE=0

  # Initialize logging
  init_log
}

teardown() {
  # Clean up test files
  rm -f "$JUNJO_LOG_FILE" "$JUNJO_SCAN_LOG_FILE" "$JUNJO_SORT_LOG_FILE" 2>/dev/null || true

  # Reset log tree level
  log_tree_reset
}

@test "init_log creates log files" {
  # Debug: check variable values
  echo "JUNJO_LOG_DIR=$JUNJO_LOG_DIR" >&3
  echo "JUNJO_LOG_FILE_NAME=$JUNJO_LOG_FILE_NAME" >&3
  echo "JUNJO_LOG_FILE=$JUNJO_LOG_FILE" >&3

  run ls -la "$JUNJO_LOG_FILE"
  [ "$status" -eq 0 ]

  run ls -la "$JUNJO_SCAN_LOG_FILE"
  [ "$status" -eq 0 ]

  run ls -la "$JUNJO_SORT_LOG_FILE"
  [ "$status" -eq 0 ]
}

@test "log_raw writes to main log file without timestamp" {
  log_raw "Test message"

  run cat "$JUNJO_LOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test message"* ]]
  [[ "$output" != *"["* ]]  # No timestamp brackets
}

@test "log writes to correct log file with timestamp" {
  log "Test main message" "$MAIN_LOG"

  run cat "$JUNJO_LOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test main message"* ]]
  [[ "$output" == *"["*"]"* ]]  # Has timestamp brackets
}

@test "log_scan writes to scan log file" {
  log_scan "Test scan message"

  run cat "$JUNJO_SCAN_LOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test scan message"* ]]
  [[ "$output" == *"["*"]"* ]]  # Has timestamp
}

@test "log_sort writes to sort log file" {
  log_sort "Test sort message"

  run cat "$JUNJO_SORT_LOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test sort message"* ]]
  [[ "$output" == *"["*"]"* ]]  # Has timestamp
}

@test "log_timestamp generates timestamp format" {
  run log_timestamp
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]\ [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]$ ]]
}

@test "log_tree_indentation increases with level" {
  LOG_TREE_INDENT_LEVEL=0
  run log_tree_indentation
  [ "$status" -eq 0 ]
  [ "$output" = "" ]

  LOG_TREE_INDENT_LEVEL=1
  run log_tree_indentation
  [ "$status" -eq 0 ]
  [ "$output" = "│   " ]

  LOG_TREE_INDENT_LEVEL=2
  run log_tree_indentation
  [ "$status" -eq 0 ]
  [ "$output" = "│   │   " ]
}

@test "log_tree_reset sets indent level to zero" {
  LOG_TREE_INDENT_LEVEL=5
  log_tree_reset
  [ "$LOG_TREE_INDENT_LEVEL" -eq 0 ]
}

@test "log tree functions work with indentation" {
  # Start a tree section
  log_tree_start "Root item"
  [ "$LOG_TREE_INDENT_LEVEL" -eq 1 ]

  # Add tree items
  log_tree "Child item"

  # End tree section
  log_tree_end "End item"
  [ "$LOG_TREE_INDENT_LEVEL" -eq 0 ]

  # Check log file contains tree characters
  run cat "$JUNJO_LOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"├──"* ]]
  [[ "$output" == *"└──"* ]]
}
