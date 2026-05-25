# nix-lefthook-linter-coverage-full

[![CI](https://github.com/pr0d1r2/nix-lefthook-linter-coverage-full/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-linter-coverage-full/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration
> process using [lefthook](https://github.com/evilmartians/lefthook) git hooks,
> [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible linter coverage check, packaged as a Nix flake.

Verifies every file extension tracked in the repo has a corresponding row in a
markdown documentation table. Catches "added a new file type without wiring a
linter" regressions.

## Doc file format

The doc file must contain a markdown table where column 1 holds backtick-quoted
extension tokens:

```markdown
| Extension | Linter | Notes |
|-----------|--------|-------|
| `.nix` | statix, nixfmt | |
| `.sh`, `.bats` | shellcheck | |
| `justfile` | custom | No dot extension |
```

## Usage

### Option A: Lefthook remote (recommended)

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-linter-coverage-full
    ref: main
    configs:
      - lefthook-remote.yml
```

Set the doc path in your shell hook or `.envrc`:

```bash
export LEFTHOOK_LINTER_COVERAGE_DOC=docs/linters.md
```

### Option B: Flake input

```nix
inputs.nix-lefthook-linter-coverage-full = {
  url = "github:pr0d1r2/nix-lefthook-linter-coverage-full";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LEFTHOOK_LINTER_COVERAGE_FULL_TIMEOUT` | `30` | Timeout in seconds |
| `LEFTHOOK_LINTER_COVERAGE_DOC` | *(required)* | Path to linter doc file (relative to repo root) |
| `LEFTHOOK_LINTER_COVERAGE_ROOT` | git root | Override repo root (for testing) |

## License

MIT
