---
name: delegate-low-reasoning-work
description: Use when running routine tests, builds, lint, formatting, snapshot or generated-output checks, or verbose output collection in stripe-ios. Delegate independent low-judgment execution to a low-cost subagent to preserve the main context while retaining simulator constraints.
---

# Delegate Routine Work

Delegate routine, verbose work when the client has a lower-cost subagent available. Keep responsibility for intent, command selection, implementation choices, diagnosis, and the final conclusion in the main conversation.

## What to delegate

- Every exact local test or build command using `ci_scripts/run_tests.rb`, `xcodebuild`, or Fastlane.
- Exact lint, formatting, snapshot-diff, and generated-output validation commands.
- Mechanical log, `.xcresult`, failure-attachment, and file-inventory collection.
- Repeating an explicit command across independently scoped schemes or targets.

## Select the executor

Use the least capable available agent that can execute the task reliably. Prefer the client's low-cost profile, such as Haiku or Luna when available. If no appropriate subagent or delegation slot is available, run the command in the main session and say why.

Do not delegate authored code changes, architectural decisions, command selection, failure diagnosis, snapshot review, security-sensitive review, or user-facing conclusions. If the exact command intentionally formats or generates files, prohibit any additional edits and review the resulting diff in the main session.

## Give a narrow contract

State the exact command, working directory, relevant timeout, scheme or test selector, and simulator or device constraint. State whether the command may update files; otherwise require no file edits. Ask for a compact result containing the exit status, elapsed time, failing test or build target names, the `.xcresult` path if present, and no more than 80 relevant log lines.

```text
Run ci_scripts/run_tests.rb --scheme StripePaymentSheet --build-only from the repository root. Do not edit files.
Return the exit status, elapsed time, failing build targets if any, the xcresult path if present, and at most 80 relevant log lines.
```

## Verify and continue

Treat the returned output as evidence, not a conclusion. Inspect structured failure output and exported screenshot attachments when relevant, then triage failures and decide the next action in the main session. If the task grows beyond the original contract, delegate a newly bounded command or handle the reasoning directly.
