# iOS Address Element Dismissal Changes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing Address Element's 'X' button a true cancel (confirm before discarding changes, return the as-presented address), block swipe-to-dismiss, and log the completion analytic only on an explicit save.

**Architecture:** All decision logic lives in the shared UIKit `AddressViewController`; the SwiftUI wrapper inherits it and only needs its swipe-blocking updated. Cancel returns a snapshot of the address captured when the form loaded; a change is detected by comparing the live form values against that snapshot. Swipe is blocked via `presentationControllerShouldDismiss` returning `false`.

**Tech Stack:** Swift, UIKit, SwiftUI (`UIViewControllerRepresentable`), XCTest, FBSnapshotTestCase, `STPLocalizedString`.

## Global Constraints

- **Scope:** Existing Address Element only (`AddressViewController` + SwiftUI `AddressElement`). Do **not** touch the Checkout Sessions SAE / `Checkout` data layer.
- **Public API unchanged:** The UIKit delegate remains the single `AddressViewControllerDelegate.addressViewControllerDidFinish(_:with:)`. Only the value returned on cancel changes.
- **No AI/tool attribution** in code, comments, or commit messages (user global rule). No "co-authored-by" trailer.
- **No force-unwraps** in Swift (user global rule). Use `guard let` / optional chaining.
- **Don't delete existing comments or make unrelated stylistic/refactor changes.**
- **`stpAssert`** is only for SDK-internal invariants — not used here.
- **Localized strings** are added as `static var` computed properties wrapping `STPLocalizedString(englishValue, translatorComment)` inside `extension String.Localized`.
- **Test runs require the user's approval first** (user global rule); `--build-only` compilation checks do **not**. Only run the newly added tests, never the full suite.
- **Quote paths in double quotes** in bash commands.
- Branch: `gbirch/ae-dismissal-changes` (already created off `master`).

---

## File Structure

- **Modify** `StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController.swift` — snapshot + change detection, finish refactor, cancel/discard, discard alert, swipe blocking.
- **Modify** `StripePaymentSheet/StripePaymentSheet/Source/Categories/String+Localized.swift` — three new alert strings.
- **Modify** `StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController+SwiftUI.swift` — swipe blocking in the SwiftUI `Coordinator` + nav controller.
- **Create** `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/AddressViewController/AddressViewControllerDismissalTests.swift` — UIKit behavior tests.
- **Create** `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/AddressViewControllerRepresentableDismissalTests.swift` — SwiftUI coordinator test.

---

## Task 1: AddressViewController dismissal behavior (UIKit) + alert strings

**Files:**
- Modify: `StripePaymentSheet/StripePaymentSheet/Source/Categories/String+Localized.swift`
- Modify: `StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController.swift`
- Test: `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/AddressViewController/AddressViewControllerDismissalTests.swift`

**Interfaces:**
- Consumes: `String.Localized.discard_changes_title`, `.discard_changes`, `.keep_editing` (added in Step 1); `AddressSectionElement.addressDetails` (`AddressSectionElement.AddressDetails`, `Equatable`); `TextFieldElement.setText(_:)`; `CheckboxElement.checkboxButton.isSelected`.
- Produces (relied on by tests and Task 2 parity):
  - `AddressViewController.hasChanges: Bool` (internal)
  - `AddressViewController.cancelAndFinish()` (internal) — finishes as a cancel with the as-presented address, no completion log
  - `AddressViewController.didContinue()` (internal, unchanged name) — saves the entered address + logs completion
  - `AddressViewController.presentationControllerShouldDismiss(_:) -> Bool` (public) — returns `false`

- [ ] **Step 1: Add the three localized alert strings**

In `String+Localized.swift`, add these inside `extension String.Localized` (place them next to `use_billing_address_for_shipping` for cohesion):

```swift
    static var discard_changes_title: String {
        STPLocalizedString(
            "Discard changes?",
            "Title of a confirmation alert shown when the customer tries to close the address form after making changes."
        )
    }

    static var discard_changes: String {
        STPLocalizedString(
            "Discard Changes",
            "Button title in a confirmation alert that discards the customer's unsaved address changes and closes the form."
        )
    }

    static var keep_editing: String {
        STPLocalizedString(
            "Keep Editing",
            "Button title in a confirmation alert that dismisses the alert and returns the customer to editing their address."
        )
    }
```

