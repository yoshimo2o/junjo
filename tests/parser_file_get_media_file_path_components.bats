#!/usr/bin/env bats

# Load required libraries
load '../lib/configs.sh'
load '../lib/parser_file.sh'

@test "parse simple JPG file" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_0001.JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "" ]
  [ "$name" = "IMG_0001.JPG" ]
  [ "$stem" = "IMG_0001" ]
  [ "$root_stem" = "IMG_0001" ]
  [ "$ext" = ".JPG" ]
  [ "$compound_ext" = ".JPG" ]
  [ "$dupe_marker" = "" ]
}

@test "parse compound extension HEIC.MOV" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_9999.HEIC.MOV" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "" ]
  [ "$name" = "IMG_9999.HEIC.MOV" ]
  [ "$stem" = "IMG_9999" ]
  [ "$root_stem" = "IMG_9999" ]
  [ "$ext" = ".MOV" ]
  [ "$compound_ext" = ".HEIC.MOV" ]
  [ "$dupe_marker" = "" ]
}

@test "parse file with duplicate marker" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234(1).JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "" ]
  [ "$name" = "IMG_1234(1).JPG" ]
  [ "$stem" = "IMG_1234(1)" ]
  [ "$root_stem" = "IMG_1234" ]
  [ "$ext" = ".JPG" ]
  [ "$compound_ext" = ".JPG" ]
  [ "$dupe_marker" = "1" ]
}

@test "parse compound extension with duplicate marker" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234(2).HEIC.MOV" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "" ]
  [ "$name" = "IMG_1234(2).HEIC.MOV" ]
  [ "$stem" = "IMG_1234(2)" ]
  [ "$root_stem" = "IMG_1234" ]
  [ "$ext" = ".MOV" ]
  [ "$compound_ext" = ".HEIC.MOV" ]
  [ "$dupe_marker" = "2" ]
}

@test "preserve intentional zero-padded numbers" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234(01).JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$stem" = "IMG_1234(01)" ]
  [ "$root_stem" = "IMG_1234(01)" ]  # Should NOT be stripped
  [ "$dupe_marker" = "" ]  # Should NOT be detected
}

@test "preserve intentional zero-padded numbers (009)" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234(009).JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$stem" = "IMG_1234(009)" ]
  [ "$root_stem" = "IMG_1234(009)" ]  # Should NOT be stripped
  [ "$dupe_marker" = "" ]  # Should NOT be detected
}

@test "handle relative path with dot" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "./IMG_1234.JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "./" ]
  [ "$name" = "IMG_1234.JPG" ]
}

@test "handle relative path without dot" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "photos/IMG_1234.JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "photos/" ]
  [ "$name" = "IMG_1234.JPG" ]
}

@test "handle absolute path" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "/Users/test/photos/IMG_1234.JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "/Users/test/photos/" ]
  [ "$name" = "IMG_1234.JPG" ]
}

@test "handle nested relative path" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "./2023/vacation/IMG_1234.JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$dir" = "./2023/vacation/" ]
  [ "$name" = "IMG_1234.JPG" ]
}

@test "preserve case in extensions" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234.heic.mov" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$ext" = ".mov" ]
  [ "$compound_ext" = ".heic.mov" ]  # Original case preserved
}

@test "handle spaces in filenames" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG 1234 (1).JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$stem" = "IMG 1234 (1)" ]
  [ "$root_stem" = "IMG 1234" ]
  [ "$dupe_marker" = "1" ]
}

@test "handle double-digit duplicate markers" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234(15).JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$stem" = "IMG_1234(15)" ]
  [ "$root_stem" = "IMG_1234" ]
  [ "$dupe_marker" = "15" ]
}

@test "handle JPG.MP4 compound extension" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234.JPG.MP4" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$ext" = ".MP4" ]
  [ "$compound_ext" = ".JPG.MP4" ]
}

@test "handle mixed case compound extensions" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234.Jpeg.Mp4" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$ext" = ".Mp4" ]
  [ "$compound_ext" = ".Jpeg.Mp4" ]  # Case preserved
}

@test "no duplicate marker for zero" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234(0).JPG" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$root_stem" = "IMG_1234(0)" ]  # Should NOT be stripped
  [ "$dupe_marker" = "" ]  # Should NOT be detected
}

@test "handle file with no extension" {
  local dir name stem root_stem ext compound_ext dupe_marker

  get_media_file_path_components "IMG_1234" \
    dir name stem root_stem ext compound_ext dupe_marker

  [ "$name" = "IMG_1234" ]
  [ "$stem" = "IMG_1234" ]
  [ "$ext" = "" ]
  [ "$compound_ext" = "" ]
}
