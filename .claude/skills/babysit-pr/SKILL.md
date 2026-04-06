---
name: babysit-pr
description: Monitor Bitrise CI and automatically fix failures for pull requests
disable-model-invocation: true
argument-hint: "[PR number or URL] [--max-retries N]"
---

# Babysit PR

You are babysitting a pull request for the stripe-ios repository. Your job is to push code, monitor Bitrise CI, and fix failures automatically until CI passes.

**Arguments:** $ARGUMENTS
- No arguments: push current branch, create/find a draft PR, monitor and fix
- A PR number or URL: skip to monitoring that existing PR
- `--max-retries N`: override the default max retry count (default: 3)

---

## Step 1: Setup and Push

1. **Verify branch**: Confirm you are NOT on `master`. If on master, stop and tell the user to check out a branch.

2. **Check for uncommitted changes**: Run `git status`. If there are uncommitted changes, ask the user whether to commit them first.

3. **Push the branch**:
   ```
   git push -u origin HEAD
   ```

4. **Find or create a PR**:
   - Check for existing PR: `GH_HOST=github.com gh pr view --json number,url,title,headRefName 2>/dev/null`
   - If no PR exists: `GH_HOST=github.com gh pr create --draft --fill`
   - Record the **PR number**, **branch name**, and **PR URL**.
   - Show the PR URL to the user.

If `$ARGUMENTS` contains a PR number or URL, use that instead and skip to Step 2.

---

## Step 2: Find the Bitrise App

Use the Bitrise MCP `list_apps` tool to find the app for this repository. Look for an app whose repository URL contains `stripe-ios`. Record the **app slug** for all subsequent Bitrise API calls.

---

## Step 3: Monitor the Build

1. Use the Bitrise MCP `list_pipelines` tool with the app slug, filtered by the branch name, to find the most recent pipeline triggered by your push. If the pipeline doesn't appear yet, wait 30 seconds and try again (up to 3 attempts).

2. Record the **pipeline ID**.

3. Check the pipeline status using `get_pipeline`:
   - If status is still running (`not_finished` or similar): set up polling.
   - If already finished: skip to Step 4.

4. **Set up polling** with `CronCreate`:
   - Schedule: `*/3 * * * *` (every 3 minutes)
   - Prompt: Check the Bitrise pipeline status using the recorded app slug and pipeline ID. Report which workflows have completed and which are still running. If the pipeline has finished, report the final status.

5. When the pipeline finishes, **delete the cron job** with `CronDelete`.

6. Report the overall result to the user.

---

## Step 4: Handle Build Results

### If all workflows pass
Report success to the user:
> All Bitrise CI checks passed for PR #NNN. The PR is green.

Stop here.

### If any workflow fails
For each failed workflow:

1. **Identify the failure**: Use `get_build` and `get_build_steps` on the failed build to find which step failed.

2. **Get failure details**: Use `get_build_log` to fetch the log for the failed build. Focus on error messages near the end of the log.

3. **Categorize and fix** based on the failing workflow:

   **lint-tests** (SwiftLint, format checks):
   - Run `ci_scripts/lint_modified_files.sh` and `ci_scripts/format_modified_files.sh` locally to reproduce and fix.

   **framework-tests** (unit tests, snapshot tests):
   - Parse the test failure from the log to get the test name and assertion error.
   - Read the failing test file and the code under test.
   - Fix the bug in the source code (not the test, unless the test itself is wrong).
   - If **snapshot tests** fail on UI you intentionally changed, offer to re-record:
     ```
     ci_scripts/run_tests.rb --record-snapshots --test <TestTarget/TestClass/testMethod>
     ```
   - Run the specific test locally to verify:
     ```
     ci_scripts/run_tests.rb --test <TestTarget/TestClass/testMethod>
     ```

   **ui-tests-paymentsheet / ui-tests-connect / ui-tests-crypto**:
   - Check if the failure looks like a flake (timeout, simulator boot failure, `XCTestError`).
   - If it looks flaky and the test wasn't modified in this branch, suggest retrying CI without code changes.
   - If it's a real failure, analyze the test and fix.

   **test-builds-xcode-16 / test-builds-xcode-26** (compilation):
   - Fix the Swift compilation errors shown in the log.
   - Build locally to verify: `ci_scripts/run_tests.rb --scheme <Scheme> --build-only`

   **integration-all** (network-dependent tests):
   - Often flaky due to network issues. Check if the failure is in test setup vs actual assertion.
   - If it looks transient, suggest retrying CI.

   **install-tests** (CocoaPods/SPM):
   - Check for Package.swift or podspec issues.

4. **Verify locally** before pushing: Run the relevant test or build command using `ci_scripts/run_tests.rb`.

5. **Commit and push** the fix.

6. **Go back to Step 3** to monitor the new build triggered by the push.

---

## Step 5: Safety Guardrails

Follow these rules strictly:

- **Max retries**: Stop after 3 fix-and-push cycles (or the value from `--max-retries`). After hitting the limit, report all remaining failures and stop.
- **Never force push** without explicitly asking the user first.
- **Never modify tests just to make them pass**. Understand the actual issue first. If a test was intentionally written to verify behavior, fix the code, not the test.
- **Flaky test detection**: If a test that was NOT modified in this branch fails with a transient-looking error (timeout, simulator issue, network error), flag it as likely flaky. Ask the user whether to retry CI without code changes (push an empty commit: `git commit --allow-empty -m "Retry CI" && git push`).
- **Ask before major changes**: If the fix requires modifying more than 3 files or changing public API, describe the proposed fix and get user approval first.
- **Track changes**: Keep a running list of all files modified across retry cycles. Include this in the final summary.

---

## Step 6: Final Report

When done (either success or max retries reached), provide a summary:

- PR URL and final CI status
- Number of fix cycles performed
- List of all files modified with brief descriptions of each fix
- Any remaining failures (if max retries reached)
- Any flaky tests observed