- [ ] **Step 2: Write the failing UIKit tests**

Create `AddressViewControllerDismissalTests.swift` with this content:

```swift
//
//  AddressViewControllerDismissalTests.swift
//  StripePaymentSheet Unit Tests
//

@_spi(STP)@testable import StripeCore
import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP)@testable import StripeUICore
import XCTest

final class AddressViewControllerDismissalTests: XCTestCase {

    private let addressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        return specProvider
    }()

    /// Retains the window hosting the VC under test for the duration of a test method.
    private var retainedWindow: UIWindow?

    override func tearDown() {
        retainedWindow = nil
        STPAnalyticsClient.sharedClient._testLogHistory = []
        super.tearDown()
    }

    // MARK: - Helpers

    private final class MockDelegate: AddressViewControllerDelegate {
        private(set) var didFinishCallCount = 0
        private(set) var lastAddress: AddressViewController.AddressDetails?
        func addressViewControllerDidFinish(
            _ addressViewController: AddressViewController,
            with address: AddressViewController.AddressDetails?
        ) {
            didFinishCallCount += 1
            lastAddress = address
        }
    }

    private let validDefaultValues = AddressViewController.Configuration.DefaultAddressDetails(
        address: .init(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        ),
        name: "Jane Doe"
    )

    private func makeConfiguration(
        defaultValues: AddressViewController.Configuration.DefaultAddressDetails = .init()
    ) -> AddressViewController.Configuration {
        var config = AddressViewController.Configuration(defaultValues: defaultValues)
        config.apiClient = .init(publishableKey: "pk_test_1234")
        return config
    }

    private func makeLoadedAddressViewController(
        configuration: AddressViewController.Configuration,
        delegate: AddressViewControllerDelegate
    ) -> AddressViewController {
        let vc = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: delegate
        )
        let navVC = UINavigationController(rootViewController: vc)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 900))
        window.isHidden = false
        window.rootViewController = navVC
        retainedWindow = window
        vc.loadViewIfNeeded()
        return vc
    }

    private func addressCompletedWasLogged() -> Bool {
        STPAnalyticsClient.sharedClient._testLogHistory.contains {
            $0["event"] as? String == "mc_address_completed"
        }
    }

    // MARK: - Tests

    func test_hasChanges_isFalseAfterLoadAndTrueAfterEditingField() {
        // Given a freshly presented address form
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(configuration: makeConfiguration(), delegate: delegate)

        // Then there are no changes yet
        XCTAssertFalse(vc.hasChanges)

        // When the customer edits a field
        vc.addressSection?.line1?.setText("999 Changed Ave")

        // Then the form is considered changed
        XCTAssertTrue(vc.hasChanges)
    }

    func test_hasChanges_detectsCheckboxToggle() {
        // Given a form with an additional-fields checkbox, unselected by default
        var config = makeConfiguration()
        config.additionalFields.checkboxLabel = "Save this address"
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(configuration: config, delegate: delegate)
        XCTAssertFalse(vc.hasChanges)

        // When the customer toggles the checkbox
        vc.checkboxElement?.checkboxButton.isSelected = true

        // Then the form is considered changed
        XCTAssertTrue(vc.hasChanges)
    }

    func test_closeWithNoChanges_finishesWithSeededAddressWithoutAlertOrCompletionLog() {
        // Given a form seeded with a valid default address and no edits
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When the customer taps 'X'
        vc.didTapCloseButton()

        // Then the delegate is finished once with the as-presented address
        XCTAssertEqual(delegate.didFinishCallCount, 1)
        XCTAssertEqual(delegate.lastAddress?.address.line1, "510 Townsend St.")
        XCTAssertEqual(delegate.lastAddress?.name, "Jane Doe")
        // ...and no confirmation alert is shown
        XCTAssertNil(vc.presentedViewController)
        // ...and no completion analytic is logged (cancel is not a completion)
        XCTAssertFalse(addressCompletedWasLogged())
    }

    func test_cancelAndFinish_returnsSeededAddressNotEditedValue() {
        // Given a form seeded with a valid default address the customer has edited
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        vc.addressSection?.line1?.setText("999 Changed Ave")
        XCTAssertTrue(vc.hasChanges)
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When the flow is cancelled (the same path the discard alert action takes)
        vc.cancelAndFinish()

        // Then the delegate receives the ORIGINAL address, not the edited value
        XCTAssertEqual(delegate.didFinishCallCount, 1)
        XCTAssertEqual(delegate.lastAddress?.address.line1, "510 Townsend St.")
        // ...and no completion analytic is logged
        XCTAssertFalse(addressCompletedWasLogged())
    }

    func test_closeWithChanges_presentsDiscardAlertWithoutFinishing() throws {
        // Given a seeded form the customer has edited
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        vc.addressSection?.line1?.setText("999 Changed Ave")

        // When the customer taps 'X'
        vc.didTapCloseButton()

        // Then the delegate is NOT finished yet
        XCTAssertEqual(delegate.didFinishCallCount, 0)

        // ...and a discard confirmation alert is presented (pump the run loop for the async present)
        let presented = expectation(description: "discard alert presented")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { presented.fulfill() }
        wait(for: [presented], timeout: 1.0)

        let alert = try XCTUnwrap(vc.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.actions.count, 2)
        XCTAssertTrue(alert.actions.contains { $0.style == .destructive })
        XCTAssertTrue(alert.actions.contains { $0.style == .cancel })
    }

    func test_didContinue_savesEnteredAddressAndLogsCompletion() {
        // Given a seeded form the customer edits
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        vc.addressSection?.line1?.setText("999 New St")
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When the customer taps Continue (save)
        vc.didContinue()

        // Then the delegate receives the ENTERED address
        XCTAssertEqual(delegate.didFinishCallCount, 1)
        XCTAssertEqual(delegate.lastAddress?.address.line1, "999 New St")
        // ...and a completion analytic is logged
        XCTAssertTrue(addressCompletedWasLogged())
    }

    func test_presentationControllerShouldDismiss_returnsFalseToBlockSwipe() {
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(configuration: makeConfiguration(), delegate: delegate)
        let presentationController = UIPresentationController(
            presentedViewController: UIViewController(),
            presenting: nil
        )
        XCTAssertFalse(vc.presentationControllerShouldDismiss(presentationController))
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

> Requires user approval before running (global rule). Ask, then run:

Run: `ci_scripts/run_tests.rb --test StripePaymentSheetTests/AddressViewControllerDismissalTests`
Expected: FAIL — compile errors ("value of type 'AddressViewController' has no member 'hasChanges' / 'cancelAndFinish'"), because the production code isn't implemented yet.

- [ ] **Step 4: Implement the production changes in `AddressViewController.swift`**

4a. Add stored snapshot properties and the `hasChanges` computed property. Insert immediately after `private var didLogAddressShow = false` (currently line 57):

```swift
    /// The address the sheet was presented with. Returned to the delegate when the customer
    /// cancels (taps 'X' with no changes, or discards changes) so we never hand back
    /// edited-but-abandoned data.
    private var initialAddressDetails: AddressDetails?
    /// A snapshot of the form's raw values when it was first presented, used to detect unsaved changes.
    private var initialFormSnapshot: AddressSectionElement.AddressDetails?
    /// The additional-fields checkbox state when the form was first presented.
    private var initialCheckboxSelected: Bool?

    /// Whether the customer has changed any form value since the sheet was presented.
    var hasChanges: Bool {
        guard let addressSection = addressSection else { return false }
        if addressSection.addressDetails != initialFormSnapshot { return true }
        if checkboxElement?.checkboxButton.isSelected != initialCheckboxSelected { return true }
        return false
    }
