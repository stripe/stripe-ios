#!/bin/bash
set -euo pipefail

# generate_diff_report.sh
# Compares newly recorded snapshots against baselines and generates an HTML diff report.
# Images are copied into the output directory as separate files (not base64 embedded).
#
# Usage: ./generate_diff_report.sh <recorded_dir> <baseline_dir> <output_dir>
#
# Exit codes:
#   0 - No differences found
#   1 - Differences found (report generated)

RECORDED_DIR="${1:?Usage: $0 <recorded_dir> <baseline_dir> <output_dir>}"
BASELINE_DIR="${2:?Usage: $0 <recorded_dir> <baseline_dir> <output_dir>}"
OUTPUT_DIR="${3:?Usage: $0 <recorded_dir> <baseline_dir> <output_dir>}"

MANIFEST="${SNAPSHOT_MANIFEST:-$(mktemp)}"

mkdir -p "$OUTPUT_DIR/images/baseline" "$OUTPUT_DIR/images/new" "$OUTPUT_DIR/images/diff"

# Threshold: ignore diffs where less than 0.5% of pixels changed
# This filters out subpixel rendering noise / antialiasing differences
DIFF_THRESHOLD="${SNAPSHOT_DIFF_THRESHOLD:-0.005}"

# Build a manifest of changes: TYPE|REL_PATH
find "$RECORDED_DIR" -name "*.png" -print0 | while IFS= read -r -d '' recorded_file; do
    rel_path="${recorded_file#$RECORDED_DIR/}"
    baseline_file="$BASELINE_DIR/$rel_path"

    if [ ! -f "$baseline_file" ]; then
        echo "added|$rel_path" >> "$MANIFEST"
    else
        if ! cmp -s "$baseline_file" "$recorded_file"; then
            # Check if the difference is above threshold
            if command -v compare &> /dev/null; then
                # Get normalized RMSE (0.0 = identical, 1.0 = completely different)
                metric=$(compare -metric RMSE "$baseline_file" "$recorded_file" /dev/null 2>&1 || true)
                normalized=$(echo "$metric" | grep -oE '\([0-9.]+\)' | tr -d '()')
                if [ -n "$normalized" ]; then
                    above=$(echo "$normalized > $DIFF_THRESHOLD" | bc -l 2>/dev/null || echo "1")
                    if [ "$above" = "1" ]; then
                        echo "modified|$rel_path" >> "$MANIFEST"
                    fi
                else
                    echo "modified|$rel_path" >> "$MANIFEST"
                fi
            else
                echo "modified|$rel_path" >> "$MANIFEST"
            fi
        fi
    fi
done || true

find "$BASELINE_DIR" -name "*.png" -print0 | while IFS= read -r -d '' baseline_file; do
    rel_path="${baseline_file#$BASELINE_DIR/}"
    if [ ! -f "$RECORDED_DIR/$rel_path" ]; then
        echo "removed|$rel_path" >> "$MANIFEST"
    fi
done || true

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

# Copy images and generate diffs
copy_image() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

grep "^modified|" "$MANIFEST" | while IFS='|' read -r type rel_path; do
    copy_image "$BASELINE_DIR/$rel_path" "$OUTPUT_DIR/images/baseline/$rel_path"
    copy_image "$RECORDED_DIR/$rel_path" "$OUTPUT_DIR/images/new/$rel_path"
    if command -v compare &> /dev/null; then
        mkdir -p "$(dirname "$OUTPUT_DIR/images/diff/$rel_path")"
        compare "$BASELINE_DIR/$rel_path" "$RECORDED_DIR/$rel_path" \
            -compose src -highlight-color '#FF000080' \
            "$OUTPUT_DIR/images/diff/$rel_path" 2>/dev/null || true
    fi
done || true

grep "^added|" "$MANIFEST" | while IFS='|' read -r type rel_path; do
    copy_image "$RECORDED_DIR/$rel_path" "$OUTPUT_DIR/images/new/$rel_path"
