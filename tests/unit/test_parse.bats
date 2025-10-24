#!/usr/bin/env bats
# Unit tests for parsing module

setup() {
  # Load the parse module
  export BASE_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export LIB_DIR="$BASE_DIR/lib"

  # Source required modules
  source "$LIB_DIR/env.sh"
  source "$LIB_DIR/log.sh"
  source "$LIB_DIR/parse.sh"

  # Initialize environment
  nl_env_init
}

@test "parse handles OK status" {
  result=$(echo "test.c: OK!" | nl_parse_output)
  [[ "$result" =~ "FILE test.c STATUS OK" ]]
}

@test "parse extracts error details from SPACE_TAB" {
  input="Error: SPACE_TAB    (line:   5, col:   3):	space before tab"
  result=$(echo "$input" | nl_parse_output)
  [[ "$result" =~ "ERR SPACE_TAB 5 3" ]]
}

@test "parse extracts error details from CONSECUTIVE_NEWLINES" {
  input="Error: CONSECUTIVE_NEWLINES	(line:  11, col:   1):	consecutive newlines"
  result=$(echo "$input" | nl_parse_output)
  [[ "$result" =~ "ERR CONSECUTIVE_NEWLINES 11 1" ]]
}

@test "parse handles multiple errors" {
  input="sample.c
Error: SPACE_TAB    (line:   5, col:   3):	space before tab
Error: CONSECUTIVE_NEWLINES	(line:  11, col:   1):	consecutive newlines
sample.c: KO!"
  result=$(echo "$input" | nl_parse_output)
  [[ "$result" =~ "FILE sample.c STATUS ERR" ]]
  [[ "$result" =~ "ERR SPACE_TAB 5 3" ]]
  [[ "$result" =~ "ERR CONSECUTIVE_NEWLINES 11 1" ]]
}

@test "parse handles mixed OK and error files" {
  input="file1.c: OK!
file2.c
Error: SPACE_TAB    (line:   5, col:   3):	space before tab
file2.c: KO!
file3.c: OK!"
  result=$(echo "$input" | nl_parse_output)
  [[ "$result" =~ "FILE file1.c STATUS OK" ]]
  [[ "$result" =~ "FILE file2.c STATUS ERR" ]]
  [[ "$result" =~ "FILE file3.c STATUS OK" ]]
}
