---
name: checkout-bug-reporting
description: Investigate and report Mobile Checkout Elements bugs in the shared tracker only when the user explicitly requests this skill.
disable-model-invocation: true
---

# Checkout bug reporting

Run only when the user explicitly invokes this skill or asks to use it. A general bug fix,
code review, or mention of the tracker does not opt in. Limit tracker edits to the requested
bugs; read-only requests and skill creation or editing do not authorize changes to the doc.

Use the [Mobile Checkout Elements Bug Tracker](https://docs.google.com/document/d/1bV3WyCppVILnOFxwnyVmY0bFxOTO_5gd3LsZ0xzLrD0/edit)
as the source of truth for bug management. Read it before investigating or reporting bugs,
and follow its current instructions and template.

Before filing, check the tracker for the same root cause (parallel agents may cover overlapping
code). Add related findings to the existing entry rather than filing a duplicate.

Verification: Prefer a live repro against the real test backend (`createCheckoutSession(...)`
and friends, which can construct arbitrary Checkout Session configs) over a stubbed/mocked
unit test when checking a claim against actual backend behavior, not just your own code's internal logic.
Do not run `git add`/`git commit` for repro code. Leave repro tests and source changes
uncommitted in the worktree.

Known unfinished preview features are out of scope.
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
- File the bug directly in the tracker and update its index. Confirm the changes were saved.

Do not file: style/lint nitpicks, duplicate reports of already-tracked issues, or anything without
a concrete trigger condition ("this could theoretically..." is not a bug report - i expect you to scrap bugs as you fail to go down the list above).
