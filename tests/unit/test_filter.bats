#!/usr/bin/env bats
# Unit tests for filter module

setup() {
  # Load the filter module
  export BASE_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export LIB_DIR="$BASE_DIR/lib"

  # Source required modules
  source "$LIB_DIR/env.sh"
  source "$LIB_DIR/log.sh"
  source "$LIB_DIR/flags.sh"
  source "$LIB_DIR/filter.sh"

  # Initialize environment
  nl_env_init
}

@test "filter includes specified error types" {
  NL_INCLUDE_TYPES=(SPACE_TAB)
  input="FILE test.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
ERR CONSECUTIVE_NEWLINES 11 1 consecutive newlines"

  result=$(echo "$input" | nl_filter_errors)
  [[ "$result" =~ "SPACE_TAB" ]]
  [[ ! "$result" =~ "CONSECUTIVE_NEWLINES" ]]
}

@test "filter excludes specified error types" {
  NL_EXCLUDE_TYPES=(SPACE_TAB)
  input="FILE test.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
ERR CONSECUTIVE_NEWLINES 11 1 consecutive newlines"

  result=$(echo "$input" | nl_filter_errors)
  [[ ! "$result" =~ "SPACE_TAB" ]]
  [[ "$result" =~ "CONSECUTIVE_NEWLINES" ]]
}

@test "filter passes all errors when no filters specified" {
  NL_INCLUDE_TYPES=()
  NL_EXCLUDE_TYPES=()
  input="FILE test.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
ERR CONSECUTIVE_NEWLINES 11 1 consecutive newlines"

  result=$(echo "$input" | nl_filter_errors)
  [[ "$result" =~ "SPACE_TAB" ]]
  [[ "$result" =~ "CONSECUTIVE_NEWLINES" ]]
}

@test "filter preserves FILE records" {
  NL_INCLUDE_TYPES=(SPACE_TAB)
  input="FILE test.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
FILE other.c STATUS OK"

  result=$(echo "$input" | nl_filter_errors)
  [[ "$result" =~ "FILE test.c STATUS ERR" ]]
  [[ "$result" =~ "FILE other.c STATUS OK" ]]
}
