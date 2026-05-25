#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TMP"

    cat > "$TMP/linters.md" <<'MD'
| Extension | Linter |
|-----------|--------|
| `.sh` | shellcheck |
| `.nix` | statix |
| `.md` | markdownlint |
MD

    mkdir -p "$TMP/src"
    touch "$TMP/src/main.sh" "$TMP/src/config.nix" "$TMP/README.md"
}

@test "fails when LEFTHOOK_LINTER_COVERAGE_DOC not set" {
    cd "$TMP"
    unset LEFTHOOK_LINTER_COVERAGE_DOC
    LEFTHOOK_LINTER_COVERAGE_ROOT="$TMP" run lefthook-linter-coverage-full
    assert_failure
    assert_output --partial "LEFTHOOK_LINTER_COVERAGE_DOC not set"
}

@test "fails when doc file missing" {
    cd "$TMP"
    LEFTHOOK_LINTER_COVERAGE_DOC="nonexistent.md" \
    LEFTHOOK_LINTER_COVERAGE_ROOT="$TMP" \
    run lefthook-linter-coverage-full
    assert_failure
    assert_output --partial "missing"
}

@test "passes when all extensions covered" {
    cd "$TMP"
    LEFTHOOK_LINTER_COVERAGE_DOC="linters.md" \
    LEFTHOOK_LINTER_COVERAGE_ROOT="$TMP" \
    run lefthook-linter-coverage-full
    assert_success
}

@test "fails when extension not listed" {
    cd "$TMP"
    touch "$TMP/data.json"
    LEFTHOOK_LINTER_COVERAGE_DOC="linters.md" \
    LEFTHOOK_LINTER_COVERAGE_ROOT="$TMP" \
    run lefthook-linter-coverage-full
    assert_failure
    assert_output --partial ".json"
}

@test "handles multiple extensions in one table cell" {
    cd "$TMP"
    cat > "$TMP/linters.md" <<'MD'
| Extension | Linter |
|-----------|--------|
| `.sh`, `.bats` | shellcheck |
| `.nix` | statix |
| `.md` | markdownlint |
MD
    touch "$TMP/test.bats"
    LEFTHOOK_LINTER_COVERAGE_DOC="linters.md" \
    LEFTHOOK_LINTER_COVERAGE_ROOT="$TMP" \
    run lefthook-linter-coverage-full
    assert_success
}

@test "handles extensionless files like justfile" {
    cd "$TMP"
    cat > "$TMP/linters.md" <<'MD'
| Extension | Linter |
|-----------|--------|
| `.sh` | shellcheck |
| `.nix` | statix |
| `.md` | markdownlint |
| `justfile` | custom |
MD
    touch "$TMP/justfile"
    LEFTHOOK_LINTER_COVERAGE_DOC="linters.md" \
    LEFTHOOK_LINTER_COVERAGE_ROOT="$TMP" \
    run lefthook-linter-coverage-full
    assert_success
}
