//
//  EmbeddedLinkInlineVerificationEligibilityTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

@MainActor
final class EmbeddedLinkInlineVerificationEligibilityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = true
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
    }

    override func tearDown() {
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = nil
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        super.tearDown()
    }

    func testReturningUserRequiringVerificationIsEligibleWithoutSendingACode() throws {
        // Given a returning Link user who needs to verify, with native Link available
        let linkAccount = makeLinkAccount()

        // When eligibility is evaluated
        let eligible = try evaluate(linkAccount: linkAccount).get()

        // Then the account is eligible, prepared on an SMS challenge that hasn't been sent
        XCTAssertTrue(eligible.linkAccount === linkAccount)
        XCTAssertEqual(eligible.coordinator.screen, .otp)
        XCTAssertEqual(eligible.coordinator.challenge?.type, .sms)
        XCTAssertFalse(eligible.coordinator.hasStarted)
        XCTAssertEqual(eligible.coordinator.challenge?.isStarted, false)
    }

    func testServerFlagOff() {
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = false
        assertIneligible(evaluate(linkAccount: makeLinkAccount()), .disabledByServer)
    }

    func testMerchantOptOut() {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.allowsLinkInlineVerification = false
        assertIneligible(evaluate(configuration: configuration, linkAccount: makeLinkAccount()), .disabledByMerchant)
    }

    func testDisabledByDefault() {
        assertIneligible(evaluate(configuration: .init(), linkAccount: makeLinkAccount()), .disabledByMerchant)
    }

    func testCheckoutElements() {
        assertIneligible(evaluate(linkAccount: makeLinkAccount(), isCheckoutElements: true), .checkoutElements)
    }

    func testLinkNotDisplayed() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        assertIneligible(evaluate(elementsSession: elementsSession, linkAccount: makeLinkAccount()), .linkNotDisplayed)
    }

    func testNoReturningLinkUser() {
        assertIneligible(evaluate(linkAccount: nil), .notReturningLinkUser)
        let signUpAccount = PaymentSheetLinkAccount(email: "jane.diaz@example.com", session: nil, publishableKey: nil, displayablePaymentDetails: nil, useMobileEndpoints: true, canSyncAttestationState: false)
        assertIneligible(evaluate(linkAccount: signUpAccount), .notReturningLinkUser)
    }

    func testAlreadyVerified() {
        let account = makeLinkAccount(current: .oneFactorAuth)
        assertIneligible(evaluate(linkAccount: account), .alreadyVerified)
    }

    func testNativeLinkUnavailable() {
        assertIneligible(evaluate(linkAccount: makeLinkAccount(useMobileEndpoints: false)), .nativeLinkUnavailable)
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = false
        assertIneligible(evaluate(linkAccount: makeLinkAccount()), .nativeLinkUnavailable)
    }

    func testWebViewRequired() throws {
        let data = try JSONSerialization.data(withJSONObject: ["webview_open_url": "https://checkout.link.com", "webview_requirement_type": "required"])
        let fallback = try StripeJSONDecoder().decode(ConsumerSession.MobileFallbackWebviewParams.self, from: data)
        assertIneligible(evaluate(linkAccount: makeLinkAccount(fallback: fallback)), .webViewRequired)
    }

    func testVerificationAlreadyStarted() {
        let account = makeLinkAccount(verificationSessions: [.init(type: .sms, state: .started)])
        assertIneligible(evaluate(linkAccount: account), .verificationAlreadyStarted)
    }

    func testSavedPaymentMethods() {
        assertIneligible(evaluate(linkAccount: makeLinkAccount(), savedPaymentMethods: [STPPaymentMethod._testCard()]), .hasSavedPaymentMethods)
    }

    func testVerificationThatDoesNotStartWithAnSMSCode() {
        // Given only email verification, which first needs a phone number match
        let account = makeLinkAccount(factors: [.init(type: .email, providesFurtherVerification: true, temporarilyDisabled: false, id: "email_factor")])
        assertIneligible(evaluate(linkAccount: account), .unsupportedVerification)
    }

    // MARK: - Helpers

    private func evaluate(
        elementsSession: STPElementsSession = ._testValue(paymentMethodTypes: ["card", "link"], linkUseAttestation: true),
        configuration: EmbeddedPaymentElement.Configuration = {
            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.allowsLinkInlineVerification = true
            return configuration
        }(),
        linkAccount: PaymentSheetLinkAccount?,
        savedPaymentMethods: [STPPaymentMethod] = [],
        isCheckoutElements: Bool = false
    ) -> Result<EmbeddedLinkInlineVerificationEligibility.Eligible, EmbeddedLinkInlineVerificationEligibility.IneligibleReason> {
        EmbeddedLinkInlineVerificationEligibility.evaluate(
            elementsSession: elementsSession,
            configuration: configuration,
            linkAccount: linkAccount,
            savedPaymentMethods: savedPaymentMethods,
            isCheckoutElements: isCheckoutElements,
            analyticsHelper: .init(analyticsClient: STPAnalyticsClient())
        )
    }

    private func assertIneligible(
        _ result: Result<EmbeddedLinkInlineVerificationEligibility.Eligible, EmbeddedLinkInlineVerificationEligibility.IneligibleReason>,
        _ expected: EmbeddedLinkInlineVerificationEligibility.IneligibleReason,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case .success:
            XCTFail("Expected \(expected), but the account was eligible", file: file, line: line)
        case .failure(let reason):
            XCTAssertEqual(reason, expected, file: file, line: line)
        }
    }

    private func makeLinkAccount(
        current: ConsumerSession.AuthenticationLevel = .notAuthenticated,
        verificationSessions: [ConsumerSession.VerificationSession] = [],
        fallback: ConsumerSession.MobileFallbackWebviewParams? = nil,
        factors: [ConsumerSession.VerificationFactor] = [
            .init(type: .sms, providesFurtherVerification: true, temporarilyDisabled: false, id: "sms_factor"),
            .init(type: .email, providesFurtherVerification: true, temporarilyDisabled: false, id: "email_factor"),
        ],
        useMobileEndpoints: Bool = true
    ) -> PaymentSheetLinkAccount {
        let session = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "jane.diaz@example.com",
            redactedFormattedPhoneNumber: "(***) *** **72",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: verificationSessions,
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: fallback,
            currentAuthenticationLevel: current,
            minimumAuthenticationLevel: .oneFactorAuth,
            availableVerificationFactors: factors
        )
        return PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: session,
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: false,
            supportedVerificationTypes: [.sms, .email]
        )
    }
}

