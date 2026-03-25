//
//  AddressViewControllerRepresentableSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/11/25.
//

import StripeCoreTestUtils
@testable import StripePayments
@testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable import StripeUICore
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
class AddressViewControllerRepresentableSnapshotTest: STPSnapshotTestCase {

    func testAddressElementView() async throws {
        var configuration = AddressElement.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        configuration.appearance = PaymentSheet.Appearance.default

        // Create a binding for the address
        @State var address: AddressElement.AddressDetails?

        // Create our SwiftUI view
        let swiftUIView = AddressElement(
            address: $address,
            configuration: configuration
        )
        .animation(nil) // Disable animations for testing

        // Embed `swiftUIView` in a UIWindow for rendering
        let hostingVC = makeWindowWithAddressView(swiftUIView)

        // Wait for address specs to load before taking snapshot
        let expectation = XCTestExpectation(description: "Address specs loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        // Assume the hostingVC only has 1 subview...
        XCTAssertFalse(hostingVC.view.subviews.isEmpty)
        let subview = hostingVC.view.subviews[0]

        verify(subview, identifier: "address_element_default")

        // Test with pre-populated address

        var prePopulatedConfiguration = AddressElement.Configuration()
        prePopulatedConfiguration.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        prePopulatedConfiguration.appearance = PaymentSheet.Appearance.default
        prePopulatedConfiguration.defaultValues = AddressElement.Configuration.DefaultAddressDetails(
            address: PaymentSheet.Address(
                city: "San Francisco",
                country: "US",
                line1: "123 Main St",
                line2: "Apt 4B",
                postalCode: "94105",
                state: "CA"
            ),
            name: "John Doe",
            phone: "+15551234567"
        )

        @State var prePopulatedAddressState: AddressElement.AddressDetails?

        let prePopulatedView = AddressElement(
            address: $prePopulatedAddressState,
            configuration: prePopulatedConfiguration
        )
        .animation(nil) // Disable animations for testing

        let prePopulatedHostingVC = makeWindowWithAddressView(prePopulatedView)
        XCTAssertFalse(prePopulatedHostingVC.view.subviews.isEmpty)
        let prePopulatedSubview = prePopulatedHostingVC.view.subviews[0]

        verify(prePopulatedSubview, identifier: "address_element_prepopulated")
    }

    // MARK: - Helpers

    /// Wraps a SwiftUI `AddressElement` in a UIWindow to ensure
    /// the SwiftUI content is actually rendered prior to snapshotting.
    private func makeWindowWithAddressView(
        _ swiftUIView: some View,
        width: CGFloat = 320,
        height: CGFloat = 800
    ) -> UIViewController {
        // Create a UIHostingController for a SwiftUI view.
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.layoutMargins = .zero
        hostingController.view.preservesSuperviewLayoutMargins = false

        // Create a UIWindow and set its rootViewController to our hosting controller.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = hostingController
        window.isHidden = false

        // Force layout so SwiftUI draws its content.
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        return hostingController
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
