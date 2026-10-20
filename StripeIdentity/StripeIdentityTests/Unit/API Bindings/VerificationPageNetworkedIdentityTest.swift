//
//  VerificationPageNetworkedIdentityTest.swift
//  StripeIdentityTests
//

import Foundation
@_spi(STP) import StripeCore
import XCTest

@testable import StripeIdentity

final class VerificationPageNetworkedIdentityTest: XCTestCase {
    func testUpdatingRequirementsPreservesNetworkedIdentity() throws {
        // Given the v8 bootstrap with every Networked Identity field
        var configuration = networkedIdentity()
        configuration["reuse_available"] = true
        configuration["lookup_email"] = "consumer@example.com"
        configuration["phone_number_autofill_hint"] = "+12025550100"
        let verificationPage = try makeVerificationPage(networkedIdentity: configuration)
        XCTAssertNotNil(verificationPage.networkedIdentity)

        // When the requirements are updated
        let copy = verificationPage.copyWithNewMissings(newMissings: [.idDocumentFront])

        // Then the entire Networked Identity configuration is kept
        XCTAssertEqual(copy.networkedIdentity, verificationPage.networkedIdentity)
    }

    func testDocumentRequirementsComeFromTheDocumentConfiguration() throws {
        let verificationPage = try makeVerificationPage()

        let documentRequirements = NetworkedIdentityDocumentRequirements(verificationPage: verificationPage)

        XCTAssertEqual(documentRequirements.allowedDocumentTypes.count, 3)
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.passport))
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.drivingLicense))
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.idCard))
        XCTAssertFalse(documentRequirements.requiresLiveCapture)
    }

    func testMissingNetworkedIdentityRoutesToNormalIdentity() throws {
        for value: Any? in [nil, NSNull()] {
            let verificationPage = try makeVerificationPage(networkedIdentity: value)

            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none, "\(String(describing: value))")
        }
    }

    func testReuseDoesNotRequireSaveAndTakesPriorityOverIt() throws {
        for saveEnabled in [true, false] {
            let verificationPage = try makeVerificationPage(
                networkedIdentity: networkedIdentity(saveEnabled: saveEnabled)
            )
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .reuse)
        }
    }

    func testSaveIsUsedWhenReuseIsNotEnabled() throws {
        for reuseEnabled: Bool? in [false, nil] {
            let verificationPage = try makeVerificationPage(
                networkedIdentity: networkedIdentity(reuseEnabled: reuseEnabled)
            )
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .save)
        }
    }

    func testMissingOrDisabledAvailabilityRoutesToNormalIdentity() throws {
        for availability: Bool? in [false, nil] {
            var configuration = networkedIdentity(saveEnabled: availability, reuseEnabled: availability)
            // A saved document found for the provided email doesn't make Networked Identity available on its own
            configuration["reuse_available"] = true
            let verificationPage = try makeVerificationPage(networkedIdentity: configuration)
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none, "\(String(describing: availability))")
        }
    }

    func testSkippedStateTakesPriorityOverConsentAndAvailability() throws {
        for consented in [false, true] {
            for direction in ["consumer_to_merchant", "merchant_to_consumer", "future_direction"] {
                let verificationPage = try makeVerificationPage(
                    networkedIdentity: networkedIdentity(consented: consented, skipped: true, direction: direction)
                )
                XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
            }
        }
    }

    func testConsentedReuseResumesEvenWhenAvailabilityChanges() throws {
        let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity(
            saveEnabled: false,
            reuseEnabled: false,
            consented: true,
            direction: "consumer_to_merchant"
        ))

        XCTAssertEqual(verificationPage.networkedIdentityRoute, .resumeReuse)
    }

    func testConsentedSaveResumesEvenWhenAvailabilityChanges() throws {
        let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity(
            saveEnabled: false,
            reuseEnabled: false,
            consented: true,
            direction: "merchant_to_consumer"
        ))

        XCTAssertEqual(verificationPage.networkedIdentityRoute, .resumeSave)
    }

    func testMissingOrUnknownConsentedDirectionDoesNotRestartFlow() throws {
        for direction: Any? in [nil, NSNull(), "future_direction"] {
            let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity(
                consented: true,
                direction: direction
            ))
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
        }
    }

    func testDirectionWithoutConsentDoesNotRestartFlow() throws {
        for direction in ["consumer_to_merchant", "merchant_to_consumer", "future_direction"] {
            let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity(direction: direction))
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
        }
    }

    func testMissingOrIncompleteStateDoesNotRestartFlow() throws {
        let states: [Any?] = [nil, NSNull(), [String: Any](), ["consented": false], ["skipped": false]]
        for state in states {
            var configuration = networkedIdentity()
            configuration["state"] = state
            let verificationPage = try makeVerificationPage(networkedIdentity: configuration)
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
        }
    }

    func testMalformedStateIsRejectedInsteadOfGuessingConsent() {
        let states: [Any] = [
            "not_an_object",
            ["consented": "false", "skipped": false],
            ["consented": false, "skipped": "false"],
        ]
        for state in states {
            var configuration = networkedIdentity()
            configuration["state"] = state
            XCTAssertThrowsError(try makeVerificationPage(networkedIdentity: configuration))
        }
    }

    func testMalformedDirectionDoesNotRestartFlow() throws {
        let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity(
            consented: true,
            direction: ["invalid": true]
        ))

        XCTAssertEqual(verificationPage.networkedIdentity?.state?.direction, .unparsable)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
    }
}

private extension VerificationPageNetworkedIdentityTest {
    func makeVerificationPage(networkedIdentity: Any? = nil) throws -> StripeAPI.VerificationPage {
        let fixtureData = try VerificationPageMock.response200.data()
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: fixtureData) as? [String: Any])
        fixture["networked_identity"] = networkedIdentity
        let data = try JSONSerialization.data(withJSONObject: fixture)
        return try StripeJSONDecoder().decode(StripeAPI.VerificationPage.self, from: data)
    }

    func networkedIdentity(
        saveEnabled: Bool? = true,
        reuseEnabled: Bool? = true,
        consented: Bool? = false,
        skipped: Bool? = false,
        direction: Any? = nil
    ) -> [String: Any] {
        var state: [String: Any] = [:]
        state["consented"] = consented
        state["skipped"] = skipped
        state["direction"] = direction
        var configuration: [String: Any] = ["state": state]
        configuration["save_enabled"] = saveEnabled
        configuration["reuse_enabled"] = reuseEnabled
        return configuration
    }
}
