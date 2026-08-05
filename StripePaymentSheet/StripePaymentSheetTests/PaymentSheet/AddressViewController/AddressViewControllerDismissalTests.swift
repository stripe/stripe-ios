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
            "GB": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
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
        // Given a freshly presented (empty) address form
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(configuration: makeConfiguration(), delegate: delegate)

        // Then there are no changes yet
        XCTAssertFalse(vc.hasChanges)

        // When the customer edits a field
        // (edit `name`, which is always present — for an empty form the street field starts in
        // autocomplete mode where `line1` is nil until the customer expands to manual entry)
        vc.addressSection?.name?.setText("Jane Doe")

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

    func test_hasChanges_detectsEmptyPhoneCountryChangeAndDiscardRestoresIt() throws {
        // Given a form with an empty optional phone field
        var config = makeConfiguration()
        config.additionalFields.phone = .optional
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(configuration: config, delegate: delegate)
        let phone = try XCTUnwrap(vc.addressSection?.phone)
        let initialCountryCode = phone.selectedCountryCode
        XCTAssert(phone.phoneNumber?.isEmpty == true)
        XCTAssertFalse(vc.hasChanges)

        // When the customer changes only the phone country
        phone.setSelectedCountryCode(initialCountryCode == "GB" ? "US" : "GB")

        // Then the form is considered changed
        XCTAssertTrue(vc.hasChanges)

        // When the customer discards the change
        vc.discardChanges()

        // Then the original phone country is restored
        XCTAssertEqual(phone.selectedCountryCode, initialCountryCode)
        XCTAssertFalse(vc.hasChanges)
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

    func test_save_reBaselinesChangeTrackingForReusedInstance() {
        // Given a seeded form the customer has edited
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        vc.addressSection?.line1?.setText("999 New St")
        XCTAssertTrue(vc.hasChanges)

        // When the customer saves (Continue)
        vc.didContinue()

        // Then the saved values become the new baseline: the same instance can be presented
        // again showing these values, and there are now no unsaved changes to detect.
        // (Before the fix the baseline stayed at first-init, so this remained true.)
        XCTAssertFalse(vc.hasChanges)

        // ...and tapping 'X' (as if reopened with no edits) finishes without a discard alert,
        // returning the saved address rather than the stale first-init value
        STPAnalyticsClient.sharedClient._testLogHistory = []
        vc.didTapCloseButton()
        XCTAssertNil(vc.presentedViewController)
        XCTAssertEqual(delegate.lastAddress?.address.line1, "999 New St")
    }

    func test_save_clearsAutocompleteResultForNextSave() {
        // Given a valid autocomplete result
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        vc.didSelectAddress(
            PaymentSheet.Address(
                city: "San Francisco",
                country: "US",
                line1: "1 Market St.",
                postalCode: "94105",
                state: "California"
            )
        )
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When the customer saves
        vc.didContinue()

        // Then the save is attributed to autocomplete
        let firstSave = STPAnalyticsClient.sharedClient._testLogHistory.last {
            $0["event"] as? String == "mc_address_completed"
        }
        let firstSaveData = firstSave?["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(firstSaveData?["auto_complete_result_selected"] as? Bool, true)

        // When the reused controller saves again without another autocomplete selection
        STPAnalyticsClient.sharedClient._testLogHistory = []
        vc.didContinue()

        // Then the previous autocomplete result is not attributed to the new save
        let secondSave = STPAnalyticsClient.sharedClient._testLogHistory.last {
            $0["event"] as? String == "mc_address_completed"
        }
        let secondSaveData = secondSave?["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(secondSaveData?["auto_complete_result_selected"] as? Bool, false)
    }

    func test_discardChanges_revertsFormToAsOpenedState() {
        // Given a form seeded with a valid default address that the customer has edited
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(
            configuration: makeConfiguration(defaultValues: validDefaultValues),
            delegate: delegate
        )
        vc.addressSection?.line1?.setText("999 Changed Ave")
        XCTAssertTrue(vc.hasChanges)

        // When the customer discards changes
        vc.discardChanges()

        // Then the form is reverted to the as-opened values
        XCTAssertEqual(vc.addressSection?.addressDetails.address.line1, "510 Townsend St.")
        XCTAssertFalse(vc.hasChanges)
        // ...and the delegate finishes once with the as-opened address, not the edited value
        XCTAssertEqual(delegate.didFinishCallCount, 1)
        XCTAssertEqual(delegate.lastAddress?.address.line1, "510 Townsend St.")
    }

    func test_discardChanges_clearsFieldAddedOverEmptyBaseline() {
        // Given a form with the phone field enabled and no default values (baseline phone is nil)
        var config = makeConfiguration()
        config.additionalFields.phone = .optional
        let delegate = MockDelegate()
        let vc = makeLoadedAddressViewController(configuration: config, delegate: delegate)

        // When the customer enters a phone number...
        vc.addressSection?.phone?.setPhoneNumber("4085551234")
        XCTAssertTrue(vc.hasChanges)

        // ...and then discards changes
        vc.discardChanges()

        // Then the phone is cleared back to the empty baseline. (This needs clear-then-populate:
        // populate alone skips phone when the baseline had none, leaving the added value stale.)
        XCTAssert(vc.addressSection?.phone?.phoneNumber?.isEmpty == true)
        XCTAssertFalse(vc.hasChanges)
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
