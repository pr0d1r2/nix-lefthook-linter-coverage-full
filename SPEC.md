## §D — Description

nix-lefthook-linter-coverage-full is a Nix-flake-packaged lefthook git-hook that enforces linter coverage completeness. It scans every file extension tracked in a repository and verifies that each one appears in a user-maintained markdown documentation table (column 1, backtick-quoted tokens). If any extension lacks a corresponding row, the hook fails with a list of uncovered extensions, catching "added a new file type without wiring a linter" regressions. The project targets Nix-based development teams that use lefthook for git-hook orchestration and want automated enforcement that their linter documentation stays in sync with the actual file types in the repository. It also bundles 15 companion lefthook linter wrappers (nixfmt, shellcheck, shfmt, statix, deadnix, yamllint, typos, trailing-whitespace, missing-final-newline, git-conflict-markers, editorconfig-checker, git-no-local-paths, nix-flake-check, nix-no-embedded-shell, file-size-check) in its development shell.

## §V — Invariants

1. The script must exit 1 with a diagnostic when `LEFTHOOK_LINTER_COVERAGE_DOC` is unset or empty.
2. The script must exit 1 when the doc file specified by `LEFTHOOK_LINTER_COVERAGE_DOC` does not exist.
3. The script must exit 0 when every file extension in the repo is listed in the doc table.
4. The script must exit 1 and list each missing extension when any tracked extension lacks a doc-table row.
5. The AWK parser must extract all backtick-quoted tokens from the first column of markdown table rows, stripping any leading dot.
6. Multiple backtick-quoted tokens in a single table cell (e.g., `` `.sh`, `.bats` ``) must each be recognized independently.
7. Extensionless filenames (e.g., `justfile`) must be matchable by their full name as a backtick-quoted token.
8. When `LEFTHOOK_LINTER_COVERAGE_ROOT` is set, the script must use `find` instead of `git ls-files` to enumerate files, enabling testing outside git repos.
9. The Nix flake must build on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
10. CI must pass on both `ubuntu-latest` and `macos-latest` runners.
11. The `LEFTHOOK_LINTER_COVERAGE_AWK_PROGRAM_PATH` placeholder in the shell script must be replaced at Nix build time with the store path of the AWK program.
12. All shell code must pass shellcheck, shfmt, and the project's full lefthook pre-push suite (15 remote linter hooks).
13. Unit tests use bats with bats-support, bats-assert, and bats-file libraries; `BATS_LIB_PATH` must be set.
14. The lefthook timeout defaults to 30 seconds (`LEFTHOOK_LINTER_COVERAGE_FULL_TIMEOUT`).
15. Editorconfig enforces UTF-8, LF line endings, 2-space indent, final newline, and trimmed trailing whitespace on all files.

## §I — Interfaces

### CLI command

```
lefthook-linter-coverage-full
```

No arguments. Behavior controlled entirely by environment variables. Exit 0 on success, exit 1 on failure (with diagnostics on stderr).

### Environment variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LEFTHOOK_LINTER_COVERAGE_DOC` | `string` | *(required)* | Path to the markdown linter-doc file, relative to repo root |
| `LEFTHOOK_LINTER_COVERAGE_ROOT` | `string` | `git rev-parse --show-toplevel` | Override repo root; when set, uses `find` instead of `git ls-files` |
| `LEFTHOOK_LINTER_COVERAGE_FULL_TIMEOUT` | `integer` | `30` | Timeout in seconds (used by lefthook-remote.yml wrapper) |

### Nix flake outputs

| Output | Path | Description |
|--------|------|-------------|
| `packages.<system>.default` | — | `writeShellApplication` wrapping the coverage-check script with git, gawk, gnused in PATH |
| `devShells.<system>.default` | — | Full dev shell with all 15 linter wrappers, bats, lefthook; runs `lefthook install` on entry |
| `devShells.<system>.ci` | — | CI-oriented shell (same packages, no shell hook) |

### Lefthook remote config (`lefthook-remote.yml`)

```yaml
pre-push:
  commands:
    linter-coverage-full:
      run: timeout ${LEFTHOOK_LINTER_COVERAGE_FULL_TIMEOUT:-30} lefthook-linter-coverage-full
```