final class EmbeddedLinkInlineVerificationExperimentTests: XCTestCase {
    func testTreatmentShowsInlineVerificationAndControlGroupsDoNot() throws {
        func experiment(_ group: ExperimentGroup) throws -> EmbeddedLinkInlineVerificationExperiment {
            try XCTUnwrap(EmbeddedLinkInlineVerificationExperiment(elementsSession: makeSession(assignments: [EmbeddedLinkInlineVerificationExperiment.experimentName: group]), dimensions: [:]))
        }
        XCTAssertTrue(try experiment(.treatment).showsInlineVerification)
        XCTAssertFalse(try experiment(.control).showsInlineVerification)
        XCTAssertFalse(try experiment(.controlTest).showsInlineVerification)
    }

    func testSessionsWithoutAnAssignmentShowInlineVerification() {
        let experiment = EmbeddedLinkInlineVerificationExperiment(elementsSession: makeSession(assignments: [:]), dimensions: [:])
        XCTAssertNil(experiment)
        XCTAssertTrue(EmbeddedLinkInlineVerificationExperiment.showsInlineVerification(for: experiment))
    }

    func testExposureIncludesCommonDimensions() throws {
        let experiment = try XCTUnwrap(EmbeddedLinkInlineVerificationExperiment(
            elementsSession: makeSession(assignments: [EmbeddedLinkInlineVerificationExperiment.experimentName: .treatment]),
            dimensions: ["embedded_row_style": "flat_with_radio"]
        ))
        XCTAssertEqual(experiment.name, "ocs_mobile_embedded_link_inline_otp")
        XCTAssertEqual(experiment.arbId, "test_arb")
        XCTAssertEqual(experiment.dimensions["embedded_row_style"], "flat_with_radio")
        XCTAssertEqual(experiment.dimensions["in_app_elements_integration_type"], "embedded")
        XCTAssertEqual(experiment.dimensions["elements_session_id"], "test_123")
        XCTAssertNotNil(experiment.dimensions["mobile_sdk_version"])
    }