```

4b. Capture the snapshot in `loadUI()`. Find (currently line 425):

```swift
        self.addressSection = makeDefaultAddressSection()
```

and add immediately after it:

```swift
        // Snapshot the form's initial state so we can (1) detect unsaved changes and
        // (2) return the as-presented address to the delegate if the customer cancels.
        self.initialAddressDetails = addressDetails
        self.initialFormSnapshot = addressSection?.addressDetails
        self.initialCheckboxSelected = checkboxElement?.checkboxButton.isSelected
```

4c. Split the finish path. Replace the current `didContinue()` (currently lines 322-325):

```swift
    func didContinue() {
        logAddressCompleted()
        delegate?.addressViewControllerDidFinish(self, with: addressDetails)
    }
```

with:

```swift
    /// Notifies the delegate that the sheet is finished with the given address. Does not log completion.
    private func finish(with addressDetails: AddressDetails?) {
        delegate?.addressViewControllerDidFinish(self, with: addressDetails)
    }

    /// Finishes as a cancel: returns the address the sheet was presented with (never the edited
    /// value) and does not log a completion. Used by the close button (no changes) and the
    /// discard-changes alert action.
    func cancelAndFinish() {
        finish(with: initialAddressDetails)
    }

    /// Called when the customer taps the Continue button to save the entered address.
    func didContinue() {
        logAddressCompleted()
        finish(with: addressDetails)
    }
