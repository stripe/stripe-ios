  Before filing, check existing `ISSUE_*.md` files for the same root cause (parallel agents may
  cover overlapping code). If found, do not file a duplicate — note it instead.

  Verification: you may edit any source in this worktree, including test infra helpers like
  `STPTestingAPIClient+Swift.swift` — this is a temporary branch, nothing gets pushed. Prefer a
  live repro against the real test backend (`createCheckoutSession(...)` and friends, which can
  construct arbitrary Checkout Session configs) over a stubbed/mocked unit test when you're
  checking a claim against actual backend behavior, not just your own code's internal logic.
  Commit repro tests you write, even though they won't be pushed, so they stay in the local
  branch history next to the `ISSUE_*.md` files.

  If you find no client-side code at all modeling a documented-as-unsupported feature, that
  absence is itself worth filing — don't treat "there's nothing to map the claim to" as
  inconclusive and drop it. File it with lower confidence if you haven't confirmed actual runtime
  behavior via a live repro, higher confidence if you have.

  When you have identified a potential issue:
  - Identify the minimal repro/trigger condition.
  - Reproduce it in a minimal test with as few mocks as possible. E2E ideal, with video - but not all warrant (eg bad input -> bad config may not require, functional test ok there).
  - Trace the ACTUAL reachable call path end to end before writing anything up. Don't assume a
    caller giving up (a timeout, an abandoned await) means the underlying work was canceled —
    for unstructured Tasks in this codebase it isn't, unless something explicitly calls
    `.cancel()` on that specific Task. Grep for `.cancel()`/`isCancelled`/`checkCancellation` on
    the path you're claiming, don't assert reachability you haven't checked.
  - Produce a `ISSUE_[surface]_[description].md` file using exactly this template. Do not deviate,
    do not add extra sections:

    ```
    Summary: [concrete impact, starting from the merchant/customer e.g. call public API x or do xyz in the UI -> ... -> bug]
    Repro: [clear, simple steps to repro]
    Test: [test file and name of test]
    Elaboration: Can go slightly more indepth on why this bug occurs.
    ```

    `[surface]` is the area you were assigned (keeps filenames collision-free across parallel
    agents and lets a human sort by surface).

  Do not file: style/lint nitpicks, already-tracked issues, or anything without a concrete trigger
  condition ("this could theoretically..." is not a bug report - i expect you to scrap bugs as you fail to go down the list above).
