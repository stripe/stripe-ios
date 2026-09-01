//
//  VerificationPageNetworkingDataTest.swift
//  StripeIdentityTests
//

import Foundation
@_spi(STP) import StripeCore
import XCTest

@testable import StripeIdentity

final class VerificationPageNetworkingDataTest: XCTestCase {
    func testDecodesNetworkingFeaturesAndRoutesReuse() throws {
        // Given a VerificationPage response with every Networked Identity feature enabled
        let verificationPage = try makeNetworkedIdentityVerificationPage()

        // Then all feature values decode and reuse takes priority over save
        let features = try XCTUnwrap(verificationPage.networkingData?.features)
        XCTAssertEqual(features.viCompatible, true)
        XCTAssertEqual(features.viMerchantEligible, true)
        XCTAssertEqual(features.viMerchantEnabled, true)
        XCTAssertEqual(features.consumerSaveEnabled, true)
        XCTAssertEqual(features.consumerReuseEnabled, true)
        XCTAssertEqual(features.consumerReusePossible, true)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .reuse)

        // ...and updating requirements preserves the bootstrap configuration
        let copy = verificationPage.copyWithNewMissings(newMissings: [.idDocumentFront])
        XCTAssertEqual(copy.networkingData, verificationPage.networkingData)

        // ...and document reuse requirements come from the same page configuration
        let documentRequirements = NetworkedIdentityDocumentRequirements(
            verificationPage: verificationPage
        )
        XCTAssertEqual(documentRequirements.allowedDocumentTypes.count, 3)
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.passport))
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.drivingLicense))
        XCTAssertTrue(documentRequirements.allowedDocumentTypes.contains(.idCard))
        XCTAssertFalse(documentRequirements.requiresLiveCapture)
    }

    func testMissingNetworkingDataRoutesToNormalIdentity() throws {
        let verificationPage = try VerificationPageMock.response200NoExp.make()

        XCTAssertNil(verificationPage.networkingData)
        XCTAssertEqual(verificationPage.networkedIdentityRoute, .none)
    }

    func testRequiresAllBaseEligibilityFlags() {
        XCTAssertEqual(features(viCompatible: false).route, .none)
        XCTAssertEqual(features(viMerchantEligible: false).route, .none)
        XCTAssertEqual(features(viMerchantEnabled: false).route, .none)
        XCTAssertEqual(features(viCompatible: nil).route, .none)
    }

    func testReuseDoesNotRequireSaveAndTakesPriorityOverIt() {
        XCTAssertEqual(features(consumerSaveEnabled: false).route, .reuse)
        XCTAssertEqual(features(consumerSaveEnabled: true).route, .reuse)
    }

    func testSaveIsUsedWhenReuseIsUnavailable() {
        XCTAssertEqual(
            features(consumerSaveEnabled: true, consumerReuseEnabled: false).route,
            .save
        )
        XCTAssertEqual(
            features(consumerSaveEnabled: true, consumerReusePossible: false).route,
            .save
        )
    }

    func testNoConsumerPathRoutesToNormalIdentity() {
        XCTAssertEqual(
            features(
                consumerSaveEnabled: false,
                consumerReuseEnabled: false,
                consumerReusePossible: false
            ).route,
            .none
        )
    }
}

private extension VerificationPageNetworkingDataTest {
    func makeNetworkedIdentityVerificationPage() throws -> StripeAPI.VerificationPage {
        let fixtureData = try VerificationPageMock.response200.data()
        var fixture = try XCTUnwrap(
            JSONSerialization.jsonObject(with: fixtureData) as? [String: Any]
        )
        fixture["networking_data"] = [
            "features": [
                "vi_compatible": true,
                "vi_merchant_eligible": true,
                "vi_merchant_enabled": true,
                "consumer_save_enabled": true,
                "consumer_reuse_enabled": true,
                "consumer_reuse_possible": true,
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: fixture)
        return try StripeJSONDecoder().decode(
            StripeAPI.VerificationPage.self,
            from: data
        )
    }

    func features(
        viCompatible: Bool? = true,
        viMerchantEligible: Bool? = true,
        viMerchantEnabled: Bool? = true,
        consumerSaveEnabled: Bool? = true,
        consumerReuseEnabled: Bool? = true,
        consumerReusePossible: Bool? = true
    ) -> StripeAPI.VerificationPageNetworkingFeatures {
        .init(
            viCompatible: viCompatible,
            viMerchantEligible: viMerchantEligible,
            viMerchantEnabled: viMerchantEnabled,
            consumerSaveEnabled: consumerSaveEnabled,
            consumerReuseEnabled: consumerReuseEnabled,
            consumerReusePossible: consumerReusePossible
        )
    }
}
