//
//  InlineAddressFormViewTests.swift
//  StripePaymentSheetTests
//

@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) @testable import StripeUICore
import SwiftUI
import UIKit
import XCTest

@MainActor
final class InlineAddressFormViewTests: XCTestCase {
    func testFormWithLoadedAddressSpecsIsAsTallAsItsFields() async throws {
        // Given a form whose address specs are already loaded, so it has fields from the start
        let state = makeState()
        let addressSectionView = try XCTUnwrap(state.addressSection?.view)

        // When SwiftUI builds the form before the page's first layout gives it a width
        let window = await showFormBeforeFirstLayout(state: state)
        defer { window.isHidden = true }

        // Then the form is as tall as its fields
        let fieldsHeight = addressSectionView.systemLayoutSizeFitting(
            CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let formView = try XCTUnwrap(addressSectionView.superview)
        XCTAssertGreaterThan(fieldsHeight, 0)
        XCTAssertEqual(formView.bounds.height, fieldsHeight, accuracy: 1)
    }

    func testFormWithLoadedAddressSpecsDoesNotBreakConstraints() async throws {
        // Fail on any constraint UIKit breaks, using the callback behind the example app's broken-constraint alerts
        let selector = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
        let method = try XCTUnwrap(class_getInstanceMethod(UIView.self, selector))
        let originalImplementation = method_getImplementation(method)
        typealias ConstraintCallback = @convention(c) (UIView, Selector, AnyObject, NSLayoutConstraint, NSArray) -> Void
        let originalCallback = unsafeBitCast(originalImplementation, to: ConstraintCallback.self)
        let callback: @convention(block) (UIView, AnyObject, NSLayoutConstraint, NSArray) -> Void = { view, engine, constraint, conflicts in
            XCTFail("Broken constraint: \(constraint)")
            originalCallback(view, selector, engine, constraint, conflicts)
        }
        let implementation = imp_implementationWithBlock(callback)
        method_setImplementation(method, implementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(implementation)
        }

        // Given a form whose address specs are already loaded, so it has fields from the start
        let state = makeState()
        let addressSectionView = try XCTUnwrap(state.addressSection?.view)

        // When SwiftUI builds the form before the page's first layout gives it a width
        let window = await showFormBeforeFirstLayout(state: state)
        defer { window.isHidden = true }

        // Then the fields are on screen, and UIKit didn't break any of their constraints on the way
        XCTAssertNotNil(addressSectionView.window)
    }

    func testFormGrowsWhenAFieldShowsAnError() async throws {
        // Given a form on screen, with "1" entered in its ZIP code field
        let state = makeState()
        let addressSectionView = try XCTUnwrap(state.addressSection?.view)
        let postalCode = try XCTUnwrap(state.addressSection?.postalCode)
        let window = await showFormBeforeFirstLayout(state: state)
        defer { window.isHidden = true }
        let formView = try XCTUnwrap(addressSectionView.superview)
        postalCode.beginEditing()
        postalCode.setText("1")
        await showUpdates(in: window)
        let heightWithoutError = formView.bounds.height

        // When the customer leaves the field, which shows that the ZIP code is incomplete
        postalCode.endEditing(continueToNextField: false)
        let fieldsHeight = addressSectionView.systemLayoutSizeFitting(
            CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        // The form animates to its new height.
        await showUpdates(in: window, until: { abs(formView.bounds.height - fieldsHeight) <= 1 })

        // Then the form grows to fit the error
        XCTAssertGreaterThan(fieldsHeight, heightWithoutError)
        XCTAssertEqual(formView.bounds.height, fieldsHeight, accuracy: 1)
    }

    /// Lays out a form for `state` at zero size, as a page does before its first layout, and then
    /// at the window's width. Returns the window, which the caller hides when done.
    private func showFormBeforeFirstLayout(state: InlineAddressFormState) async -> UIWindow {
        // A window in the app's scene gets the display updates that drive SwiftUI's animations.
        let windowScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = windowScene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = CGRect(x: 0, y: 0, width: 320, height: 800)
        let pageViewController = UIViewController()
        window.rootViewController = pageViewController
        window.makeKeyAndVisible()
        let hostingController = UIHostingController(rootView: InlineAddressFormView(state: state))
        pageViewController.addChild(hostingController)
        hostingController.view.frame = .zero
        pageViewController.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: pageViewController)
        layout(hostingController, in: window)
        await waitForViewUpdate()

        hostingController.view.frame = window.bounds
        layout(hostingController, in: window)
        await waitForViewUpdate()
        layout(hostingController, in: window)
        return window
    }

    /// Lays out `window` until the form has measured its fields and SwiftUI has applied their
    /// height, or until `condition` holds, for up to a second.
    private func showUpdates(in window: UIWindow, until condition: () -> Bool = { false }) async {
        let deadline = Date().addingTimeInterval(1)
        repeat {
            window.rootViewController?.children.forEach { layout($0, in: window) }
            await waitForViewUpdate()
        } while !condition() && Date() < deadline
    }

    private func waitForViewUpdate() async {
        let viewUpdate = expectation(description: "The form measures its fields")
        DispatchQueue.main.async {
            viewUpdate.fulfill()
        }
        await fulfillment(of: [viewUpdate], timeout: 1)
    }

    private func layout(_ viewController: UIViewController, in window: UIWindow) {
        window.setNeedsLayout()
        window.layoutIfNeeded()
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
    }

    private func makeState() -> InlineAddressFormState {
        InlineAddressFormState(
            defaultValues: .init(),
            allowedCountries: ["US"],
            nameField: .auto,
            phone: .hidden,
            appearance: .default,
            addressSpecProvider: makeAddressSpecProvider()
        )
    }

    private func makeAddressSpecProvider() -> AddressSpecProvider {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "\\d{5}",
                zipNameType: .zip
            ),
        ]
        return addressSpecProvider
    }
}
