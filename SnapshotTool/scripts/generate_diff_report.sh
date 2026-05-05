#!/bin/bash
set -euo pipefail

# generate_diff_report.sh
# Compares newly recorded snapshots against baselines and generates an HTML diff report.
#
# Usage: ./generate_diff_report.sh <recorded_dir> <baseline_dir> <output_html>
#
# Exit codes:
#   0 - No differences found
#   1 - Differences found (report generated)
#   2 - Error

RECORDED_DIR="${1:?Usage: $0 <recorded_dir> <baseline_dir> <output_html>}"
BASELINE_DIR="${2:?Usage: $0 <recorded_dir> <baseline_dir> <output_html>}"
OUTPUT_HTML="${3:?Usage: $0 <recorded_dir> <baseline_dir> <output_html>}"

DIFF_DIR=$(mktemp -d)
MANIFEST="${SNAPSHOT_MANIFEST:-$(mktemp)}"
trap "rm -rf $DIFF_DIR" EXIT

CHANGED_COUNT=0
ADDED_COUNT=0
REMOVED_COUNT=0
UNCHANGED_COUNT=0

# Build a manifest of changes: TYPE|REL_PATH
find "$RECORDED_DIR" -name "*.png" -print0 | while IFS= read -r -d '' recorded_file; do
    rel_path="${recorded_file#$RECORDED_DIR/}"
    baseline_file="$BASELINE_DIR/$rel_path"

    if [ ! -f "$baseline_file" ]; then
        echo "added|$rel_path" >> "$MANIFEST"
    else
        if ! cmp -s "$baseline_file" "$recorded_file"; then
            echo "modified|$rel_path" >> "$MANIFEST"
            # Generate diff image if ImageMagick available
            if command -v compare &> /dev/null; then
                diff_output="$DIFF_DIR/$rel_path"
                mkdir -p "$(dirname "$diff_output")"
                compare "$baseline_file" "$recorded_file" -compose src -highlight-color '#FF000080' "$diff_output" 2>/dev/null || true
            fi
        fi
    fi
done

find "$BASELINE_DIR" -name "*.png" -print0 | while IFS= read -r -d '' baseline_file; do
    rel_path="${baseline_file#$BASELINE_DIR/}"
    if [ ! -f "$RECORDED_DIR/$rel_path" ]; then
        echo "removed|$rel_path" >> "$MANIFEST"
    fi
done

# Count changes
if [ ! -f "$MANIFEST" ] || [ ! -s "$MANIFEST" ]; then
    echo "No snapshot differences found."
    exit 0
fi

CHANGED_COUNT=$(grep -c "^modified|" "$MANIFEST" || true)
ADDED_COUNT=$(grep -c "^added|" "$MANIFEST" || true)
REMOVED_COUNT=$(grep -c "^removed|" "$MANIFEST" || true)
TOTAL_CHANGES=$((CHANGED_COUNT + ADDED_COUNT + REMOVED_COUNT))

if [ "$TOTAL_CHANGES" -eq 0 ]; then
    echo "No snapshot differences found."
    exit 0
fi

echo "Found $TOTAL_CHANGES changes: $CHANGED_COUNT modified, $ADDED_COUNT added, $REMOVED_COUNT removed"

# Helper to base64-encode an image
img_uri() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "data:image/png;base64,$(base64 < "$file" | tr -d '\n')"
    fi
}

