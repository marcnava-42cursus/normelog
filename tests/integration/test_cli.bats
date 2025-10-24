#!/usr/bin/env bats
# Integration tests for CLI

setup() {
  export BASE_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export NORMELOG="$BASE_DIR/bin/normelog"
}

@test "normelog --version shows version" {
  run "$NORMELOG" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "normelog" ]]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "normelog --help shows help" {
  run "$NORMELOG" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "OPTIONS" ]]
}

@test "normelog accepts -a flag" {
  run "$NORMELOG" -a --version
  [ "$status" -eq 0 ]
}

@test "normelog accepts --json flag" {
  run "$NORMELOG" --json --version
  [ "$status" -eq 0 ]
}

@test "normelog accepts --debug flag" {
  run "$NORMELOG" --debug --version
  [ "$status" -eq 0 ]
}

@test "normelog accepts --no-update-check flag" {
  run "$NORMELOG" --no-update-check --version
  [ "$status" -eq 0 ]
}

@test "normelog accepts -C flag with directory" {
  run "$NORMELOG" -C /tmp --version
  [ "$status" -eq 0 ]
}

@test "normelog accepts type filter argument" {
  # This just tests parsing, not actual filtering
  run "$NORMELOG" SPACE_TAB --version
  [ "$status" -eq 0 ]
}

@test "normelog accepts exclusion type filter" {
  run "$NORMELOG" -SPACE_TAB --version
  [ "$status" -eq 0 ]
}
