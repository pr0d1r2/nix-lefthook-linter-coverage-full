# shellcheck shell=bash
# Lefthook-compatible linter coverage check.
# Verifies every file extension in the repo has a corresponding row in a
# markdown linter-doc table. Catches "added a new file type without wiring
# a linter" regressions.
#
# The doc file must contain a markdown table where column 1 holds
# backtick-quoted extension tokens (e.g. `.nix`, `.sh`, `justfile`).
#
# Usage: lefthook-linter-coverage-full
# NOTE: sourced by writeShellApplication — no shebang or set needed.

DOC="${LEFTHOOK_LINTER_COVERAGE_DOC:-}"
ROOT="${LEFTHOOK_LINTER_COVERAGE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" || exit 1

if [ -z "$DOC" ]; then
  echo "check-linter-coverage: LEFTHOOK_LINTER_COVERAGE_DOC not set" >&2
  echo "  Set it to the path of your linter documentation file" >&2
  echo "  (relative to repo root), e.g.:" >&2
  echo "    export LEFTHOOK_LINTER_COVERAGE_DOC=docs/linters.md" >&2
  exit 1
fi

if [ ! -f "$DOC" ]; then
  echo "check-linter-coverage: $DOC missing — cannot verify coverage" >&2
  exit 1
fi

AWK_PROGRAM="LEFTHOOK_LINTER_COVERAGE_AWK_PROGRAM_PATH"

declare -A listed=()
while IFS= read -r tok; do
  [ -z "$tok" ] && continue
  listed["$tok"]=1
done < <(gawk -f "$AWK_PROGRAM" "$DOC")

mapfile -t exts < <(
  if [ -n "${LEFTHOOK_LINTER_COVERAGE_ROOT:-}" ]; then
    find . -type f ! -path './.git/*'
  else
    git ls-files
  fi | gawk -F/ '{print $NF}' | sed 's/.*\.//' | sort -u
)

missing=()
for ext in "${exts[@]}"; do
  [ -z "$ext" ] && continue
  if [ -z "${listed[$ext]:-}" ]; then
    missing+=("$ext")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "check-linter-coverage: ${#missing[@]} extension(s) not listed in $DOC:"
    for ext in "${missing[@]}"; do
      printf '  .%s\n' "$ext"
    done
    echo
    echo "Fix: add a row to the extension table in $DOC with an"
    echo "assigned linter or an explicit exempt reason."
  } >&2
  exit 1
fi
exit 0
