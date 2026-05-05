#!/bin/bash
set -euo pipefail

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

CHANGED_COUNT=$(grep -c "^modified|" "$MANIFEST" || true)
ADDED_COUNT=$(grep -c "^added|" "$MANIFEST" || true)
REMOVED_COUNT=$(grep -c "^removed|" "$MANIFEST" || true)
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

# List modified snapshots
if [ "$CHANGED_COUNT" -gt 0 ]; then
    echo "### Modified" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    SHOWN=0
    grep "^modified|" "$MANIFEST" | head -$MAX_INLINE | while IFS='|' read -r type rel_path; do
        filename=$(basename "$rel_path")
        echo "- \`${filename}\`" >> "$BODY_FILE"
    done
    echo "" >> "$BODY_FILE"
fi

# List added snapshots
if [ "$ADDED_COUNT" -gt 0 ]; then
    echo "### Added" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    grep "^added|" "$MANIFEST" | head -$MAX_INLINE | while IFS='|' read -r type rel_path; do
        filename=$(basename "$rel_path")
        echo "- \`${filename}\`" >> "$BODY_FILE"
    done
    echo "" >> "$BODY_FILE"
fi

# List removed snapshots
if [ "$REMOVED_COUNT" -gt 0 ]; then
    echo "### Removed" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    grep "^removed|" "$MANIFEST" | head -$MAX_INLINE | while IFS='|' read -r type rel_path; do
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

**[👀 View Full Diff Report](${REPORT_URL})**

To approve these changes, a reviewer (not the PR author) should comment:
\`\`\`
/approve-snapshots
\`\`\`
EOF

# Delete previous snapshot comments from this bot
curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPO/issues/$PR_NUMBER/comments?per_page=100" \
    | python3 -c "
import json, sys
comments = json.load(sys.stdin)
for c in comments:
    if 'Snapshot Changes Detected' in (c.get('body') or ''):
        print(c['id'])
" 2>/dev/null | while read -r comment_id; do
    curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPO/issues/$PR_NUMBER/comments/$comment_id" || true
done

# Post the comment using python3 for safe JSON encoding
python3 -c "
import json, sys, urllib.request

body = open('$BODY_FILE').read()
payload = json.dumps({'body': body}).encode()

req = urllib.request.Request(
    'https://api.github.com/repos/$GITHUB_REPO/issues/$PR_NUMBER/comments',
    data=payload,
    headers={
        'Authorization': 'token $GITHUB_TOKEN',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
    },
    method='POST',
)
resp = urllib.request.urlopen(req)
print(f'PR comment posted (status {resp.status})')
"
