#!/usr/bin/env bats
# Unit tests for stats module

setup() {
  # Load the stats module
  export BASE_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export LIB_DIR="$BASE_DIR/lib"

  # Source required modules
  source "$LIB_DIR/env.sh"
  source "$LIB_DIR/log.sh"
  source "$LIB_DIR/stats.sh"

  # Initialize environment
  nl_env_init
}

@test "stats counts total errors" {
  input="FILE test.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
ERR CONSECUTIVE_NEWLINES 11 1 consecutive newlines
FILE other.c STATUS OK"

  result=$(echo "$input" | nl_compute_stats)
  [[ "$result" =~ "TOTAL 2" ]]
}

@test "stats counts errors by type" {
  input="FILE test.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
ERR SPACE_TAB 8 3 space before tab
ERR CONSECUTIVE_NEWLINES 11 1 consecutive newlines"

  result=$(echo "$input" | nl_compute_stats)
  [[ "$result" =~ "TYPE SPACE_TAB 2" ]]
  [[ "$result" =~ "TYPE CONSECUTIVE_NEWLINES 1" ]]
}

@test "stats counts OK and error files" {
  input="FILE test1.c STATUS ERR
ERR SPACE_TAB 5 3 space before tab
FILE test2.c STATUS OK
FILE test3.c STATUS ERR
ERR CONSECUTIVE_NEWLINES 11 1 consecutive newlines
FILE test4.c STATUS OK"

  result=$(echo "$input" | nl_compute_stats)
  [[ "$result" =~ "OK_FILES 2" ]]
  [[ "$result" =~ "ERR_FILES 2" ]]
}

@test "stats handles no errors" {
  input="FILE test1.c STATUS OK
FILE test2.c STATUS OK"

  result=$(echo "$input" | nl_compute_stats)
  [[ "$result" =~ "TOTAL 0" ]]
  [[ "$result" =~ "OK_FILES 2" ]]
  [[ "$result" =~ "ERR_FILES 0" ]]
}