```

4d. Replace the current `didTapCloseButton()` (currently lines 339-341):

```swift
    @objc func didTapCloseButton() {
        didContinue()
    }
```

with:

```swift
    @objc func didTapCloseButton() {
        // Tapping 'X' is a cancel: if the customer changed nothing, dismiss and return the
        // as-presented address; otherwise confirm before discarding their changes.
        if hasChanges {
            presentDiscardChangesAlert()
        } else {
            cancelAndFinish()
        }
    }

    private func presentDiscardChangesAlert() {
        let alertController = UIAlertController(
            title: String.Localized.discard_changes_title,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: String.Localized.keep_editing, style: .cancel))
        alertController.addAction(
            UIAlertAction(title: String.Localized.discard_changes, style: .destructive) { [weak self] _ in
                self?.cancelAndFinish()
            }
        )
        present(alertController, animated: true)
    }
```

4e. Block swipe-to-dismiss. Replace the current `UIAdaptivePresentationControllerDelegate` extension (currently lines 636-641):

```swift
extension AddressViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        didContinue()
    }
}
```

with:

```swift
extension AddressViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Disallow swipe-to-dismiss so an accidental gesture can't discard entered address data.
        // Customers exit via the 'X' button (which confirms if there are unsaved changes) or Continue.
        return false
    }
}
```

- [ ] **Step 5: Verify it compiles (no approval needed)**

Run: `ci_scripts/run_tests.rb --scheme StripePaymentSheet --build-only`
Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Run the tests to verify they pass**

> Requires user approval before running (global rule). Ask, then run:

Run: `ci_scripts/run_tests.rb --test StripePaymentSheetTests/AddressViewControllerDismissalTests`
Expected: PASS (all 7 tests).

- [ ] **Step 7: Commit**

```bash
git add "StripePaymentSheet/StripePaymentSheet/Source/Categories/String+Localized.swift" "StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController.swift" "StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/AddressViewController/AddressViewControllerDismissalTests.swift"
git commit -m "Make Address Element 'X' a cancel and block swipe-to-dismiss

Tapping 'X' now confirms before discarding unsaved changes and returns the
as-presented address on cancel; swipe-to-dismiss is disallowed; the address
completion analytic fires only on an explicit save."
```

---

## Task 2: SwiftUI wrapper swipe blocking

**Files:**
- Modify: `StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController+SwiftUI.swift`
- Test: `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/AddressViewControllerRepresentableDismissalTests.swift`

**Interfaces:**
- Consumes: `AddressViewControllerRepresentable.Coordinator(address:dismiss:)` (internal).
- Produces: `AddressViewControllerRepresentable.Coordinator.presentationControllerShouldDismiss(_:) -> Bool` returning `false`; `isModalInPresentation = true` set on the wrapper-owned `UINavigationController`.

- [ ] **Step 1: Write the failing SwiftUI coordinator test**

Create `AddressViewControllerRepresentableDismissalTests.swift`:

```swift
//
//  AddressViewControllerRepresentableDismissalTests.swift
//  StripePaymentSheet Unit Tests
//

@_spi(STP)@testable import StripePaymentSheet
import SwiftUI
import XCTest

final class AddressViewControllerRepresentableDismissalTests: XCTestCase {

