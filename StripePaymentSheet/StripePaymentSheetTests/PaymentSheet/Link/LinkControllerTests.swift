//
//  LinkControllerTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class LinkControllerTests: XCTestCase {

    private let configuration = PaymentSheet.Configuration()

    override func tearDown() {
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        super.tearDown()
    }

    func testReportsLinkUnavailableWhenLinkSettingsAreMissing() {
        // Given a session without Link settings on a device that can use native Link
        let elementsSession = STPElementsSession._testCardValue()
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true

        // When
        let error = LinkController.nativeLinkUnavailableError(
            elementsSession: elementsSession,
            configuration: configuration
        )

        // Then
        XCTAssertEqual(error, .linkUnavailable)
    }

    func testReportsLinkUnavailableWhenNoFundingSourcesAreAvailable() throws {
        // Given a session without Link funding sources on a device that can't use native Link
        let (_, elementsSession) = try PayWithLinkTestHelpers.makeSetupIntentAndElementsSession(linkFundingSources: [])
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = false

        // When
        let error = LinkController.nativeLinkUnavailableError(
            elementsSession: elementsSession,
            configuration: configuration
        )

        // Then the missing funding sources are reported instead of the attestation issue
        XCTAssertEqual(error, .linkUnavailable)
    }

    func testReportsMissingAppAttestationWhenDeviceCannotUseNativeLink() throws {
        // Given a session with Link funding sources on a device that can't use native Link
        let (_, elementsSession) = try PayWithLinkTestHelpers.makeSetupIntentAndElementsSession(linkFundingSources: ["CARD"])
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = false

        // When
        let error = LinkController.nativeLinkUnavailableError(
            elementsSession: elementsSession,
            configuration: configuration
        )

        // Then
        XCTAssertEqual(error, .missingAppAttestation)
    }

    func testReportsNoErrorWhenNativeLinkIsAvailable() throws {
        // Given a session with Link funding sources on a device that can use native Link
        let (_, elementsSession) = try PayWithLinkTestHelpers.makeSetupIntentAndElementsSession(linkFundingSources: ["CARD"])
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true

        // When
        let error = LinkController.nativeLinkUnavailableError(
            elementsSession: elementsSession,
            configuration: configuration
        )

        // Then
        XCTAssertNil(error)
    }
}