    private func makeSession(assignments: [String: ExperimentGroup]) -> STPElementsSession {
        STPElementsSession._testValue(experimentsData: ExperimentsData(arbId: "test_arb", experimentAssignments: assignments, allResponseFields: [:]))
    }
}

final class EmbeddedLinkInlineVerificationFlagsTests: XCTestCase {
    override func tearDown() {
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = nil
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationForcesDialogOverride = nil
        super.tearDown()
    }

    func testFlagsComeFromLinkSettings() throws {
        let enabled = try makeSession(flags: ["link_mobile_enable_embedded_inline_otp": true, "link_mobile_embedded_inline_otp_force_dialog": true])
        XCTAssertTrue(enabled.linkEmbeddedInlineVerificationEnabled)
        XCTAssertTrue(enabled.linkEmbeddedInlineVerificationForcesDialog)

        let unset = try makeSession(flags: [:])
        XCTAssertFalse(unset.linkEmbeddedInlineVerificationEnabled)
        XCTAssertFalse(unset.linkEmbeddedInlineVerificationForcesDialog)
    }

    func testOverridesTakePrecedence() throws {
        let enabled = try makeSession(flags: ["link_mobile_enable_embedded_inline_otp": true])
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = false
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationForcesDialogOverride = true
        XCTAssertFalse(enabled.linkEmbeddedInlineVerificationEnabled)
        XCTAssertTrue(enabled.linkEmbeddedInlineVerificationForcesDialog)
    }

    private func makeSession(flags: [String: Bool]) throws -> STPElementsSession {
        var response: [String: Any] = ["link_funding_sources": ["CARD"]]
        flags.forEach { response[$0.key] = $0.value }
        let linkSettings = try XCTUnwrap(LinkSettings.decodedObject(fromAPIResponse: response))
        return STPElementsSession._testValue(linkSettings: linkSettings)
    }
}

@MainActor
final class EmbeddedLinkInlineVerificationViewStateTests: XCTestCase {
    func testStateBeforeTheCodeIsSent() throws {
        // Given an SMS challenge with an email alternative that hasn't been sent yet
        let session = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "jane.diaz@example.com",
            redactedFormattedPhoneNumber: "(***) *** **72",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .notAuthenticated,
            minimumAuthenticationLevel: .oneFactorAuth,
            availableVerificationFactors: [
                .init(type: .sms, providesFurtherVerification: true, temporarilyDisabled: false, id: "sms_factor"),
                .init(type: .email, providesFurtherVerification: true, temporarilyDisabled: false, id: "email_factor"),
            ]
        )
        let account = PaymentSheetLinkAccount(email: "jane.diaz@example.com", session: session, publishableKey: "pk_test_123", displayablePaymentDetails: nil, useMobileEndpoints: true, canSyncAttestationState: false, supportedVerificationTypes: [.sms, .email])
        let coordinator = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init(analyticsClient: STPAnalyticsClient()))
        coordinator.prepare()

        // When the card's state is derived from it
        let state = EmbeddedLinkInlineVerificationView.State(coordinator: coordinator, email: account.email)

        // Then the masked number shows, entry waits for the code, and both actions sit behind a loading "More options"
        XCTAssertEqual(state.recipient, "(•••) ••• ••72")
        XCTAssertFalse(state.isCodeEntryEnabled)
        XCTAssertTrue(state.isActionLoading)
        guard case .menu(let items, let isEnabled) = state.actions else {
            return XCTFail("Expected a More options menu, got \(state.actions)")
        }
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(items.map(\.action), [.resend, .email])
    }
}
