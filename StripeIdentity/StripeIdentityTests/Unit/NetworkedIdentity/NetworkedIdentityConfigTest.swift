//
//  NetworkedIdentityConfigTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripeIdentity
import XCTest

final class NetworkedIdentityConfigTest: XCTestCase {

    func testPageDrivesRouting_andHostSuppliesKey() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), options: makeOptions())

        XCTAssertEqual(config.route, .reuse)
        XCTAssertEqual(config.merchantPublishableKey, "pk_host")
        XCTAssertEqual(config.merchantEmail, "networked@example.com")
        XCTAssertEqual(config.phoneNumberAutofillHint, "+12025550100")
        XCTAssertTrue(config.saveEnabled)
        XCTAssertTrue(config.savedDocumentAvailable)
    }

    private func makePage() throws -> StripeAPI.VerificationPage {
        let page = try VerificationPageMock.response200.make()
        return StripeAPI.VerificationPage(
            biometricConsent: page.biometricConsent,
            documentCapture: page.documentCapture,
            documentSelect: page.documentSelect,
            individual: page.individual,
            countryNotListed: page.countryNotListed,
            individualWelcome: page.individualWelcome,
            phoneOtp: page.phoneOtp,
            fallbackUrl: page.fallbackUrl,
            id: page.id,
            livemode: page.livemode,
            networkedIdentity: .init(
                saveEnabled: true,
                reuseEnabled: true,
                reuseAvailable: true,
                lookupEmail: "networked@example.com",
                phoneNumberAutofillHint: "+12025550100",
                state: .init(consented: false, skipped: false, direction: nil)
            ),
            requirements: page.requirements,
            selfie: page.selfie,
            status: page.status,
            submitted: page.submitted,
            success: page.success,
            unsupportedClient: page.unsupportedClient,
            bottomsheet: page.bottomsheet,
            userSessionId: page.userSessionId,
            experiments: page.experiments,
            isStripe: page.isStripe,
            skipSuccessPage: page.skipSuccessPage
        )
    }

    private func makeOptions() -> IdentityVerificationSheet.Configuration.NetworkedIdentityOptions {
        .init(linkSessionHandoff: nil, merchantPublishableKey: "pk_host")
    }
}
