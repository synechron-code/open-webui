#!/usr/bin/env bash
set -euo pipefail

# Simplified script: accept incoming ('theirs') side for all conflicted files
# except those explicitly listed (either as args or in a single keep-list file).
# Usage:
#   ./accept-incoming-except.sh keep-list.txt
#   ./accept-incoming-except.sh path/to/keep1 path/to/keep2
# Notes:
#   - Run this while a merge is in progress and conflicts are present.
#   - Files listed in the keep list will be left as conflicts for manual resolution.

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository." >&2
  exit 2
fi

# Build keep list from a single file argument or remaining args
KEEP=()
if [ $# -eq 1 ] && [ -f "$1" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # strip comments and trim
    line="${line%%#*}"
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$line" ] && KEEP+=("$line")
  done < "$1"
else
  for a in "$@"; do
    KEEP+=("$a")
  done
fi

# Helper: check path membership
keep_contains() {
  local key="$1"; shift
  for p in "$@"; do
    [ "$p" = "$key" ] && return 0
  done
  return 1
}

# Gather conflicted files (NUL separated to be safe)
mapfile -t UNMERGED < <(git diff --name-only --diff-filter=U -z | tr '\0' '\n')

if [ ${#UNMERGED[@]} -eq 0 ]; then
  echo "No merge conflicts found."
  exit 0
fi

echo "Conflicted files: ${#UNMERGED[@]}"
for f in "${UNMERGED[@]}"; do
  if [ ${#KEEP[@]} -gt 0 ] && keep_contains "$f" "${KEEP[@]}"; then
    echo "Keeping conflict for: $f"
  else
    echo "Accepting incoming for: $f"
    git checkout --theirs -- "$f"
    git add -- "$f"
  fi
done

# Final status
REMAINING_COUNT=$(git diff --name-only --diff-filter=U | wc -l)
if [ "${REMAINING_COUNT}" -eq 0 ]; then
  echo "All non-kept conflicts resolved. Run 'git commit' to finish the merge."
else
  echo "Remaining conflicts:"
  git diff --name-only --diff-filter=U
  echo "Resolve the remaining files listed above, then 'git add' and 'git commit'."
fi

exit 0
