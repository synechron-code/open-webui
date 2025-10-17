#!/usr/bin/env bash
set -euo pipefail

# Helper script for merging upstream changes into Nexus Chat v3
# accept incoming ('theirs') side for all conflicted files
# except those explicitly listed (either as args or in a single keep-list file).
# Usage:
#   ./accept-incoming-except.sh nexus-chat-v3-customized-files.txt
#   ./accept-incoming-except.sh [--quiet] [--remaining-out <file>] nexus-chat-v3-customized-files.txt
#   ./accept-incoming-except.sh path/to/keep1 path/to/keep2
# Flags:
#   --quiet              Suppress per-file echo lines, show only summary
#   --remaining-out FILE Write remaining conflicted paths to FILE
# Notes:
#   - Run this while a merge is in progress and conflicts are present.
#   - Files listed in the keep list will be left as conflicts for manual resolution.

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository." >&2
  exit 2
fi

# Parse CLI flags
QUIET=false
REMAINING_OUT=""
KEEP=()

while [ $# -gt 0 ]; do
  case "$1" in
    --quiet)
      QUIET=true
      shift
      ;;
    --remaining-out)
      if [ $# -lt 2 ]; then
        echo "Error: --remaining-out requires a file path argument" >&2
        exit 2
      fi
      REMAINING_OUT="$2"
      shift 2
      ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 2
      ;;
    *)
      # Non-flag argument: either a keep-list file or a path to keep
      if [ ${#KEEP[@]} -eq 0 ] && [ -f "$1" ]; then
        # First non-flag arg is a file: read it as keep-list
        while IFS= read -r line || [ -n "$line" ]; do
          # strip comments and trim
          line="${line%%#*}"
          line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
          [ -n "$line" ] && KEEP+=("$line")
        done < "$1"
        shift
      else
        # Collect remaining args as paths to keep
        KEEP+=("$1")
        shift
      fi
      ;;
  esac
done

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

# Initialize counters
TOTAL_CONFLICTS=${#UNMERGED[@]}
AUTO_RESOLVED_COUNT=0
KEPT_COUNT=0
WARN_COUNT=0

[ "$QUIET" = false ] && echo "Conflicted files: ${TOTAL_CONFLICTS}"

for f in "${UNMERGED[@]}"; do
  if [ ${#KEEP[@]} -gt 0 ] && keep_contains "$f" "${KEEP[@]}"; then
    [ "$QUIET" = false ] && echo "Keeping conflict for: $f"
    ((KEPT_COUNT++))
  else
    [ "$QUIET" = false ] && echo "Accepting incoming for: $f"
    # Determine if there's a stage-3 (theirs) entry in the index and try several fallbacks.
    stage3_sha=""
    if git ls-files -u -- "$f" >/dev/null 2>&1; then
      # git ls-files -u format: <mode> <object> <stage>\t<path>
      stage3_sha=$(git ls-files -u -- "$f" | awk '$3==3{print $2; exit}') || true
    fi

    # Track whether this file was successfully resolved
    RESOLVED=false

    # 1) If stage3 exists, prefer 'git checkout --theirs' (works when index has stage 3)
    if [ -n "${stage3_sha}" ]; then
      if git checkout --theirs -- "$f" >/dev/null 2>&1; then
        git add -- "$f"
        RESOLVED=true
      fi
      # If checkout failed for some reason, try extracting the blob directly
      if [ "$RESOLVED" = false ] && git cat-file -p "${stage3_sha}" > "$f" 2>/dev/null; then
        git add -- "$f"
        RESOLVED=true
      fi
    fi

    # 2) If MERGE_HEAD exists, attempt to extract the incoming file from the merge commit
    if [ "$RESOLVED" = false ] && git rev-parse --verify MERGE_HEAD >/dev/null 2>&1; then
      if git show MERGE_HEAD:"$f" > "$f" 2>/dev/null; then
        git add -- "$f"
        RESOLVED=true
      fi
    fi

    # 3) If we still have a stage3 SHA but previous methods failed, try cat-file again as a fallback
    if [ "$RESOLVED" = false ] && [ -n "${stage3_sha}" ]; then
      if git cat-file -p "${stage3_sha}" > "$f" 2>/dev/null; then
        git add -- "$f"
        RESOLVED=true
      fi
    fi

    # Update counters
    if [ "$RESOLVED" = true ]; then
      ((AUTO_RESOLVED_COUNT++))
    else
      # Nothing worked: leave file as conflicted and warn the user
      echo "Warning: no 'theirs' (incoming) version available for '$f'. Leaving as conflict."
      ((WARN_COUNT++))
    fi
  fi
done

# Final status and summary
mapfile -t REMAINING < <(git diff --name-only --diff-filter=U)
REMAINING_COUNT=${#REMAINING[@]}

# Print summary
echo ""
echo "========================================"
echo "Summary:"
echo "  Total conflicts:     ${TOTAL_CONFLICTS}"
echo "  Auto-resolved:       ${AUTO_RESOLVED_COUNT}"
echo "  Kept for manual:     ${KEPT_COUNT}"
echo "  Warnings:            ${WARN_COUNT}"
echo "  Remaining conflicts: ${REMAINING_COUNT}"
echo "========================================"

# Optionally write remaining conflicts to file
if [ -n "${REMAINING_OUT}" ]; then
  if [ ${REMAINING_COUNT} -eq 0 ]; then
    # Create empty file or clear existing
    : > "${REMAINING_OUT}"
    echo "No remaining conflicts. Empty file written to: ${REMAINING_OUT}"
  else
    printf "%s\n" "${REMAINING[@]}" > "${REMAINING_OUT}"
    echo "Remaining conflicts written to: ${REMAINING_OUT}"
  fi
fi

# Final instructions
if [ "${REMAINING_COUNT}" -eq 0 ]; then
  echo ""
  echo "All non-kept conflicts resolved. Run 'git commit' to finish the merge."
else
  echo ""
  echo "Remaining conflicts:"
  printf "  %s\n" "${REMAINING[@]}"
  echo ""
  echo "Resolve the remaining files listed above, then 'git add' and 'git commit'."
fi

exit 0