# Generate HTML report
{
cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Snapshot Diff Report</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; }
h1 { font-size: 24px; margin-bottom: 16px; }
.summary { display: flex; gap: 12px; margin-bottom: 20px; flex-wrap: wrap; }
.stat { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 10px 16px; }
.stat .n { font-size: 24px; font-weight: bold; }
.stat .l { font-size: 11px; color: #8b949e; text-transform: uppercase; }
.stat.m .n { color: #f0883e; }
.stat.a .n { color: #3fb950; }
.stat.r .n { color: #f85149; }
.filters { display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; }
.filters button { background: #21262d; border: 1px solid #30363d; color: #c9d1d9; padding: 5px 14px; border-radius: 16px; cursor: pointer; font-size: 13px; }
.filters button.on { background: #388bfd; border-color: #388bfd; color: #fff; }
.item { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px; margin-bottom: 12px; }
.item .name { font-size: 13px; font-weight: 600; margin-bottom: 10px; word-break: break-all; }
.badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; margin-right: 6px; }
.badge.modified { background: #f0883e20; color: #f0883e; }
.badge.added { background: #3fb95020; color: #3fb950; }
.badge.removed { background: #f8514920; color: #f85149; }
.modes { display: flex; gap: 6px; margin-bottom: 10px; }
.modes button { background: #21262d; border: 1px solid #30363d; color: #c9d1d9; padding: 3px 10px; border-radius: 4px; cursor: pointer; font-size: 12px; }
.modes button.on { background: #388bfd; border-color: #388bfd; color: #fff; }
.view { display: flex; gap: 8px; align-items: flex-start; flex-wrap: wrap; }
.view .col { text-align: center; }
.view .col img { max-width: 300px; height: auto; border: 1px solid #30363d; border-radius: 4px; background: repeating-conic-gradient(#1c1c1c 0% 25%, #2a2a2a 0% 50%) 50% / 16px 16px; }
.view .col .lbl { font-size: 10px; color: #8b949e; text-transform: uppercase; margin-bottom: 4px; }
.overlay-wrap { position: relative; display: inline-block; }
.overlay-wrap img { max-width: 300px; }
.overlay-wrap img.ov { position: absolute; top: 0; left: 0; }
.slider { margin-top: 6px; width: 300px; }
.hidden { display: none; }
</style>
</head>
<body>
<h1>Snapshot Diff Report</h1>
EOF

cat << HTML
<div class="summary">
<div class="stat m"><div class="n">${CHANGED_COUNT}</div><div class="l">Modified</div></div>
<div class="stat a"><div class="n">${ADDED_COUNT}</div><div class="l">Added</div></div>
<div class="stat r"><div class="n">${REMOVED_COUNT}</div><div class="l">Removed</div></div>
</div>
<div class="filters">
<button class="on" onclick="filt(this,'all')">All (${TOTAL_CHANGES})</button>
<button onclick="filt(this,'modified')">Modified (${CHANGED_COUNT})</button>
<button onclick="filt(this,'added')">Added (${ADDED_COUNT})</button>
<button onclick="filt(this,'removed')">Removed (${REMOVED_COUNT})</button>
</div>
HTML

# Emit each changed item
grep "^modified|" "$MANIFEST" | while IFS='|' read -r type rel_path; do
    filename=$(basename "$rel_path")
    baseline_uri=$(img_uri "$BASELINE_DIR/$rel_path")
    recorded_uri=$(img_uri "$RECORDED_DIR/$rel_path")
    diff_uri=$(img_uri "$DIFF_DIR/$rel_path")

    cat << ITEM
<div class="item" data-t="modified">
<div class="name"><span class="badge modified">Modified</span>${filename}</div>
<div class="modes">
<button class="on" onclick="mode(this,'sbs')">Side by Side</button>
<button onclick="mode(this,'overlay')">Overlay</button>
<button onclick="mode(this,'diff')">Diff Only</button>
</div>
<div class="view" data-m="sbs">
<div class="col sbs-v"><div class="lbl">Baseline</div><img src="${baseline_uri}" /></div>
<div class="col sbs-v"><div class="lbl">New</div><img src="${recorded_uri}" /></div>
<div class="col sbs-v diff-v"><div class="lbl">Diff</div><img src="${diff_uri}" /></div>
<div class="col overlay-v hidden">
<div class="overlay-wrap">
<img src="${baseline_uri}" />
<img class="ov" src="${recorded_uri}" style="opacity:0.5" />
</div>
<input type="range" class="slider" min="0" max="100" value="50" oninput="this.parentElement.querySelector('.ov').style.opacity=this.value/100" />
</div>
</div>
</div>
ITEM
done

grep "^added|" "$MANIFEST" | while IFS='|' read -r type rel_path; do
    filename=$(basename "$rel_path")
    recorded_uri=$(img_uri "$RECORDED_DIR/$rel_path")
    cat << ITEM
<div class="item" data-t="added">
<div class="name"><span class="badge added">Added</span>${filename}</div>
<div class="view"><div class="col"><img src="${recorded_uri}" /></div></div>
</div>
ITEM
done

grep "^removed|" "$MANIFEST" | while IFS='|' read -r type rel_path; do
    filename=$(basename "$rel_path")
    baseline_uri=$(img_uri "$BASELINE_DIR/$rel_path")
    cat << ITEM
<div class="item" data-t="removed">
<div class="name"><span class="badge removed">Removed</span>${filename}</div>
<div class="view"><div class="col"><img src="${baseline_uri}" style="opacity:0.5" /></div></div>
</div>
ITEM
done

cat << 'EOF'
<script>
function filt(btn, type) {
  btn.parentElement.querySelectorAll('button').forEach(b => b.classList.remove('on'));
  btn.classList.add('on');
  document.querySelectorAll('.item').forEach(el => {
    el.style.display = (type === 'all' || el.dataset.t === type) ? '' : 'none';
  });
}
function mode(btn, m) {
  btn.parentElement.querySelectorAll('button').forEach(b => b.classList.remove('on'));
  btn.classList.add('on');
  var view = btn.closest('.item').querySelector('.view');
  view.querySelectorAll('.sbs-v').forEach(el => el.classList.toggle('hidden', m !== 'sbs'));
  view.querySelectorAll('.diff-v').forEach(el => el.classList.toggle('hidden', m === 'overlay'));
  view.querySelectorAll('.overlay-v').forEach(el => el.classList.toggle('hidden', m !== 'overlay'));
  if (m === 'diff') {
    view.querySelectorAll('.sbs-v').forEach(el => el.classList.add('hidden'));
    view.querySelectorAll('.diff-v').forEach(el => el.classList.remove('hidden'));
  }
}
</script>
</body>
</html>
EOF
} > "$OUTPUT_HTML"

echo "Report generated: $OUTPUT_HTML"
exit 1