### Doc-table format (input)

Markdown table where column 1 contains backtick-quoted extension tokens. Leading dots are stripped. Example:

```markdown
| Extension | Linter | Notes |
|-----------|--------|-------|
| `.nix` | statix, nixfmt | |
| `.sh`, `.bats` | shellcheck | |
| `justfile` | custom | No dot extension |
```

### AWK program (`linter-coverage.awk`)

```
(stdin: markdown file) → (stdout: one token per line, dot-stripped)
```

Parses markdown table rows (`/^\|/`), extracts first column, prints each backtick-quoted token with leading dot removed.

### File size limits config (`config/lefthook/file_size_limits.yml`)

```yaml
default: 4096
extensions:
  lock: 65536
  nix: 10240
  bats: 4096
  yml: 4096
```

## §T — Tasks

| status | id | goal |
|--------|----|------|
| `.` | T1 | Add bats tests for the AWK script in isolation (e.g., header-only tables, empty tables, tables with no backtick tokens) |
| `.` | T2 | Add test for dotfiles (`.gitignore`, `.editorconfig`) — verify they resolve to `gitignore`, `editorconfig` |
| `.` | T3 | Add test for files with multiple dots (e.g., `foo.spec.ts`) — verify only the final extension is checked |
| `.` | T4 | Add test for empty repository (no tracked files) — should exit 0 |
| `.` | T5 | Align `actions/checkout` version in `update-pins.yml` (v4) with `ci.yml` (v6) |
| `.` | T6 | Add `nix-flake-check` remote to the Nix flake inputs (present in lefthook.yml remotes but absent from flake.nix inputs/dev-shell wrappers) |
| `.` | T7 | Add markdownlint lefthook remote (`.markdownlint.yml` config exists but no corresponding remote in `lefthook.yml`) |
| `.` | T8 | Document the 15 bundled linter wrappers in README.md (currently only the main tool is documented) |
| `.` | T9 | Add a `--verbose` or `--list` mode that prints all detected extensions and their coverage status |
| `.` | T10 | Add integration test that exercises the full Nix-built package (currently tests rely on `LEFTHOOK_LINTER_COVERAGE_ROOT` override, not the actual Nix derivation) |

## §B — Bugs / Known Issues

1. **`actions/checkout` version skew**: `ci.yml` uses `actions/checkout@v6` while `update-pins.yml` uses `actions/checkout@v4`. This is not a functional bug but creates inconsistency and may miss security fixes in the older pin.

2. **`nix-flake-check` remote missing from flake inputs**: `lefthook.yml` lists `nix-lefthook-nix-flake-check` as a remote, but `flake.nix` has no corresponding `-src` input and no wrapper derivation. The hook runs only because lefthook fetches it at runtime via git, but it is not Nix-managed or version-pinned the same way as the other 14 linters. (On closer inspection, `nix-flake-check` may intentionally not need a wrapper since it invokes `nix flake check` directly, but it breaks the pattern of the other remotes.)

3. **Extensionless dotfiles produce misleading tokens**: A file named `.envrc` is processed by `sed 's/.*\.//'` to yield `envrc`, which then must appear in the doc table. This is technically correct but may surprise users who think of `.envrc` as a dotfile without an extension rather than having extension `envrc`.

4. **No error if AWK program path is invalid**: If the Nix build-time substitution of `LEFTHOOK_LINTER_COVERAGE_AWK_PROGRAM_PATH` fails or produces an invalid path, the gawk invocation will fail with a generic "No such file" error rather than a project-specific diagnostic.

5. **`sed 's/.*\.//'` on filenames with no dot returns the full filename**: For files like `Makefile` or `Dockerfile`, the sed substitution is a no-op (no dot to match), so the full filename becomes the "extension." This is handled by design (the doc table can list `` `Makefile` ``), but it is undocumented and may be non-obvious to users.

6. **macOS CI runs only on push/dispatch, not PRs**: The `build-macos` job in `ci.yml` is conditioned on `github.event_name == 'push' || github.event_name == 'workflow_dispatch'`, so PRs are not tested on macOS before merge.
