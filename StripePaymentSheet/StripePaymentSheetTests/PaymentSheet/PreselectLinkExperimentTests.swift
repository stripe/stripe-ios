@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

@MainActor
final class PreselectLinkExperimentTests: XCTestCase {
    private var analyticsClient: MockAnalyticsClientV2!

    override func setUp() {
        super.setUp()
        analyticsClient = MockAnalyticsClientV2()
    }

    func testTreatmentPreselectsLinkAndLogsExposure() throws {
        XCTAssertTrue(evaluate())
        let payload = try XCTUnwrap(analyticsClient.loggedAnalyticsPayloads.first)
        XCTAssertEqual(analyticsClient.loggedAnalyticsPayloads.count, 1)
        XCTAssertEqual(payload["event_name"] as? String, "elements.experiment_exposure")
        XCTAssertEqual(payload["experiment_retrieved"] as? String, "ocs_mobile_preselect_link")
        XCTAssertEqual(payload["arb_id"] as? String, "arb_123")
        XCTAssertEqual(payload["assignment_group"] as? String, "treatment")
        XCTAssertEqual(payload["dimensions-in_app_elements_integration_type"] as? String, "flowcontroller")
        XCTAssertEqual(payload["dimensions-displayed_payment_method_types"] as? String, "card")
        XCTAssertEqual(payload["dimensions-displayed_payment_method_types_including_wallets"] as? String, "card,link")
        XCTAssertEqual(payload["dimensions-link_enabled"] as? String, "true")
        XCTAssertEqual(payload["dimensions-link_login_state"] as? String, "logged_out")
        XCTAssertEqual(payload["dimensions-apple_pay_enabled"] as? String, "false")
        XCTAssertEqual(payload["dimensions-has_saved_payment_method"] as? String, "false")
        XCTAssertNotNil(payload["dimensions-mobile_session_id"])
        XCTAssertNotNil(payload["dimensions-mobile_sdk_version"])
        XCTAssertNotNil(payload["dimensions-elements_session_id"])
    }

    func testEmbeddedTreatmentPreselectsLink() {
        XCTAssertTrue(evaluate(configuration: EmbeddedPaymentElement.Configuration(), integrationShape: .embedded))
        XCTAssertEqual(analyticsClient.loggedAnalyticsPayloads.first?["dimensions-in_app_elements_integration_type"] as? String, "embedded")
    }

    func testControlLogsExposureWithoutPreselectingLink() {
        XCTAssertFalse(evaluate(assignment: "control"))
        XCTAssertEqual(analyticsClient.loggedAnalyticsPayloads.first?["assignment_group"] as? String, "control")
    }

    func testControlTestLogsExposureWithoutPreselectingLink() {
        XCTAssertFalse(evaluate(assignment: "control_test"))
        XCTAssertEqual(analyticsClient.loggedAnalyticsPayloads.first?["assignment_group"] as? String, "control_test")
    }

    func testMissingAssignmentIsNotExposed() {
        XCTAssertFalse(evaluate(assignment: nil))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testUnknownAssignmentIsNotExposed() {
        XCTAssertFalse(evaluate(assignment: "future_variant"))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testUnimplementedHoldbackIsNotExposed() {
        XCTAssertFalse(evaluate(assignment: "holdback"))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testCompletePaymentSheetIsNotExposed() {
        XCTAssertFalse(evaluate(integrationShape: .paymentSheet))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testExistingSelectionIsNotExposed() {
        XCTAssertFalse(evaluate(hasExistingSelection: true))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testDisabledLinkIsNotExposed() {
        var configuration = PaymentSheet.Configuration()
        configuration.link.display = .never
        XCTAssertFalse(evaluate(configuration: configuration))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testHiddenLinkButtonIsNotExposed() {
        var configuration = PaymentSheet.Configuration()
        configuration.link.display = .walletButtonHidden
        XCTAssertFalse(evaluate(configuration: configuration))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testExternalWalletButtonsAreNotExposed() {
        var configuration = PaymentSheet.Configuration()
        configuration.willUseWalletButtonsView = true
        XCTAssertFalse(evaluate(configuration: configuration))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testUnsupportedLinkIsNotExposed() {
        XCTAssertFalse(evaluate(supportsLink: false))
        XCTAssertTrue(analyticsClient.loggedAnalyticsPayloads.isEmpty)
    }

    func testVerifiedLinkAccountDimension() {
        let session = ConsumerSession.make(
            clientSecret: "client_secret", emailAddress: "user@example.com",
            redactedFormattedPhoneNumber: "(***) *** **55", unredactedPhoneNumber: "(555) 555-5555",
            phoneNumberCountry: "US", verificationSessions: [.init(type: .sms, state: .verified)],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)], mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .twoFactorAuth, minimumAuthenticationLevel: .oneFactorAuth
        )
        assertLoginState(session: session, isNativeLinkAvailable: true, expected: "logged_in")
    }

    func testUnverifiedNativeLinkAccountDimension() {
        let session = LinkStubs.consumerSession()
        assertLoginState(session: session, isNativeLinkAvailable: true, expected: "needs_verification")
    }

    func testUnverifiedWebLinkAccountDimension() {
        let session = LinkStubs.consumerSession()
        assertLoginState(session: session, isNativeLinkAvailable: false, expected: "needs_web_verification")
    }

    private func assertLoginState(session: ConsumerSession, isNativeLinkAvailable: Bool, expected: String) {
        let previousOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = isNativeLinkAvailable
        defer { PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = previousOverride }
        let account = PaymentSheetLinkAccount(
            email: "test@example.com", session: session, publishableKey: nil,
            displayablePaymentDetails: nil, useMobileEndpoints: true, canSyncAttestationState: false
        )
        XCTAssertTrue(evaluate(linkAccount: account))
        XCTAssertEqual(analyticsClient.loggedAnalyticsPayloads.first?["dimensions-link_login_state"] as? String, expected)
    }

    private func evaluate(
        assignment: String? = "treatment",
        configuration: PaymentElementConfiguration = PaymentSheet.Configuration(),
        integrationShape: PaymentSheetLoader.IntegrationShape = .flowController,
        hasExistingSelection: Bool = false,
        supportsLink: Bool = true,
        linkAccount: PaymentSheetLinkAccount? = nil
    ) -> Bool {
        // Given a backend assignment and no higher-priority selection
        var json = STPTestUtils.jsonNamed("ElementsSession")!
        json[jsonDict: "payment_method_preference"]?["ordered_payment_method_types"] = supportsLink ? ["card", "link"] : ["card"]
        json["experiments_data"] = [
            "arb_id": "arb_123",
            "experiment_assignments": assignment.map { ["ocs_mobile_preselect_link": $0] } ?? [:],
        ] as [String: Any]
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!
        let shape: ExperimentIntegrationShape = integrationShape == .embedded ? .embedded : .flowController

        // When the loader evaluates the final fallback
        return PreselectLinkExperiment.shouldPreselectLink(
            elementsSession: elementsSession,
            configuration: configuration,
            integrationShape: integrationShape,
            hasExistingSelection: hasExistingSelection,
            isApplePayEnabled: false,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            linkAccount: linkAccount,
            analyticsHelper: ExperimentAnalyticsHelper(integrationShape: shape, analyticsClientV2: analyticsClient)
        )
    }
}
