# Snapshot Testing Tool

Automated visual snapshot testing with CI-driven recording and human approval.

## How It Works

1. **CI always re-records** — snapshot tests run in record mode on every PR
2. **Diffs against baselines** — recorded snapshots are compared to the `snapshot-baselines` branch
3. **HTML report** — if changes are detected, a visual diff report is generated as a CI artifact
4. **Approval required** — a GitHub Check blocks merge until someone (not the PR author) comments `/approve-snapshots`
5. **Baselines update on merge** — when a PR merges, approved snapshots become the new baselines

## Setup (One-Time)

```bash
# Create the snapshot-baselines orphan branch from existing reference images
./SnapshotTool/scripts/init_baselines.sh
git push origin snapshot-baselines
```

## Local Development

```bash
# Run tests and see a diff report locally
./SnapshotTool/scripts/local_diff.sh

# Run only specific test target
./SnapshotTool/scripts/local_diff.sh StripePaymentSheetTests
```

## CI Workflow

The GitHub Actions workflows handle everything automatically:

- **`.github/workflows/snapshot-tests.yml`** — runs on PRs, records snapshots, generates diff report, creates a check
- **`.github/workflows/snapshot-approve.yml`** — listens for `/approve-snapshots` comments, updates baselines

## Approving Changes

1. CI posts a "Snapshot Review" check on your PR with a link to the diff report
2. Download and open the HTML report from the workflow artifacts
3. Review the visual changes (side-by-side, overlay, and diff views)
4. A reviewer comments `/approve-snapshots` on the PR
5. The check flips to green and the PR can merge

## Requirements

- ImageMagick (`brew install imagemagick`) — for generating diff images
  - Falls back to binary comparison if not available
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
