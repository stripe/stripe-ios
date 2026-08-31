//
//  ShippingAddressElementPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/6/26.

@_spi(STP) @testable import StripeCore
@_spi(AppearanceAPIAdditionsPreview) @_spi(STP) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class ShippingAddressElementPresentationTests: XCTestCase {

    private var window: UIWindow!
    private var presentingViewController: UIViewController!
    private var previousAnalyticsHistory: [[String: Any]]!

    override func setUp() {
        super.setUp()
        previousAnalyticsHistory = STPAnalyticsClient.sharedClient._testLogHistory
        STPAnalyticsClient.sharedClient._testLogHistory = []
        presentingViewController = UIViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presentingViewController
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        presentingViewController.dismiss(animated: false)
        window.isHidden = true
        presentingViewController = nil
        window = nil
        STPAnalyticsClient.sharedClient._testLogHistory = previousAnalyticsHistory
        previousAnalyticsHistory = nil
        super.tearDown()
    }

    func testPresentUsesExplicitPresenterAndExistingAddressViewController() throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()

        // When
        let navigationController = present(shippingAddressElement)

        // Then
        let unwrappedNavigationController = try XCTUnwrap(navigationController)
        XCTAssertTrue(presentingViewController.presentedViewController === unwrappedNavigationController)
        XCTAssertTrue(unwrappedNavigationController.viewControllers.first === shippingAddressElement.addressViewController)
    }

    func testCompletionRunsAfterDelegateDismissesPresentation() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let completionExpectation = expectation(description: "Presentation completion called")
        var presentedViewControllerAtCompletion: UIViewController?
        _ = try XCTUnwrap(present(shippingAddressElement) {
            presentedViewControllerAtCompletion = self.presentingViewController.presentedViewController
            completionExpectation.fulfill()
        })

        // When
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: makeAddressDetails()
        )
        await fulfillment(of: [completionExpectation], timeout: 2)

        // Then
        XCTAssertNil(presentedViewControllerAtCompletion)
    }

    func testAsyncPresentReturnsAfterDismissal() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let presentationExpectation = expectation(description: "Sheet presented")
        let returnExpectation = expectation(description: "Async presentation returned")
        let observingViewController = PresentationObservingViewController()
        observingViewController.onPresent = { _ in
            presentationExpectation.fulfill()
        }
        window.rootViewController = observingViewController
        presentingViewController = observingViewController
        var didReturn = false

        UIView.setAnimationsEnabled(false)
        let presentationTask = Task { @MainActor in
            await shippingAddressElement.present(from: observingViewController)
            didReturn = true
            returnExpectation.fulfill()
        }
        await fulfillment(of: [presentationExpectation], timeout: 2)
        UIView.setAnimationsEnabled(true)
        XCTAssertFalse(didReturn)

        // When
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: nil
        )
        await fulfillment(of: [returnExpectation], timeout: 2)
        await presentationTask.value

        // Then
        XCTAssertTrue(didReturn)
        XCTAssertNil(observingViewController.presentedViewController)
    }

    func testPresentationAndCancellationLogShippingAddressEvents() throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()

        // When
        _ = try XCTUnwrap(present(shippingAddressElement))
        shippingAddressElement.addressViewController.viewDidAppear(false)
        shippingAddressElement.addressViewController.viewDidAppear(false)
        shippingAddressElement.addressViewController.didTapCloseButton()

        // Then
        let events = shippingAddressEvents
        XCTAssertEqual(
            events.compactMap { $0["event"] as? String },
            ["elements.shipping_address.shown", "elements.shipping_address.canceled"]
        )
        events.forEach { assertCommonAnalyticsParameters($0) }
        XCTAssertFalse(STPAnalyticsClient.sharedClient._testLogHistory.contains {
            ["mc_address_show", "mc_address_completed"].contains($0["event"] as? String)
        })
    }

    func testSuccessfulSaveLogsStartedAndCompletedEvents() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let delegate = ShippingAddressElementDelegateMock()
        shippingAddressElement.delegate = delegate

        // When
        try await shippingAddressElement.save(addressDetails: makeAddressDetails())

        // Then
        let events = shippingAddressEvents
        XCTAssertEqual(
            events.compactMap { $0["event"] as? String },
            ["elements.shipping_address.save_started", "elements.shipping_address.save_completed"]
        )
        events.forEach { assertCommonAnalyticsParameters($0) }
    }

    func testFailedSaveLogsStartedAndFailedEvents() async {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let delegate = ShippingAddressElementDelegateMock(
            error: CheckoutError.apiError(message: "Sensitive error details")
        )
        shippingAddressElement.delegate = delegate

        // When
        do {
            try await shippingAddressElement.save(addressDetails: makeAddressDetails())
            XCTFail("Expected save to fail")
        } catch CheckoutError.apiError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Then
        let events = shippingAddressEvents
        XCTAssertEqual(
            events.compactMap { $0["event"] as? String },
            ["elements.shipping_address.save_started", "elements.shipping_address.save_failed"]
        )
        events.forEach { assertCommonAnalyticsParameters($0) }
        XCTAssertNil(events[0]["error_type"])
        XCTAssertNil(events[0]["error_code"])
        XCTAssertEqual(events[1]["error_type"] as? String, "StripePaymentSheet.CheckoutError")
        XCTAssertEqual(events[1]["error_code"] as? String, "apiError")
        XCTAssertFalse(events[1].values.contains { ($0 as? String) == "Sensitive error details" })
    }

    func testCanPresentAgainFromCompletion() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let secondPresentationExpectation = expectation(description: "Second sheet presented")
        _ = try XCTUnwrap(present(shippingAddressElement) {
            XCTAssertNotNil(self.present(shippingAddressElement))
            secondPresentationExpectation.fulfill()
        })

        // When
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: nil
        )
        await fulfillment(of: [secondPresentationExpectation], timeout: 2)

        // Then
        let navigationController = try XCTUnwrap(
            presentingViewController.presentedViewController as? UINavigationController
        )
        XCTAssertTrue(navigationController.viewControllers.first === shippingAddressElement.addressViewController)
    }

    private func makeShippingAddressElement() -> ShippingAddressElement {
        return ShippingAddressElement(
            configuration: .init(),
            initialShippingAddress: .init(
                name: "Jane Doe",
                address: .init(
                    country: "US",
                    line1: "123 Main St.",
                    city: "Seattle",
                    state: "WA",
                    postalCode: "98101"
                )
            ),
            allowedCountries: ["US"],
            checkoutSessionId: "cs_test_123",
            apiClient: STPAPIClient(publishableKey: "pk_test_123"),
            useAutocompleteEndpoints: false
        )
    }

    private func present(
        _ shippingAddressElement: ShippingAddressElement,
        completion: (() -> Void)? = nil
    ) -> UINavigationController? {
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer {
            UIView.setAnimationsEnabled(animationsWereEnabled)
        }
        shippingAddressElement.present(
            from: presentingViewController,
            completion: completion
        )
        return presentingViewController.presentedViewController as? UINavigationController
    }

    private func makeAddressDetails() -> AddressViewController.AddressDetails {
        return .init(
            address: .init(
                city: "Seattle",
                country: "US",
                line1: "123 Main St.",
                postalCode: "98101",
                state: "WA"
            ),
            name: "Jane Doe"
        )
    }

    private var shippingAddressEvents: [[String: Any]] {
        STPAnalyticsClient.sharedClient._testLogHistory.filter {
            ($0["event"] as? String)?.hasPrefix("elements.shipping_address.") == true
        }
    }

    private func assertCommonAnalyticsParameters(
        _ event: [String: Any],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(event["checkout_session_id"] as? String, "cs_test_123", file: file, line: line)
        let addressData = event["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(addressData?["address_country_code"] as? String, "US", file: file, line: line)
        XCTAssertEqual(addressData?.keys.contains("auto_complete_result_selected"), true, file: file, line: line)
        XCTAssertEqual(addressData?.keys.contains("edit_distance"), true, file: file, line: line)
    }
}

private final class PresentationObservingViewController: UIViewController {

    var onPresent: ((UIViewController) -> Void)?

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
        onPresent?(viewControllerToPresent)
    }
}

@MainActor
private final class ShippingAddressElementDelegateMock: ShippingAddressElementDelegate {

    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func updateShippingAddress(name: String?, address: CheckoutController.Address?) async throws {
        if let error {
            throw error
        }
    }
}
