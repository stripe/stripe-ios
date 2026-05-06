#!/bin/bash
set -uo pipefail

# post_pr_comment.sh
# Posts a snapshot diff summary as a PR comment with a link to the full report.
#
# Usage: ./post_pr_comment.sh <manifest_file> <recorded_dir> <report_url> <pr_number>
#
# Requires: GITHUB_TOKEN and GITHUB_REPOSITORY env vars

MANIFEST="${1:?Usage: $0 <manifest_file> <recorded_dir> <report_url> <pr_number>}"
RECORDED_DIR="${2:?}"
REPORT_URL="${3:?}"
PR_NUMBER="${4:?}"

GITHUB_REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY not set}"
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN not set}"

if [ ! -f "$MANIFEST" ]; then
    echo "Manifest file not found: $MANIFEST"
    exit 1
fi

CHANGED_COUNT=$(grep -c "^modified|" "$MANIFEST" 2>/dev/null || echo 0)
ADDED_COUNT=$(grep -c "^added|" "$MANIFEST" 2>/dev/null || echo 0)
REMOVED_COUNT=$(grep -c "^removed|" "$MANIFEST" 2>/dev/null || echo 0)
TOTAL=$((CHANGED_COUNT + ADDED_COUNT + REMOVED_COUNT))

MAX_INLINE=8

# Build the comment body into a temp file
BODY_FILE=$(mktemp)
trap "rm -f $BODY_FILE" EXIT

cat > "$BODY_FILE" << EOF
## 📸 Snapshot Changes Detected

| Modified | Added | Removed | Total |
|:--------:|:-----:|:-------:|:-----:|
| ${CHANGED_COUNT} | ${ADDED_COUNT} | ${REMOVED_COUNT} | ${TOTAL} |

EOF

# Show modified snapshots with inline diff images
if [ "$CHANGED_COUNT" -gt 0 ]; then
    echo "### Modified" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    SHOWN=0
    grep "^modified|" "$MANIFEST" 2>/dev/null | head -$MAX_INLINE | while IFS='|' read -r type rel_path; do
        filename=$(basename "$rel_path")
        echo "#### \`${filename}\`" >> "$BODY_FILE"
        echo "| Baseline | New | Diff |" >> "$BODY_FILE"
        echo "|:---:|:---:|:---:|" >> "$BODY_FILE"
        echo "| ![baseline](${REPORT_URL}/images/baseline/${rel_path}) | ![new](${REPORT_URL}/images/new/${rel_path}) | ![diff](${REPORT_URL}/images/diff/${rel_path}) |" >> "$BODY_FILE"
        echo "" >> "$BODY_FILE"
    done
    echo "" >> "$BODY_FILE"
fi

# List added snapshots with preview
if [ "$ADDED_COUNT" -gt 0 ]; then
    echo "### Added" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    grep "^added|" "$MANIFEST" 2>/dev/null | head -$MAX_INLINE | while IFS='|' read -r type rel_path; do
        filename=$(basename "$rel_path")
        echo "#### \`${filename}\`" >> "$BODY_FILE"
        echo "![new](${REPORT_URL}/images/new/${rel_path})" >> "$BODY_FILE"
        echo "" >> "$BODY_FILE"
    done
    echo "" >> "$BODY_FILE"
fi

# List removed snapshots
if [ "$REMOVED_COUNT" -gt 0 ]; then
    echo "### Removed" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    grep "^removed|" "$MANIFEST" 2>/dev/null | head -$MAX_INLINE | while IFS='|' read -r type rel_path; do
        filename=$(basename "$rel_path")
        echo "- \`${filename}\`" >> "$BODY_FILE"
    done
    echo "" >> "$BODY_FILE"
fi

if [ "$TOTAL" -gt "$MAX_INLINE" ]; then
    REMAINING=$((TOTAL - MAX_INLINE))
    echo "_...and ${REMAINING} more_" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
fi

cat >> "$BODY_FILE" << EOF
---

**[👀 View Full Diff Report](${SNAPSHOT_REPORT_URL:-$REPORT_URL})**

To approve these changes, a reviewer (not the PR author) should comment:
\`\`\`
/approve-snapshots
\`\`\`
EOF

# Delete previous snapshot comments
python3 << PYEOF
import json, urllib.request

headers = {
    'Authorization': 'token ${GITHUB_TOKEN}',
    'Accept': 'application/vnd.github.v3+json',
}

# List comments
req = urllib.request.Request(
    'https://api.github.com/repos/${GITHUB_REPO}/issues/${PR_NUMBER}/comments?per_page=100',
    headers=headers,
)
comments = json.loads(urllib.request.urlopen(req).read())
for c in comments:
    if 'Snapshot Changes Detected' in (c.get('body') or ''):
        del_req = urllib.request.Request(
            f"https://api.github.com/repos/${GITHUB_REPO}/issues/comments/{c['id']}",
            headers=headers,
            method='DELETE',
        )
        try:
            urllib.request.urlopen(del_req)
        except:
            pass

# Post new comment
body = open('${BODY_FILE}').read()
payload = json.dumps({'body': body}).encode()
req = urllib.request.Request(
    'https://api.github.com/repos/${GITHUB_REPO}/issues/${PR_NUMBER}/comments',
    data=payload,
    headers={**headers, 'Content-Type': 'application/json'},
    method='POST',
)
resp = urllib.request.urlopen(req)
print(f'PR comment posted (status {resp.status})')
PYEOF
