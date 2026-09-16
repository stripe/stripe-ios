//
//  VerificationPageNetworkingDataTest.swift
//  StripeIdentityTests
//

import Foundation
@_spi(STP) import StripeCore
import XCTest

@testable import StripeIdentity

final class VerificationPageNetworkingDataTest: XCTestCase {
    func testDecodesV8BootstrapAndPreservesItWhenUpdatingRequirements() throws {
        // Given the proposed v8 bootstrap with both Networked Identity paths available
        var configuration = networkedIdentity()
        configuration["email"] = "consumer@example.com"
        configuration["phone_number"] = "+12025550100"
        let verificationPage = try makeVerificationPage(
            networkedIdentity: configuration,
            merchantPublishableKey: "pk_test_merchant"
        )

        // Then the server configuration decodes and reuse takes priority over save
        let configurationModel = try XCTUnwrap(verificationPage.networkedIdentity)
        XCTAssertEqual(verificationPage.merchantPublishableKey, "pk_test_merchant")
        XCTAssertEqual(configurationModel.saveAvailable, true)
        XCTAssertEqual(configurationModel.reuseAvailable, true)
        XCTAssertEqual(configurationModel.email, "consumer@example.com")
        XCTAssertEqual(configurationModel.phoneNumber, "+12025550100")
        XCTAssertEqual(configurationModel.state?.consented, false)
        XCTAssertEqual(configurationModel.state?.skipped, false)
        XCTAssertNil(configurationModel.state?.direction)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .reuse)

        // ...and updating requirements preserves the entire bootstrap configuration
        let copy = verificationPage.copyWithNewMissings(newMissings: [.idDocumentFront])
        XCTAssertEqual(copy.networkedIdentity, verificationPage.networkedIdentity)
        XCTAssertEqual(copy.merchantPublishableKey, verificationPage.merchantPublishableKey)

