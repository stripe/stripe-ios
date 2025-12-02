//
//  PMMERepresentableSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 10/27/25.
//

@_spi(STP)@testable import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(PaymentMethodMessagingElementPreview)@testable import StripePaymentSheet
@_spi(STP)@testable import StripeUICore
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
class PMMERepresentableSnapshotTests: STPSnapshotTestCase {

    var mockAnalyticsClient = MockAnalyticsClient()

    func testPMMERepresentable_SinglePartner() async {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later with {partner}",
            style: .automatic
        )

        // Create the SwiftUI view wrapper that uses PMMEViewRepresentable
        let swiftUIView = PMMELoadedViewWrapper(viewData: viewData)
            .animation(nil) // Disable animations for testing

        // Embed in UIWindow for rendering
        let hostingVC = makeWindowWithView(swiftUIView)

        hostingVC.view.setNeedsLayout()
        hostingVC.view.layoutIfNeeded()

        // Verify the snapshot
        XCTAssertFalse(hostingVC.view.subviews.isEmpty)
        let subview = hostingVC.view.subviews[0]

        verify(subview, identifier: "pmme_representable_single_partner")
    }

    func testPMMERepresentable_MultiPartner() async {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Buy now or pay later",
            style: .automatic
        )

        let swiftUIView = PMMELoadedViewWrapper(viewData: viewData)
            .animation(nil)

        let hostingVC = makeWindowWithView(swiftUIView)

        hostingVC.view.setNeedsLayout()
        hostingVC.view.layoutIfNeeded()

        XCTAssertFalse(hostingVC.view.subviews.isEmpty)
        let subview = hostingVC.view.subviews[0]

        verify(subview, identifier: "pmme_representable_multi_partner")
    }

    func testPMMERepresentable_SinglePartner_CustomAppearance() async {
        var appearance = PaymentMethodMessagingElement.Appearance()
        appearance.font = .boldSystemFont(ofSize: 20)
        appearance.textColor = .red

        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "4 interest-free payments with {partner}",
            appearance: appearance
        )

        let swiftUIView = PMMELoadedViewWrapper(viewData: viewData)
            .animation(nil)

        let hostingVC = makeWindowWithView(swiftUIView)

        hostingVC.view.setNeedsLayout()
        hostingVC.view.layoutIfNeeded()

        XCTAssertFalse(hostingVC.view.subviews.isEmpty)
        let subview = hostingVC.view.subviews[0]

        verify(subview, identifier: "pmme_representable_custom_appearance")
    }

    func testPMMERepresentable_MultiPartner_CustomAppearance() async {
        var appearance = PaymentMethodMessagingElement.Appearance()
        appearance.font = .boldSystemFont(ofSize: 20)
        appearance.textColor = .red

        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Buy now or pay later",
            appearance: appearance
        )

        let swiftUIView = PMMELoadedViewWrapper(viewData: viewData)
            .animation(nil)

        let hostingVC = makeWindowWithView(swiftUIView)

        hostingVC.view.setNeedsLayout()
        hostingVC.view.layoutIfNeeded()

        XCTAssertFalse(hostingVC.view.subviews.isEmpty)
    }

    // MARK: - Helpers

    /// Wrapper view to test PMMELoadedView directly
    private struct PMMELoadedViewWrapper: View {
        let viewData: PaymentMethodMessagingElement.ViewData

        var body: some View {
            PaymentMethodMessagingElement.PMMELoadedView(viewData: viewData, integrationType: .viewData)
        }
    }

    /// Wraps a SwiftUI view in a UIWindow to ensure proper rendering
    private func makeWindowWithView(
        _ swiftUIView: some View,
        width: CGFloat = 375,
        height: CGFloat = 600
    ) -> UIViewController {
        // Create a UIHostingController for the SwiftUI view
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.layoutMargins = .zero
        hostingController.view.preservesSuperviewLayoutMargins = false

        // Create a UIWindow and set its rootViewController
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = hostingController
        window.isHidden = false

        // Force layout so SwiftUI draws its content
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        // Return hosting controller (window is kept alive through rootViewController relationship)
        return hostingController
    }

    private func makeViewData(
        mode: PaymentMethodMessagingElement.Mode,
        promotion: String,
        style: PaymentMethodMessagingElement.Appearance.UserInterfaceStyle = .automatic,
        appearance: PaymentMethodMessagingElement.Appearance? = nil
    ) -> PaymentMethodMessagingElement.ViewData {
        // Reset analytics at the start of each test
        mockAnalyticsClient.reset()

        var finalAppearance = appearance ?? PaymentMethodMessagingElement.Appearance()
        finalAppearance.style = style

        let configuration = PaymentMethodMessagingElement.Configuration(
            amount: 5000,
            currency: "usd"
        )
        let analyticsHelper = PMMEAnalyticsHelper(
            configuration: configuration,
            analyticsClient: mockAnalyticsClient
        )

        return PaymentMethodMessagingElement.ViewData(
            mode: mode,
            infoUrl: URL(string: "https://stripe.com")!,
            promotion: promotion,
            appearance: finalAppearance,
            analyticsHelper: analyticsHelper
        )
    }

    private func makeLogoSet(color: UIColor = .systemBlue) -> PaymentMethodMessagingElement.LogoSet {
        let imageSize = CGSize(width: 60, height: 20)

        let lightImage = createTestImage(size: imageSize, color: color)
        let darkImage = createTestImage(size: imageSize, color: color.withAlphaComponent(0.8))

        return PaymentMethodMessagingElement.LogoSet(
            light: lightImage,
            dark: darkImage,
            altText: "Partner Logo",
            code: "test_partner"
        )
    }

    private func createTestImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill with color
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Add a border
            UIColor.black.withAlphaComponent(0.3).setStroke()
            let borderPath = UIBezierPath(rect: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5))
            borderPath.lineWidth = 1
            borderPath.stroke()

            // Add text label
            let label = "LOGO"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.white,
            ]
            let textSize = label.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            label.draw(in: textRect, withAttributes: attributes)
        }
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)

        // Verify analytics - displayed event should be logged
        assertDisplayedEventLogged(file: file, line: line)
    }

    private func assertDisplayedEventLogged(file: StaticString = #filePath, line: UInt = #line) {
        let displayedEvents = mockAnalyticsClient.loggedAnalytics.filter { analytic in
            guard let paymentSheetAnalytic = analytic as? PaymentSheetAnalytic else { return false }
            return paymentSheetAnalytic.event == .paymentMethodMessagingElementDisplayed
        }

        XCTAssertEqual(displayedEvents.count, 1, "Expected exactly one displayed event", file: file, line: line)
    }
}
