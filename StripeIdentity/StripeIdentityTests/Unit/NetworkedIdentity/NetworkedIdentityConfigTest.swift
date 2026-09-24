//
//  NetworkedIdentityConfigTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable import StripeIdentity
import XCTest

final class NetworkedIdentityConfigTest: XCTestCase {

    func testWithoutOverrides_everythingComesFromThePage() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), overrides: nil)

        XCTAssertEqual(config.route, .reuse)
        XCTAssertEqual(config.merchantPublishableKey, "pk_page")
        XCTAssertEqual(config.merchantEmail, "networked@example.com")
        XCTAssertFalse(config.seedSavedDocuments)
    }

    func testWithoutNetworkedIdentityEmail_theProvidedEmailIsUsed() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(networkedEmail: nil), overrides: nil)

        XCTAssertEqual(config.merchantEmail, "provided@example.com")
    }

    func testWithoutNetworkedIdentityFields_nothingIsOffered() throws {
        let config = NetworkedIdentityConfig.from(
            page: try makePage(merchantPublishableKey: nil, networkedIdentity: false),
            overrides: nil
        )

        XCTAssertEqual(config.route, NetworkedIdentityRoute.none)
        XCTAssertNil(config.merchantPublishableKey)
    }

    func testOverrides_winOverThePage() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), overrides: makeOverrides(route: .save))

        XCTAssertEqual(config.route, .save)
        XCTAssertEqual(config.merchantPublishableKey, "pk_override")
        XCTAssertEqual(config.merchantEmail, "person@example.com")
        XCTAssertTrue(config.seedSavedDocuments)
    }

    func testNilOverrideRoute_keepsPageRoute() throws {
        let config = NetworkedIdentityConfig.from(page: try makePage(), overrides: makeOverrides(route: nil))

        XCTAssertEqual(config.route, .reuse)
    }

    private func makePage(
        merchantPublishableKey: String? = "pk_page",
        networkedEmail: String? = "networked@example.com",
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
                    saveAvailable: true,
                    reuseAvailable: true,
                    email: networkedEmail,
                    phoneNumber: nil,
                    state: .init(consented: false, skipped: false, direction: nil)
                )
                : nil,
            networkingData: page.networkingData,
            providedDetails: .init(email: "provided@example.com"),
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

    private func makeOverrides(route: NetworkedIdentityRoute?) -> NetworkedIdentityDebugOverrides {
        NetworkedIdentityDebugOverrides(
            route: route,
            merchantPublishableKey: "pk_override",
            merchantEmail: "person@example.com",
            seedSavedDocuments: true
        )
    }
}
