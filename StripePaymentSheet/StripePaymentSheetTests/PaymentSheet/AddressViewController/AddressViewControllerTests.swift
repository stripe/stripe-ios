//
//  AddressViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

@MainActor
final class AddressViewControllerTests: XCTestCase {
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

    func testDefaultSaveHandlerFinishesWithoutLoading() async {
        // Given a valid address and the default save handler
        let delegateCalled = expectation(description: "Delegate called")
        let delegate = TestAddressViewControllerDelegate()
        delegate.onFinish = { delegateCalled.fulfill() }
        let viewController = makeViewController(delegate: delegate)

        // When the customer saves
        viewController.didTapSaveButton()
        await fulfillment(of: [delegateCalled], timeout: 1)

        // Then the delegate is notified with the address without showing loading
        XCTAssertEqual(delegate.addresses.count, 1)
        XCTAssertEqual(delegate.addresses.first.flatMap { $0 }?.address.line1, "510 Townsend St.")
        XCTAssertEqual(viewController.button.status, .enabled)
        XCTAssertTrue(viewController.view.isUserInteractionEnabled)
        XCTAssertTrue(closeButton(in: viewController)?.isEnabled ?? false)
    }

    func testSaveHandlerControlsLoadingAndFinishesAfterSuccess() async {
        // Given a save handler that shows loading while its work is in flight
        let saveStarted = expectation(description: "Save started")
        let delegateCalled = expectation(description: "Delegate called")
        let saveHandler = TestAddressViewControllerSaveHandler()
        saveHandler.shouldSuspend = true
        saveHandler.showsLoading = true
        saveHandler.onSave = { saveStarted.fulfill() }
        let delegate = TestAddressViewControllerDelegate()
        delegate.onFinish = { delegateCalled.fulfill() }
        let viewController = makeViewController(delegate: delegate, saveHandler: saveHandler)

        // When the customer saves
        viewController.didTapSaveButton()
        await fulfillment(of: [saveStarted], timeout: 1)

        // Then the UI is locked and the delegate has not been notified
        XCTAssertEqual(saveHandler.addresses.count, 1)
        XCTAssertEqual(saveHandler.addresses.first?.address.line1, "510 Townsend St.")
        XCTAssertTrue(delegate.addresses.isEmpty)
        XCTAssertEqual(viewController.button.status, .spinnerWithInteractionDisabled)
        XCTAssertFalse(viewController.view.isUserInteractionEnabled)
        XCTAssertFalse(closeButton(in: viewController)?.isEnabled ?? true)

        // When Save is tapped again and the original save completes
        viewController.didTapSaveButton()
        XCTAssertEqual(saveHandler.addresses.count, 1)
        saveHandler.resume()
        await fulfillment(of: [delegateCalled], timeout: 1)

        // Then the delegate is notified once and interaction is restored
        XCTAssertEqual(delegate.addresses.count, 1)
        XCTAssertEqual(viewController.button.status, .enabled)
        XCTAssertTrue(viewController.view.isUserInteractionEnabled)
        XCTAssertTrue(closeButton(in: viewController)?.isEnabled ?? false)
    }

    func testSaveHandlerCanOptOutOfLoading() async {
        // Given a save handler whose work is in flight without showing loading
        let saveStarted = expectation(description: "Save started")
        let delegateCalled = expectation(description: "Delegate called")
        let saveHandler = TestAddressViewControllerSaveHandler()
        saveHandler.shouldSuspend = true
        saveHandler.onSave = { saveStarted.fulfill() }
        let delegate = TestAddressViewControllerDelegate()
        delegate.onFinish = { delegateCalled.fulfill() }
        let viewController = makeViewController(delegate: delegate, saveHandler: saveHandler)

        // When the customer saves
        viewController.didTapSaveButton()
        await fulfillment(of: [saveStarted], timeout: 1)

        // Then the UI remains unchanged while duplicate saves are still ignored
        XCTAssertEqual(viewController.button.status, .enabled)
        XCTAssertTrue(viewController.view.isUserInteractionEnabled)
        XCTAssertTrue(closeButton(in: viewController)?.isEnabled ?? false)
        viewController.didTapSaveButton()
        XCTAssertEqual(saveHandler.addresses.count, 1)

        // When the save completes
        saveHandler.resume()
        await fulfillment(of: [delegateCalled], timeout: 1)

        // Then the delegate is notified
        XCTAssertEqual(delegate.addresses.count, 1)
    }

