//
//  NetworkedIdentityConfigTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripeIdentity
import XCTest

final class NetworkedIdentityConfigTest: XCTestCase {

    func testWithoutOverrides_everythingComesFromThePage() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), options: nil)

        XCTAssertEqual(config.route, .reuse)
        XCTAssertEqual(config.merchantPublishableKey, "pk_page")
        XCTAssertEqual(config.merchantEmail, "networked@example.com")
        XCTAssertEqual(config.phoneNumberAutofillHint, "+12025550100")
        XCTAssertTrue(config.saveEnabled)
        XCTAssertTrue(config.savedDocumentAvailable)
    }

    func testWithoutNetworkedIdentityFields_nothingIsOffered() throws {
        let config = NetworkedIdentityConfig.from(
            page: try makePage(merchantPublishableKey: nil, networkedIdentity: false),
            options: nil
        )

        XCTAssertEqual(config.route, NetworkedIdentityRoute.none)
        XCTAssertNil(config.merchantPublishableKey)
    }

    func testOverrides_winOverThePage() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), options: makeOptions(debugRoute: "save"))

        XCTAssertEqual(config.route, .save)
        XCTAssertEqual(config.merchantPublishableKey, "pk_override")
        XCTAssertEqual(config.merchantEmail, "person@example.com")
        XCTAssertTrue(config.saveEnabled)
        XCTAssertFalse(config.savedDocumentAvailable)
        // The phone hint has no debug override; it always comes from the page.
        XCTAssertEqual(config.phoneNumberAutofillHint, "+12025550100")
    }

    func testNilOverrideRoute_keepsPageRoute() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), options: makeOptions(debugRoute: nil))

        XCTAssertEqual(config.route, .reuse)
    }

    private func makePage(
        merchantPublishableKey: String? = "pk_page",
        networkedIdentity: Bool = true
    ) throws -> StripeAPI.VerificationPage {
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
            merchantPublishableKey: merchantPublishableKey,
            networkedIdentity: networkedIdentity
                ? .init(
                    saveEnabled: true,
                    reuseEnabled: true,
                    reuseAvailable: true,
                    lookupEmail: "networked@example.com",
                    phoneNumberAutofillHint: "+12025550100",
                    state: .init(consented: false, skipped: false, direction: nil)
                )
                : nil,
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

    private func makeOptions(debugRoute: String?) -> IdentityVerificationSheet.Configuration.NetworkedIdentityOptions {
        .init(
            linkSessionHandoff: nil,
            debugMerchantPublishableKey: "pk_override",
            debugProvidedEmail: "person@example.com",
            debugRoute: debugRoute
        )
    }
}
