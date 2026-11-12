  Use the [Mobile Checkout Elements Bug Tracker](https://docs.google.com/document/d/1bV3WyCppVILnOFxwnyVmY0bFxOTO_5gd3LsZ0xzLrD0/edit)
  as the source of truth for bug reports, root causes, manifestations, and status. Existing
  repository issue files are historical evidence. Do not create or maintain repository files
  to track bugs.

  At the start of each bug investigation, read the current tracker using Google Docs/Drive
  tools, including its How to use, Status, Index, Bugs, and Template sections. Follow the
  document's current instructions and template when managing bugs.

  Before reporting or updating a bug, re-read the tracker and check for the same root cause
  (parallel agents may cover overlapping code). Keep one entry per root cause: add a new
  manifestation to an existing entry when applicable, or update its existing manifestation
  with new evidence. If the root cause is unknown, create an entry with root cause "Unknown";
  merge entries that share a root cause once it is established, preserving their manifestations.

  Verification: you may edit any source in this worktree, including test infra helpers like
  `STPTestingAPIClient+Swift.swift` — this is a temporary branch, nothing gets pushed. Prefer a
  live repro against the real test backend (`createCheckoutSession(...)` and friends, which can
  construct arbitrary Checkout Session configs) over a stubbed/mocked unit test when you're
  checking a claim against actual backend behavior, not just your own code's internal logic.
  Do not run `git add`/`git commit` for repro code. Leave repro tests and source changes
  uncommitted in the worktree; publish bug reports directly to the tracker.

  Known unfinished preview features are out of scope per the user's 2026-11-03 direction.
  Do not file absence of their implementation as a bug. Focus on supported flows and concrete
  incorrect outcomes; respect documented integration preconditions when assessing reachability.

  When you have identified a potential issue:
  - Identify the minimal repro/trigger condition.
  - Reproduce it in a minimal test with as few mocks as possible. E2E ideal, with video - but not all warrant (eg bad input -> bad config may not require, functional test ok there).
  - Trace the ACTUAL reachable call path end to end before writing anything up. Don't assume a
    caller giving up (a timeout, an abandoned await) means the underlying work was canceled —
    for unstructured Tasks in this codebase it isn't, unless something explicitly calls
    `.cancel()` on that specific Task. Grep for `.cancel()`/`isCancelled`/`checkCancellation` on
    the path you're claiming, don't assert reachability you haven't checked.
  - Update the tracker itself using Google Docs/Drive editing tools. For a new root cause,
    copy the document's current template into its Bugs section, choose an unused BUG-# ID,
    and add a matching Index row. Record the root cause and manifestations in the entry;
    record the summary, status, and affected product areas in the index. Each manifestation
    must describe its trigger conditions, expected behavior, actual behavior, and clear
    playground repro steps. Preserve the document's structure and unrelated entries.
  - Set new reports to "Reported". An agent's reproduction does not qualify as "Human verified";
    that status requires a person to reproduce the bug. Keep the index current as evidence
    establishes human verification, work on a fix, or a merged fix, following the document's
    status definitions. Merge duplicate root-cause entries and reconcile their index rows.
  - After editing, read the tracker again to verify that the entry, manifestations, and matching
    index row were saved correctly. Include the tracker link and BUG-# ID when reporting the
    outcome to the user. A bug report is filed only when the document has been updated.

  If the tracker cannot be read or updated, tell the user what access or tool is missing.
  Do not fall back to repository issue files or claim a bug has been filed without saving it
  in the tracker.

  Do not file: style/lint nitpicks, duplicate reports of already-tracked issues, or anything without
  a concrete trigger condition ("this could theoretically..." is not a bug report - i expect you to scrap bugs as you fail to go down the list above).
