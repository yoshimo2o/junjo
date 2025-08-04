#!/usr/bin/env bats

# Load required libraries
load '../junjo.config'
load '../lib/parser_takeout.sh'

# Test direct match strategy
@test "locate_takeout_meta_file - direct match JPG" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-direct-match/IMG_9224.JPG"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-direct-match/IMG_9224.JPG.supplemental-metadata.json" ]
  [ "$result_meta_file_name" = "IMG_9224.JPG.supplemental-metadata.json" ]
  [ "$result_match_strategy" = "direct" ]
}

@test "locate_takeout_meta_file - direct match HEIC" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-direct-match/IMG_9087.HEIC"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-direct-match/IMG_9087.HEIC.supplemental-metadata.json" ]
  [ "$result_meta_file_name" = "IMG_9087.HEIC.supplemental-metadata.json" ]
  [ "$result_match_strategy" = "direct" ]
}

# Test duplication match strategy
@test "locate_takeout_meta_file - duplication match JPG" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-duplication-match/IMG_3238(1).JPG"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-duplication-match/IMG_3238.JPG.supplemental-metadata(1).json" ]
  [ "$result_meta_file_name" = "IMG_3238.JPG.supplemental-metadata(1).json" ]
  [ "$result_match_strategy" = "duplication" ]
}

# Test truncation match strategy
@test "locate_takeout_meta_file - compound extension truncated" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-truncation-match/170825_193248390692632_3881876_o.jpg"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-truncation-match/170825_193248390692632_3881876_o.jpg.supplemen.json" ]
  [ "$result_meta_file_name" = "170825_193248390692632_3881876_o.jpg.supplemen.json" ]
  [ "$result_match_strategy" = "truncation" ]
}

@test "locate_takeout_meta_file - another compound extension truncated" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-truncation-match/D2A4ADDE-D69E-44BC-8053-1FB1C199715A.jpg"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-truncation-match/D2A4ADDE-D69E-44BC-8053-1FB1C199715A.jpg.suppl.json" ]
  [ "$result_meta_file_name" = "D2A4ADDE-D69E-44BC-8053-1FB1C199715A.jpg.suppl.json" ]
  [ "$result_match_strategy" = "truncation" ]
}

@test "locate_takeout_meta_file - original extension dropped, filename truncated" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-truncation-match/78268A60-6FF5-48E4-B030-674024878FFF-16960-0000.png"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-truncation-match/78268A60-6FF5-48E4-B030-674024878FFF-16960-000.json" ]
  [ "$result_meta_file_name" = "78268A60-6FF5-48E4-B030-674024878FFF-16960-000.json" ]
  [ "$result_match_strategy" = "truncation" ]
}

@test "locate_takeout_meta_file - only extension replaced" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-truncation-match/7CE69B82-6FE1-4660-956C-369E24BF4936-14124-000.jpeg"

  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?

  [ "$exit_code" -eq 0 ]
  [ "$result_meta_file" = "samples/google-takeout-truncation-match/7CE69B82-6FE1-4660-956C-369E24BF4936-14124-000.json" ]
  [ "$result_meta_file_name" = "7CE69B82-6FE1-4660-956C-369E24BF4936-14124-000.json" ]
  [ "$result_match_strategy" = "truncation" ]
}

# Test no match scenarios
@test "locate_takeout_meta_file - no match found should return empty" {
  local result_meta_file result_meta_file_name result_match_strategy
  local sample_file="samples/google-takeout-no-match/DSC09311.JPG"

  set +e
  locate_takeout_meta_file "$sample_file" result_meta_file result_meta_file_name result_match_strategy
  local exit_code=$?
  set -e

  [ "$exit_code" -eq 1 ]
  [ -z "$result_meta_file" ]
  [ -z "$result_meta_file_name" ]
  [ -z "$result_match_strategy" ]
}