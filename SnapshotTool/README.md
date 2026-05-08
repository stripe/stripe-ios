# Snapshot Testing Tool

Automated visual snapshot testing with CI-driven recording and human approval.

## How It Works

1. **CI always re-records** — snapshot tests run in record mode on every PR
2. **Diffs against baselines** — recorded snapshots are compared to the `snapshot-baselines` branch
3. **HTML report** — if changes are detected, a visual diff report is generated as a CI artifact
4. **Approval required** — a GitHub Check blocks merge until someone adds the `snapshot changes approved` label
5. **Baselines update on merge** — when a PR merges, approved snapshots become the new baselines

## Setup (One-Time)

```bash
# Create the snapshot-baselines orphan branch from existing reference images
ruby SnapshotTool/scripts/snapshot_tool.rb init_baselines
git push origin snapshot-baselines
```

## Local Development

```bash
# Run tests and see a diff report locally
ruby SnapshotTool/scripts/snapshot_tool.rb local_diff

# Run only specific test target
ruby SnapshotTool/scripts/snapshot_tool.rb local_diff StripePaymentSheetTests
```

## CLI Reference

```bash
# Generate a diff report from recorded vs baseline directories
ruby SnapshotTool/scripts/snapshot_tool.rb generate_diff <recorded_dir> <baseline_dir> <output_dir> [--manifest PATH] [--threshold 0.1]

# Initialize the snapshot-baselines branch
ruby SnapshotTool/scripts/snapshot_tool.rb init_baselines

# Run tests locally and open the diff report
ruby SnapshotTool/scripts/snapshot_tool.rb local_diff [test_target]

# Post a PR comment with snapshot changes (CI only)
ruby SnapshotTool/scripts/snapshot_tool.rb post_pr_comment <manifest> <recorded_dir> <report_url> <pr_number>
```

## CI Workflow

The GitHub Actions workflows handle everything automatically:

- **`.github/workflows/snapshot-tests.yml`** — runs on PRs, records snapshots, generates diff report, creates a check

## Approving Changes

1. CI posts a "Snapshot Review" check on your PR with a link to the diff report
2. Download and open the HTML report from the workflow artifacts
3. Review the visual changes (side-by-side, overlay, and diff views)
4. Add the `snapshot changes approved` label to the PR
5. The check flips to green and the PR can merge

## Requirements

- ImageMagick (`brew install imagemagick`) — required for diff image generation and pixel threshold comparison
- macOS CI runner with Xcode and iOS Simulator

## Architecture

```
snapshot-baselines (orphan branch)
├── TestClass.testMethod@3x.png
├── TestClass.testOtherMethod@3x.png
└── ...

CI records snapshots → diffs against branch → generates HTML → uploads artifact
                                                                     ↓
                                              Reviewer approves → baselines updated
```