    func test_coordinator_blocksSwipeToDismiss() {
        // Given the SwiftUI wrapper's coordinator
        let coordinator = AddressViewControllerRepresentable.Coordinator(
            address: .constant(nil),
            dismiss: {}
        )
        let presentationController = UIPresentationController(
            presentedViewController: UIViewController(),
            presenting: nil
        )

        // Then swipe-to-dismiss is disallowed
        XCTAssertFalse(coordinator.presentationControllerShouldDismiss(presentationController))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

> Requires user approval before running. Ask, then run:

Run: `ci_scripts/run_tests.rb --test StripePaymentSheetTests/AddressViewControllerRepresentableDismissalTests`
Expected: FAIL — compile error ("value of type 'AddressViewControllerRepresentable.Coordinator' has no member 'presentationControllerShouldDismiss'"), since the coordinator currently implements `presentationControllerDidDismiss` instead.

- [ ] **Step 3: Implement the SwiftUI changes**

3a. Block swipe on the wrapper-owned navigation controller. In `makeUIViewController`, find (currently line 54):

```swift
        let navigationController = UINavigationController(rootViewController: addressViewController)
```

and add immediately after it:

```swift
        // Disallow swipe-to-dismiss so accidental gestures can't discard entered address data.
        navigationController.isModalInPresentation = true
```

3b. Replace the coordinator's swipe handler. Find (currently lines 104-107):

```swift
        // Called after the sheet has been dismissed by a swipe down
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            addressViewController?.didContinue()
        }
```

with:

```swift
        // Disallow swipe-to-dismiss so accidental gestures can't discard entered address data.
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            return false
        }
```

- [ ] **Step 4: Verify it compiles (no approval needed)**

Run: `ci_scripts/run_tests.rb --scheme StripePaymentSheet --build-only`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Run the test to verify it passes**

> Requires user approval before running. Ask, then run:

Run: `ci_scripts/run_tests.rb --test StripePaymentSheetTests/AddressViewControllerRepresentableDismissalTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add "StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController+SwiftUI.swift" "StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/AddressViewControllerRepresentableDismissalTests.swift"
git commit -m "Block swipe-to-dismiss in the SwiftUI Address Element wrapper"
```

---

## Task 3: Verify existing snapshot tests still pass

The dismissal changes don't alter the rendered form, so the existing snapshot suite should be unaffected. Confirm no regression.

**Files:**
- (verification only — no edits expected)

- [ ] **Step 1: Run the existing Address Element snapshot tests**

> Requires user approval before running. Ask, then run:

Run: `ci_scripts/run_tests.rb --test StripePaymentSheetTests/AddressViewControllerSnapshotTests`
Expected: PASS with no snapshot diffs. (If a diff appears, investigate — the change should not affect rendering.)

- [ ] **Step 2: Run the SwiftUI representable snapshot test**

> Requires user approval before running. Ask, then run:

Run: `ci_scripts/run_tests.rb --test StripePaymentSheetTests/AddressViewControllerRepresentableSnapshotTest`
Expected: PASS with no snapshot diffs.

---

## Self-Review (completed while writing this plan)

**Spec coverage:**
- 'X' with no changes → dismiss returning original → Task 1, Step 4d (`didTapCloseButton` → `cancelAndFinish`) + test `test_closeWithNoChanges_...`. ✓
- 'X' with changes → Discard/Keep Editing alert → Task 1, Step 4d (`presentDiscardChangesAlert`) + test `test_closeWithChanges_...`. ✓
- Swipe blocked → Task 1 Step 4e (UIKit) + Task 2 Step 3 (SwiftUI) + tests. ✓
- Cancel returns as-presented address → Task 1, Steps 4a/4b snapshot + `cancelAndFinish` + test `test_cancelAndFinish_returnsSeededAddressNotEditedValue`. ✓
- Continue is the only save; completion logged only on save → Task 1, Step 4c + tests `test_didContinue_...` (logs) and `test_closeWithNoChanges_...`/`test_cancelAndFinish_...` (no log). ✓
- New localized strings → Task 1, Step 1. ✓
- Public delegate API unchanged → no change to `AddressViewControllerDelegate`. ✓
- SwiftUI 0.3s binding write preserved → untouched in Task 2. ✓

**Placeholder scan:** No TBD/TODO; every code step shows complete code. ✓

**Type consistency:** `hasChanges`, `cancelAndFinish()`, `didContinue()`, `finish(with:)`, `initialAddressDetails`, `initialFormSnapshot`, `initialCheckboxSelected`, `presentationControllerShouldDismiss(_:)`, `String.Localized.discard_changes_title/.discard_changes/.keep_editing`, and the `mc_address_completed` event string are used consistently across production and tests. ✓