done || true

grep "^removed|" "$MANIFEST" | while IFS='|' read -r type rel_path; do
    copy_image "$BASELINE_DIR/$rel_path" "$OUTPUT_DIR/images/baseline/$rel_path"
done || true

# Generate HTML report referencing the image files
cat > "$OUTPUT_DIR/index.html" << 'EOF'
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
<div id="app"></div>
<script>
EOF

# Inject the manifest data as JSON
echo "const MANIFEST = [" >> "$OUTPUT_DIR/index.html"
while IFS='|' read -r type rel_path; do
    # Escape for JS
    escaped=$(echo "$rel_path" | sed 's/"/\\"/g')
    echo "{type:\"$type\",path:\"$escaped\"}," >> "$OUTPUT_DIR/index.html"
done < "$MANIFEST"
echo "];" >> "$OUTPUT_DIR/index.html"

cat >> "$OUTPUT_DIR/index.html" << 'EOF'
const changed = MANIFEST.filter(m => m.type === 'modified').length;
const added = MANIFEST.filter(m => m.type === 'added').length;
const removed = MANIFEST.filter(m => m.type === 'removed').length;
const total = MANIFEST.length;

function basename(p) { return p.split('/').pop(); }

function renderItem(m) {
  const name = basename(m.path);
  if (m.type === 'modified') {
    return `<div class="item" data-t="modified">
      <div class="name"><span class="badge modified">Modified</span>${name}</div>
      <div class="modes">
        <button class="on" onclick="mode(this,'sbs')">Side by Side</button>
        <button onclick="mode(this,'overlay')">Overlay</button>
        <button onclick="mode(this,'diff')">Diff Only</button>
      </div>
      <div class="view">
        <div class="col sbs-v"><div class="lbl">Baseline</div><img src="images/baseline/${m.path}" /></div>
        <div class="col sbs-v"><div class="lbl">New</div><img src="images/new/${m.path}" /></div>
        <div class="col sbs-v diff-v"><div class="lbl">Diff</div><img src="images/diff/${m.path}" /></div>
        <div class="col overlay-v hidden">
          <div class="overlay-wrap">
            <img src="images/baseline/${m.path}" />
            <img class="ov" src="images/new/${m.path}" style="opacity:0.5" />
          </div>
          <input type="range" class="slider" min="0" max="100" value="50"
            oninput="this.parentElement.querySelector('.ov').style.opacity=this.value/100" />
        </div>
      </div>
    </div>`;
  } else if (m.type === 'added') {
    return `<div class="item" data-t="added">
      <div class="name"><span class="badge added">Added</span>${name}</div>
      <div class="view"><div class="col"><img src="images/new/${m.path}" /></div></div>
    </div>`;
  } else {
    return `<div class="item" data-t="removed">
      <div class="name"><span class="badge removed">Removed</span>${name}</div>
      <div class="view"><div class="col"><img src="images/baseline/${m.path}" style="opacity:0.5" /></div></div>
    </div>`;
  }
}

document.getElementById('app').innerHTML = `
  <div class="summary">
    <div class="stat m"><div class="n">${changed}</div><div class="l">Modified</div></div>
    <div class="stat a"><div class="n">${added}</div><div class="l">Added</div></div>
    <div class="stat r"><div class="n">${removed}</div><div class="l">Removed</div></div>
  </div>
  <div class="filters">
    <button class="on" onclick="filt(this,'all')">All (${total})</button>
    <button onclick="filt(this,'modified')">Modified (${changed})</button>
    <button onclick="filt(this,'added')">Added (${added})</button>
    <button onclick="filt(this,'removed')">Removed (${removed})</button>
  </div>
  ${MANIFEST.map(renderItem).join('\n')}
`;

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

echo "Report generated: $OUTPUT_DIR/index.html"
exit 1
