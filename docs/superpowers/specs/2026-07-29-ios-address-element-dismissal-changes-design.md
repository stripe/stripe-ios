# (iOS) Dismissal Changes — Address Element

**Date:** 2026-07-29
**Scope:** Existing Address Element (`AddressViewController` + SwiftUI `AddressElement`) only.
**Source:** "(iOS) Dismissal Changes" section of the Checkout Sessions SAE design doc, Option 1 (proposed).

## Problem

Today the shipped Address Element saves whatever address is currently entered whenever the
sheet is dismissed — the 'X' button, a swipe-to-dismiss, and the Continue button all funnel
through `didContinue()`, which calls
`delegate.addressViewControllerDidFinish(with: addressDetails)` using the *live* form value
(a valid address, or `nil` if incomplete). Saving on dismiss has received negative merchant
feedback: customers who tap 'X' or swipe to back out unintentionally overwrite/commit an
address they meant to abandon.

This spec updates the existing AE so dismissing is a true cancel, while an explicit Continue
remains the only save.

Out of scope (tracked separately in the doc's "Next Steps"): the Checkout Sessions Shipping
Address Element (SAE) — it has no UI component on iOS yet, only a data/API layer
(`Checkout.updateShippingAddress`) — plus React Native and public documentation updates.

## Target behavior

| Exit path | Condition | Result |
|---|---|---|
| **Continue** button (enabled only when the address is valid) | — | Save: log completion, then `addressViewControllerDidFinish(with: <entered address>)`. Unchanged. |
| **'X'** button | no changes since presentation | Cancel: `addressViewControllerDidFinish(with: <original address>)`. No completion log. |
| **'X'** button | changes made since presentation | Present alert **"Discard changes?"**. **Discard** → cancel (finish with original address, no completion log). **Keep Editing** → dismiss the alert, stay on the sheet. |
| **Swipe-to-dismiss** | any | Blocked entirely (does nothing). |

Key points:
- The **Continue button is the only save path.** The 'X' button is a pure cancel.
- On cancel, the delegate receives the **address the sheet was presented with** (the seeded
  default, or `nil` if the sheet opened empty) — never the edited-but-abandoned value.
- The public UIKit delegate API is **unchanged**: still the single
  `addressViewControllerDidFinish(_:with:)`. Only the value returned on cancel changes. This is
  a deliberate silent behavior change for existing merchants, which the doc's Option 1 accepts.

## Design decisions

1. **Alert = Discard / Keep Editing only** (no "Save" action in the alert). Saving is done only
   via the Continue button. This avoids the footgun of a "Save" action that would produce `nil`
   when the form is invalid, and keeps a single, unambiguous save affordance.
2. **Swipe is blocked entirely** (not "blocked only when dirty"). `isModalInPresentation`
   defaults to `false`, so `presentationControllerShouldDismiss(_:)` is consulted; returning
   `false` blocks the interactive swipe (and iPad form-sheet tap-outside). No prompt is shown on
   a swipe attempt — the gesture simply does nothing.
3. **Analytics:** `logAddressCompleted` fires **only on save** (Continue), not on cancel. This
   changes the existing AE's analytics so the "completed" event reflects an actual completion.
   (Per the doc, the SAE gets its own new event names; that is separate from this change.)

## Implementation

### `AddressViewController.swift`

**Snapshot the "as-presented" state.** In `loadUI()`, immediately after
`self.addressSection = makeDefaultAddressSection()` seeds the form, capture:
- `initialAddressDetails: AddressDetails?` — the public payload derived from the seeded form
  (i.e. the current value of the existing computed `addressDetails` at seed time). `nil` when
  the sheet opens empty. This is what cancel/discard returns.
- `initialFormSnapshot: AddressSectionElement.AddressDetails` — the raw
  `addressSection.addressDetails` at seed time, plus the additional-fields checkbox selected
  state. Used for change detection. (`AddressSectionElement.AddressDetails` is `Equatable`; it
  is already compared with `==` elsewhere in this file.)

**Change detection.** A computed `hasChanges: Bool` comparing the current raw form values
(`addressSection.addressDetails` + additional-fields checkbox state) against
`initialFormSnapshot`. Raw values are used (not the public `addressDetails`, which is `nil`
while invalid) so a partial/invalid edit still counts as a change. Returns `false` before the
form has loaded.

**Split the finish path.**
- `func finish(with addressDetails: AddressDetails?)` — just
  `delegate?.addressViewControllerDidFinish(self, with: addressDetails)`. No logging.
- `func didContinue()` (Continue button, save) — `logAddressCompleted()` then
  `finish(with: addressDetails)` (live form value). This preserves today's save behavior.
- `@objc func didTapCloseButton()` — if `hasChanges`, present the discard alert; otherwise
  `finish(with: initialAddressDetails)` (no log).
- Discard alert action → `finish(with: initialAddressDetails)` (no log).

**Discard alert.** Build a `UIAlertController` inline (mirroring the CustomerSheet
"close form" prompt pattern):
- title: `String.Localized.discard_changes_title`
- `.cancel` action: `String.Localized.keep_editing` (dismisses the alert, no-op)
- `.destructive` action: `String.Localized.discard_changes` → `finish(with: initialAddressDetails)`

Present on `self` via `present(_:animated:)`.

**Block swipe.** The VC is already the presentation-controller delegate (set in
`viewDidAppear`: `navigationController?.presentationController?.delegate = self`). Replace the
existing `presentationControllerWillDismiss(_:) { didContinue() }` (the source of today's
save-on-swipe) with `presentationControllerShouldDismiss(_:) -> Bool { false }`.

### `AddressViewController+SwiftUI.swift`

The 'X'/alert/`hasChanges` logic lives entirely in the shared `AddressViewController`, so the
SwiftUI path inherits it. Two `Coordinator` changes:
- Replace `presentationControllerDidDismiss(_:) { addressViewController?.didContinue() }` with
  `presentationControllerShouldDismiss(_:) -> Bool { false }`.
- Set `isModalInPresentation = true` on the `UINavigationController` we create in
  `makeUIViewController` (belt-and-suspenders, since we own that controller here).

The deferred (0.3s) binding write in `addressViewControllerDidFinish` is unchanged; on cancel
the binding is now written with the original address.

### Localized strings — `StripePaymentSheet/.../Source/Categories/String+Localized.swift`

New `static var`s wrapping `STPLocalizedString`, following the existing convention:
- `discard_changes_title` — "Discard changes?"
- `discard_changes` — "Discard Changes"
- `keep_editing` — "Keep Editing"

## Testing

New unit test file `AddressViewControllerDismissalTests.swift` (alongside the existing
`AddressViewControllerSnapshotTests.swift`), using a preloaded `AddressSpecProvider` so the
form is built synchronously and a mock `AddressViewControllerDelegate`:

- `hasChanges` is `false` right after load; becomes `true` after editing a field / toggling the
  checkbox.
- Close with no changes → delegate receives the original (seeded) address; `nil` for an
  empty-seeded sheet; no completion analytic.
- Close with a valid seeded default, no changes → delegate receives that seeded address.
- Close with changes → an alert is presented and the delegate is **not** yet called.
- Discard action → delegate receives the original address (not the edited value).
- Continue → delegate receives the entered address; completion analytic fires.
- `presentationControllerShouldDismiss` returns `false`.

Existing snapshot tests are unaffected — the rendered form does not change, and the alert is a
system `UIAlertController`.

## Risks / call-outs

- **Silent behavior change** for merchants using the existing AE: the delegate now returns the
  original address on cancel instead of the edited value. Accepted per the doc's Option 1
  (Option 3, which would rev the delegate API, was not chosen).
- **Presentation-controller delegate hijacking in push style** is pre-existing (the VC already
  assigns itself as the presentation delegate in `viewDidAppear`); this change only alters the
  delegate method behavior, so it introduces no new hijacking.
