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

    override func setUp() {
        super.setUp()
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
        XCTAssertEqual(unwrappedNavigationController.modalPresentationStyle, .automatic)
    }

    func testCompletionRunsAfterDelegateDismissesPresentation() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let completionExpectation = expectation(description: "Presentation completion called")
        var presentedViewControllerAtCompletion: UIViewController?
        let navigationController = try XCTUnwrap(present(shippingAddressElement) {
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
        XCTAssertTrue(navigationController.viewControllers.isEmpty)
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

    func testSubmittedAddressIsIgnored() async throws {
        // Given
        let configuration = CheckoutTestHelpers.makeConfiguration()
        let checkout = try await Checkout(configuration: configuration)
        let initialShippingAddress = Checkout.Session.ShippingAddress(
            name: "Jenny Rosen",
            address: .init(
                country: "US",
                line1: "510 Townsend St.",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103"
            )
        )
        checkout.dangerouslySetSessionDirectly(
            checkout.session.makeCopyOverriding(shippingAddress: .newValue(initialShippingAddress))
        )
        let shippingAddressElement = checkout.getShippingAddressElement()
        let completionExpectation = expectation(description: "Presentation completion called")
        _ = try XCTUnwrap(present(shippingAddressElement) {
            completionExpectation.fulfill()
        })

        // When
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: makeAddressDetails()
        )
        await fulfillment(of: [completionExpectation], timeout: 2)

        // Then
        XCTAssertEqual(checkout.session.shippingAddress, initialShippingAddress)
    }

    func testSequentialPresentationsUseSeparateNavigationControllersAndCompleteOnce() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        var completionCount = 0
        let firstCompletionExpectation = expectation(description: "First presentation completion called")
        let firstNavigationController = try XCTUnwrap(present(shippingAddressElement) {
            completionCount += 1
            firstCompletionExpectation.fulfill()
        })
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: nil
        )
        await fulfillment(of: [firstCompletionExpectation], timeout: 2)

        // When
        let secondCompletionExpectation = expectation(description: "Second presentation completion called")
        let secondNavigationController = try XCTUnwrap(present(shippingAddressElement) {
            completionCount += 1
            secondCompletionExpectation.fulfill()
        })
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: nil
        )
        await fulfillment(of: [secondCompletionExpectation], timeout: 2)

        // Then
        XCTAssertFalse(firstNavigationController === secondNavigationController)
        XCTAssertEqual(completionCount, 2)
    }

    func testNilAddressDismissesPresentation() async throws {
        // Given
        let shippingAddressElement = makeShippingAddressElement()
        let completionExpectation = expectation(description: "Presentation completion called")
        _ = try XCTUnwrap(present(shippingAddressElement) {
            completionExpectation.fulfill()
        })

        // When
        shippingAddressElement.addressViewControllerDidFinish(
            shippingAddressElement.addressViewController,
            with: nil
        )
        await fulfillment(of: [completionExpectation], timeout: 2)

        // Then
        XCTAssertNil(presentingViewController.presentedViewController)
    }

    private func makeShippingAddressElement() -> ShippingAddressElement {
        return ShippingAddressElement(
            configuration: .init(),
            initialShippingAddress: nil,
            allowedCountries: ["US"],
            apiClient: .shared,
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