    func testFailedSaveShowsErrorAndCanRetry() async {
        // Given a handler that shows loading and fails its first save
        let saveStarted = expectation(description: "Save started")
        let saveFinished = expectation(description: "Save finished")
        let saveHandler = TestAddressViewControllerSaveHandler()
        saveHandler.error = AddressSaveTestError.saveFailed
        saveHandler.shouldSuspend = true
        saveHandler.showsLoading = true
        saveHandler.onSave = { saveStarted.fulfill() }
        saveHandler.onSaveFinished = { saveFinished.fulfill() }
        let delegate = TestAddressViewControllerDelegate()
        let viewController = makeViewController(delegate: delegate, saveHandler: saveHandler)

        // When the customer saves
        viewController.didTapSaveButton()
        await fulfillment(of: [saveStarted], timeout: 1)
        saveHandler.resume()
        await fulfillment(of: [saveFinished], timeout: 1)

        // Then the error is displayed without completing or locking the form
        XCTAssertTrue(delegate.addresses.isEmpty)
        XCTAssertEqual(viewController.errorLabel.text, AddressSaveTestError.saveFailed.localizedDescription)
        XCTAssertEqual(viewController.button.status, .enabled)
        XCTAssertTrue(viewController.view.isUserInteractionEnabled)
        XCTAssertTrue(closeButton(in: viewController)?.isEnabled ?? false)

        // When the customer retries and the save succeeds
        let delegateCalled = expectation(description: "Delegate called")
        delegate.onFinish = { delegateCalled.fulfill() }
        saveHandler.error = nil
        saveHandler.shouldSuspend = false
        saveHandler.onSave = nil
        saveHandler.onSaveFinished = nil
        viewController.didTapSaveButton()
        await fulfillment(of: [delegateCalled], timeout: 1)

        // Then the retry completes and clears the error
        XCTAssertEqual(saveHandler.addresses.count, 2)
        XCTAssertEqual(delegate.addresses.count, 1)
        XCTAssertTrue(viewController.errorLabel.isHidden)
    }

    func testCloseBypassesSaveHandler() {
        // Given a custom save handler
        let saveHandler = TestAddressViewControllerSaveHandler()
        let delegate = TestAddressViewControllerDelegate()
        let viewController = makeViewController(delegate: delegate, saveHandler: saveHandler)

        // When the customer closes the address view
        viewController.didTapCloseButton()

        // Then existing cancellation behavior is preserved without saving
        XCTAssertTrue(saveHandler.addresses.isEmpty)
        XCTAssertEqual(delegate.addresses.count, 1)
        XCTAssertEqual(delegate.addresses.first.flatMap { $0 }?.address.line1, "510 Townsend St.")
    }

    private func makeViewController(
        delegate: AddressViewControllerDelegate,
        saveHandler: AddressViewControllerSaveHandler = DefaultAddressViewControllerSaveHandler()
    ) -> AddressViewController {
        var configuration = AddressViewController.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_1234")
        configuration.defaultValues = .init(
            address: .init(
                city: "San Francisco",
                country: "US",
                line1: "510 Townsend St.",
                postalCode: "94103",
                state: "CA"
            ),
            name: "Jane Doe",
            phone: nil
        )
        let viewController = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: delegate,
            saveHandler: saveHandler
        )
        viewController.loadViewIfNeeded()
        return viewController
    }

    private func closeButton(in viewController: AddressViewController) -> UIButton? {
        viewController.navigationItem.leftBarButtonItem?.customView as? UIButton
    }
}

@MainActor
private final class TestAddressViewControllerDelegate: AddressViewControllerDelegate {
    var addresses: [AddressViewController.AddressDetails?] = []
    var onFinish: (() -> Void)?

    func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        addresses.append(address)
        onFinish?()
    }
}

@MainActor
private final class TestAddressViewControllerSaveHandler: AddressViewControllerSaveHandler {
    var addresses: [AddressViewController.AddressDetails] = []
    var error: Error?
    var shouldSuspend = false
    var showsLoading = false
    var onSave: (() -> Void)?
    var onSaveFinished: (() -> Void)?
    private var continuation: CheckedContinuation<Void, Never>?

    func save(
        address: AddressViewController.AddressDetails,
        setLoading: (Bool) -> Void
    ) async throws {
        addresses.append(address)
        if showsLoading {
            setLoading(true)
        }
        if shouldSuspend {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                onSave?()
            }
        } else {
            onSave?()
        }
        if showsLoading {
            setLoading(false)
        }
        onSaveFinished?()
        if let error {
            throw error
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

private enum AddressSaveTestError: LocalizedError {
    case saveFailed

    var errorDescription: String? {
        "The address could not be saved."
    }
}
