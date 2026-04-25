//
//  FinancialConnectionsSessionTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 4/29/22.
//

import Foundation
@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@testable import StripeFinancialConnections
import UIKit
import XCTest

enum FinancialConnectionsSessionMock: String, MockData {
    typealias ResponseType = StripeAPI.FinancialConnectionsSession
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case bothAccountsAndLinkedAccountsPresent = "FinancialConnectionsSession_both_accounts_la"
    case onlyAccountsPresent = "FinancialConnectionsSession_only_accounts"
    case bothAccountsAndLinkedAccountsMissing = "FinancialConnectionsSession_only_both_missing"
    case onlyLinkedAccountsPresent = "FinancialConnectionsSession_only_la"
}

enum FinancialConnectionsSynchronizeMock: String, MockData {
    typealias ResponseType = FinancialConnectionsSynchronize
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case synchronize = "FinancialConnectionsSynchronize"
}

// Dummy class to determine this bundle
private class ClassForBundle {}

final class FinancialConnectionsSessionTests: XCTestCase {

    func testBothAccountsAndLinkedAccountsPresentFavorsAccounts() {
        guard let session = try? FinancialConnectionsSessionMock.bothAccountsAndLinkedAccountsPresent.make() else {
            return XCTFail("Could not load FinancialConnectionsSession")
        }
        XCTAssertEqual(session.accounts.data.count, 5)
    }

    func testOnlyAccountsPresentParsesCorrectly() {
        guard let session = try? FinancialConnectionsSessionMock.onlyAccountsPresent.make() else {
            return XCTFail("Could not load FinancialConnectionsSession")
        }
        XCTAssertEqual(session.accounts.data.count, 5)
    }

    func testOnlyLinkedAccountsPresentParsesCorrectly() {
        guard let session = try? FinancialConnectionsSessionMock.onlyLinkedAccountsPresent.make() else {
            return XCTFail("Could not load FinancialConnectionsSession")
        }
        XCTAssertEqual(session.accounts.data.count, 5)
    }

    func testBothAccountsAndLinkedAccountsMissingFailsToParse() {
        XCTAssertThrowsError(try FinancialConnectionsSessionMock.bothAccountsAndLinkedAccountsMissing.make())
    }

    func testSynchronizeWithoutBrandPreservesExistingStripeBranding() throws {
        let synchronize = try FinancialConnectionsSynchronizeMock.synchronize.make()

        XCTAssertNil(synchronize.manifest.brand)
        XCTAssertEqual(synchronize.manifest.theme, .light)
        XCTAssertEqual(synchronize.manifest.appearance.logo, .stripe_logo)
        XCTAssertTrue(
            synchronize.manifest.appearance.colors.primary.isEqual(FinancialConnectionsAppearance.Colors.stripe.primary)
        )
    }

    func testSynchronizeParsesLinkBrand() throws {
        let synchronize = try makeSynchronize(brandValue: "link")

        XCTAssertEqual(synchronize.manifest.brand, .link)
        XCTAssertEqual(synchronize.manifest.appearance.logo, .link_logo)
        XCTAssertTrue(
            synchronize.manifest.appearance.colors.primary.isEqual(FinancialConnectionsAppearance.Colors.stripe.primary)
        )
    }

    func testSynchronizeParsesNotlinkBrand() throws {
        let synchronize = try makeSynchronize(brandValue: "notlink")

        XCTAssertEqual(synchronize.manifest.brand, .notlink)
        XCTAssertEqual(synchronize.manifest.appearance.logo, .notlink_logo)
    }

    func testSynchronizeParsesUnknownBrandAsUnparsable() throws {
        let synchronize = try makeSynchronize(brandValue: "random_brand")

        XCTAssertEqual(synchronize.manifest.brand, .unparsable)
        XCTAssertEqual(synchronize.manifest.appearance.logo, .stripe_logo)
    }

    func testLinkThemeWithoutBrandPreservesExistingLinkBranding() {
        let manifest = makeManifest(theme: .linkLight)

        XCTAssertNil(manifest.brand)
        XCTAssertEqual(manifest.appearance.logo, .link_logo)
        XCTAssertTrue(manifest.appearance.colors.primary.isEqual(FinancialConnectionsAppearance.Colors.link.primary))
    }

    func testExplicitBrandOverridesLogoWithoutChangingThemeColors() {
        let manifest = makeManifest(theme: .light, brand: .notlink)

        XCTAssertEqual(manifest.appearance.logo, .notlink_logo)
        XCTAssertTrue(manifest.appearance.colors.primary.isEqual(FinancialConnectionsAppearance.Colors.stripe.primary))
    }

    private func makeSynchronize(brandValue: String?) throws -> FinancialConnectionsSynchronize {
        var payload = try JSONSerialization.jsonObject(with: FinancialConnectionsSynchronizeMock.synchronize.data()) as? [String: Any]
        var manifest = payload?["manifest"] as? [String: Any]

        manifest?["brand"] = brandValue
        payload?["manifest"] = manifest

        let data = try JSONSerialization.data(withJSONObject: payload ?? [:])
        return try decode(data: data)
    }

    private func decode(data: Data) throws -> FinancialConnectionsSynchronize {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/financial_connections/sessions/synchronize")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["request-id": "req_123"]
        )
        let result: Result<FinancialConnectionsSynchronize, Error> = STPAPIClient.decodeResponse(
            data: data,
            error: nil,
            response: response
        )
        switch result {
        case .success(let synchronize):
            return synchronize
        case .failure(let error):
            throw error
        }
    }

    private func makeManifest(
        theme: FinancialConnectionsSessionManifest.Theme,
        brand: FinancialConnectionsSessionManifest.Brand? = nil
    ) -> FinancialConnectionsSessionManifest {
        FinancialConnectionsSessionManifest(
            allowManualEntry: false,
            brand: brand,
            consentRequired: false,
            customManualEntryHandling: false,
            disableLinkMoreAccounts: false,
            id: "fcsess_123",
            instantVerificationDisabled: false,
            institutionSearchDisabled: false,
            livemode: false,
            manualEntryMode: .automatic,
            manualEntryUsesMicrodeposits: false,
            nextPane: .consent,
            permissions: [],
            product: "external_api",
            singleAccount: false,
            theme: theme
        )
    }
}
