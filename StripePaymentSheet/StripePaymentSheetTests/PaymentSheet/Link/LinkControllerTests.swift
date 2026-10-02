//
//  LinkControllerTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCore
@_spi(STP) @testable import StripePaymentSheet
import XCTest

@MainActor
final class LinkControllerTests: XCTestCase {

    func testBrandOverrideTakesPriority() {
        // Given a controller whose brand would otherwise resolve to Link, with a Onelink override
        let controller = makeController(initialLinkBrand: .link, brandOverride: .onelink)

        // Then the override is used
        XCTAssertEqual(controller.resolvedLinkBrand, .onelink)
    }

    func testWithoutBrandOverrideUsesResolvedBrand() {
        // Given no signed in customer, and no brand override
        LinkAccountContext.shared.account = nil
        let controller = makeController(initialLinkBrand: .onelink, brandOverride: nil)

        // Then the brand resolved at creation is used
        XCTAssertEqual(controller.resolvedLinkBrand, .onelink)
    }

    // MARK: - Helpers

    private func makeController(initialLinkBrand: LinkBrand, brandOverride: LinkBrand?) -> LinkController {
        var paymentElementConfiguration = PaymentSheet.Configuration()
        paymentElementConfiguration.link.brand = brandOverride
        return LinkController(
            mode: .setup,
            elementsSession: ._testValue(intent: ._testValue()),
            intent: ._testValue(),
            paymentElementConfiguration: paymentElementConfiguration,
            linkBrand: initialLinkBrand,
            appearance: nil,
            configuration: nil,
            analyticsHelper: ._testValue(),
            requestSurface: .standaloneLink
        )
    }
}
