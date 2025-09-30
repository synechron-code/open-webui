#!/usr/bin/env bash
set -euo pipefail

# Helper script for merging upstream changes into Nexus Chat v3
# accept incoming ('theirs') side for all conflicted files
# except those explicitly listed (either as args or in a single keep-list file).
# Usage:
#   ./accept-incoming-except.sh nexus-chat-v3-customized-files.txt
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
    # Determine if there's a stage-3 (theirs) entry in the index and try several fallbacks.
    stage3_sha=""
    if git ls-files -u -- "$f" >/dev/null 2>&1; then
      # git ls-files -u format: <mode> <object> <stage>\t<path>
      stage3_sha=$(git ls-files -u -- "$f" | awk '$3==3{print $2; exit}') || true
    fi

    # 1) If stage3 exists, prefer 'git checkout --theirs' (works when index has stage 3)
    if [ -n "${stage3_sha}" ]; then
      if git checkout --theirs -- "$f" >/dev/null 2>&1; then
        git add -- "$f"
        continue
      fi
      # If checkout failed for some reason, try extracting the blob directly
      if git cat-file -p "${stage3_sha}" > "$f" 2>/dev/null; then
        git add -- "$f"
        continue
      fi
    fi

    # 2) If MERGE_HEAD exists, attempt to extract the incoming file from the merge commit
    if git rev-parse --verify MERGE_HEAD >/dev/null 2>&1; then
      if git show MERGE_HEAD:"$f" > "$f" 2>/dev/null; then
        git add -- "$f"
        continue
      fi
    fi

    # 3) If we still have a stage3 SHA but previous methods failed, try cat-file again as a fallback
    if [ -n "${stage3_sha}" ]; then
      if git cat-file -p "${stage3_sha}" > "$f" 2>/dev/null; then
        git add -- "$f"
        continue
      fi
    fi

    # Nothing worked: leave file as conflicted and warn the user
    echo "Warning: no 'theirs' (incoming) version available for '$f'. Leaving as conflict."
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