        // ...and document reuse requirements still come from the document capture configuration
        let documentRequirements = NetworkedIdentityDocumentRequirements(verificationPage: verificationPage)
        XCTAssertEqual(documentRequirements.allowedDocumentTypes.count, 3)
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.passport))
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.drivingLicense))
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.idCard))
        XCTAssertFalse(documentRequirements.requiresLiveCapture)
    }

    func testMissingNetworkedIdentityRoutesToNormalIdentity() throws {
        let verificationPage = try VerificationPageMock.response200NoExp.make()

        XCTAssertNil(verificationPage.networkedIdentity)
        XCTAssertNil(verificationPage.merchantPublishableKey)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
    }

    func testNullNetworkedIdentityRoutesToNormalIdentity() throws {
        let verificationPage = try makeVerificationPage(
            networkedIdentity: NSNull(),
            merchantPublishableKey: NSNull()
        )

        XCTAssertNil(verificationPage.networkedIdentity)
        XCTAssertNil(verificationPage.merchantPublishableKey)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
    }

    func testLegacyNetworkingFeaturesDoNotEnableV8Routing() throws {
        // Given an older response containing all the internal eligibility flags
        let verificationPage = try makeVerificationPage(networkingData: [
            "features": [
                "vi_compatible": true,
                "vi_merchant_eligible": true,
                "vi_merchant_enabled": true,
                "consumer_save_enabled": true,
                "consumer_reuse_enabled": true,
                "consumer_reuse_possible": true,
            ],
        ])

        // Then these flags remain decodable but do not opt into the new bootstrap contract
        XCTAssertEqual(verificationPage.networkingData?.features?.consumerReuseEnabled, true)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
    }

    func testAvailabilityDoesNotDependOnLegacyFeaturesOrMerchantKey() throws {
        let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity())

        XCTAssertNil(verificationPage.networkingData)
        XCTAssertNil(verificationPage.merchantPublishableKey)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .reuse)
    }

    func testReuseDoesNotRequireSaveAndTakesPriorityOverIt() throws {
        for saveAvailable in [true, false] {
            let verificationPage = try makeVerificationPage(
                networkedIdentity: networkedIdentity(saveAvailable: saveAvailable)
            )
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .reuse)
        }
    }

    func testSaveIsUsedWhenReuseIsUnavailable() throws {
        for reuseAvailable: Bool? in [false, nil] {
            let verificationPage = try makeVerificationPage(
                networkedIdentity: networkedIdentity(reuseAvailable: reuseAvailable)
            )
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .save)
        }
    }

    func testMissingOrDisabledAvailabilityRoutesToNormalIdentity() throws {
        for availability: Bool? in [false, nil] {
            let verificationPage = try makeVerificationPage(
                networkedIdentity: networkedIdentity(saveAvailable: availability, reuseAvailable: availability)
            )
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
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
            saveAvailable: false,
            reuseAvailable: false,
            consented: true,
            direction: "consumer_to_merchant"
        ))

        XCTAssertEqual(verificationPage.networkedIdentityRoute, .resumeReuse)
    }

    func testConsentedSaveResumesEvenWhenAvailabilityChanges() throws {
        let verificationPage = try makeVerificationPage(networkedIdentity: networkedIdentity(
            saveAvailable: false,
            reuseAvailable: false,
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

    func testNetworkedIdentityContactDetailsAreOptionalAndDoNotUseProvidedDetails() throws {
        for contactValue: Any? in [nil, NSNull()] {
            var configuration = networkedIdentity()
            configuration["email"] = contactValue
            configuration["phone_number"] = contactValue
            let verificationPage = try makeVerificationPage(
                networkedIdentity: configuration,
                providedDetails: ["email": "legacy@example.com"]
            )

            XCTAssertNil(verificationPage.networkedIdentity?.email)
            XCTAssertNil(verificationPage.networkedIdentity?.phoneNumber)
            XCTAssertEqual(verificationPage.providedDetails?.email, "legacy@example.com")
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .reuse)
        }
    }

    func testDecodesProvidedEmailAndPreservesItWhenUpdatingRequirements() throws {
        // Given the older merchant-provided details remain present for compatibility
        let verificationPage = try makeVerificationPage(providedDetails: ["email": "consumer@example.com"])
        XCTAssertEqual(verificationPage.providedDetails?.email, "consumer@example.com")

        let copy = verificationPage.copyWithNewMissings(newMissings: [.idDocumentFront])

        XCTAssertEqual(copy.providedDetails, verificationPage.providedDetails)
        XCTAssertNil(copy.networkedIdentity)
        XCTAssertEqual(copy.networkedIdentityRoute, .none)
    }

    func testProvidedEmailIsOptional() throws {
        let providedDetailsValues: [Any?] = [nil, NSNull(), [String: Any](), ["email": NSNull()]]
        for providedDetails in providedDetailsValues {
            let verificationPage = try makeVerificationPage(providedDetails: providedDetails)
            XCTAssertNil(verificationPage.providedDetails?.email)
            XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
        }
    }
}

private extension VerificationPageNetworkingDataTest {
    func makeVerificationPage(
        networkedIdentity: Any? = nil,
        merchantPublishableKey: Any? = nil,
        providedDetails: Any? = nil,
        networkingData: Any? = nil
    ) throws -> StripeAPI.VerificationPage {
        let fixtureData = try VerificationPageMock.response200.data()
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: fixtureData) as? [String: Any])
        fixture["networked_identity"] = networkedIdentity
        fixture["merchant_publishable_key"] = merchantPublishableKey
        fixture["provided_details"] = providedDetails
        fixture["networking_data"] = networkingData
        let data = try JSONSerialization.data(withJSONObject: fixture)
        return try StripeJSONDecoder().decode(StripeAPI.VerificationPage.self, from: data)
    }

    func networkedIdentity(
        saveAvailable: Bool? = true,
        reuseAvailable: Bool? = true,
        consented: Bool? = false,
        skipped: Bool? = false,
        direction: Any? = nil
    ) -> [String: Any] {
        var state: [String: Any] = [:]
        state["consented"] = consented
        state["skipped"] = skipped
        state["direction"] = direction
        var configuration: [String: Any] = ["state": state]
        configuration["save_available"] = saveAvailable
        configuration["reuse_available"] = reuseAvailable
        return configuration
    }
}
