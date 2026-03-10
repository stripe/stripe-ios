//
//  PMMESnapshotTests.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/27/25.
//

@_spi(STP)@testable import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(PaymentMethodMessagingElementPreview)@testable import StripePaymentSheet
@_spi(STP)@testable import StripeUICore
import UIKit
import XCTest

@MainActor
class PMMESnapshotTests: STPSnapshotTestCase {

    var mockAnalyticsClient = MockAnalyticsClient()

    // MARK: - Single Partner Mode Tests

    func testSinglePartnerMode_Automatic() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later with {partner}",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testSinglePartnerMode_AlwaysLight() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later with {partner}",
            style: .alwaysLight
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testSinglePartnerMode_AlwaysDark() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later with {partner}",
            style: .alwaysDark
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testSinglePartnerMode_Flat() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later with {partner}",
            style: .flat
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testSinglePartnerMode_CustomFont() {
        var appearance = PaymentMethodMessagingElement.Appearance()
        appearance.font = .boldSystemFont(ofSize: 20)
        appearance.textColor = .red

        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "4 interest-free payments with {partner}",
            appearance: appearance
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testSinglePartnerMode_CustomColors() {
        var appearance = PaymentMethodMessagingElement.Appearance()
        appearance.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        appearance.linkTextColor = .purple

        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Pay in 4 installments with {partner}",
            appearance: appearance
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testSinglePartnerMode_LogoAtFront() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "{partner} lets you pay over time",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    // MARK: - Multi Partner Mode Tests

    func testMultiPartnerMode_OneLogo() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet()]),
            promotion: "Flexible payment options",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_TwoLogos_Automatic() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Buy now or pay later",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_ThreeLogos_AlwaysLight() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [
                makeLogoSet(),
                makeLogoSet(color: .systemGreen),
                makeLogoSet(color: .systemPurple),
            ]),
            promotion: "Flexible payment options available",
            style: .alwaysLight
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_ThreeLogos_AlwaysDark() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [
                makeLogoSet(),
                makeLogoSet(color: .systemGreen),
                makeLogoSet(color: .systemPurple),
            ]),
            promotion: "Flexible payment options available",
            style: .alwaysDark
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_Flat() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Multiple BNPL options",
            style: .flat
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_CustomFont() {
        var appearance = PaymentMethodMessagingElement.Appearance()
        appearance.font = .italicSystemFont(ofSize: 16)

        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Pay over time with trusted partners",
            appearance: appearance
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    // MARK: - Long Text Tests

    func testSinglePartnerMode_LongText() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later in 4 interest-free installments with {partner} for orders over $50",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_LongText() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Choose from multiple flexible payment options and pay over time with no hidden fees or interest charges",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    // MARK: - Narrow Width Tests

    func testSinglePartnerMode_NarrowWidth() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            promotion: "Buy now or pay later with {partner}",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view, width: 200)
    }

    func testMultiPartnerMode_NarrowWidth() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            promotion: "Flexible payment options",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view, width: 200)
    }

    // MARK: - Legal Disclosure Tests

    func testSinglePartnerMode_WithLegalDisclosure() {
        let viewData = makeViewData(
            mode: .singlePartner(logo: makeLogoSet()),
            legalDisclosure: "18+, T&C apply. Credit subject to status.",
            promotion: "Buy now or pay later with {partner}",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    func testMultiPartnerMode_WithLegalDisclosure() {
        let viewData = makeViewData(
            mode: .multiPartner(logos: [makeLogoSet(), makeLogoSet(color: .systemGreen)]),
            legalDisclosure: "18+, T&C apply. Credit subject to status.",
            promotion: "Buy now or pay later",
            style: .automatic
        )
        let view = PMMEUIView(viewData: viewData, integrationType: .uiKit)
        verify(view)
    }

    // MARK: - Helper Methods

    private func makeViewData(
        mode: PaymentMethodMessagingElement.Mode,
        legalDisclosure: String? = nil,
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
            learnMoreText: "Learn more",
            legalDisclosure: legalDisclosure,
            promotion: promotion,
            appearance: finalAppearance,
            analyticsHelper: analyticsHelper
        )
    }

    private func makeLogoSet(color: UIColor = .systemBlue) -> PaymentMethodMessagingElement.LogoSet {
        // Create test images with explicit sizes that will scale properly
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

            // Add a border to make it more visible
            UIColor.black.withAlphaComponent(0.3).setStroke()
            let borderPath = UIBezierPath(rect: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5))
            borderPath.lineWidth = 1
            borderPath.stroke()

            // Add some text to differentiate images
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

    private func verify(
        _ view: UIView,
        width: CGFloat = 375,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Add the view to a window for proper trait collection and layout
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 600))
        let containerVC = UIViewController()
        window.rootViewController = containerVC
        window.makeKeyAndVisible()

        // Add view to container
        containerVC.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
        ])

        // Force layout pass
        window.layoutIfNeeded()

        // Calculate the natural height
        let size = view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Update bounds for snapshot
        view.bounds = CGRect(origin: .zero, size: size)
        view.layoutIfNeeded()

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
