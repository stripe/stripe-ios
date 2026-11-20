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
        let state = InlineAddressFormState(
            defaultValues: .init(),
            allowedCountries: ["US"],
            nameField: .auto,
            phone: .hidden,
            appearance: .default,
            addressSpecProvider: makeAddressSpecProvider()
        )
        let addressSectionView = try XCTUnwrap(state.addressSection?.view)

        // ...and SwiftUI builds the form before the page's first layout gives it a width
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 800))
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

        // When the page lays out the form at its width
        hostingController.view.frame = window.bounds
        layout(hostingController, in: window)
        await waitForViewUpdate()
        layout(hostingController, in: window)

        // Then the form is as tall as its fields
        let fieldsHeight = addressSectionView.systemLayoutSizeFitting(
            CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        XCTAssertGreaterThan(fieldsHeight, 0)
        XCTAssertEqual(addressSectionView.bounds.height, fieldsHeight, accuracy: 1)
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

    private func makeAddressSpecProvider() -> AddressSpecProvider {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        return addressSpecProvider
    }
}
