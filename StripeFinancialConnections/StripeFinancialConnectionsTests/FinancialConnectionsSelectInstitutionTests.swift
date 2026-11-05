//
//  FinancialConnectionsSelectInstitutionTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Till Hellmund on 2026-11-05.
//

import Foundation
@_spi(InternalOnlyAPI) @testable import StripeCore
import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

enum FinancialConnectionsSelectInstitutionMock: String, MockData {
    typealias ResponseType = FinancialConnectionsSelectInstitution
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case streamlinedConsent = "FinancialConnectionsSelectInstitution_streamlined_consent"
    case idConsentContent = "FinancialConnectionsSelectInstitution_id_consent_content"
}

// Dummy class to determine this bundle
private class ClassForBundle {}

final class FinancialConnectionsSelectInstitutionTests: XCTestCase {

    func testStreamlinedConsentResponseDecodes() throws {
        // When
        let payload = try FinancialConnectionsSelectInstitutionMock.streamlinedConsent.make()

        // Then
        XCTAssertEqual(payload.manifest.nextPane, .streamlinedConsent)
        XCTAssertNil(payload.text?.idConsentContentPane)

        let streamlinedConsentPane = try XCTUnwrap(payload.text?.streamlinedConsentPane)
        let screen = streamlinedConsentPane.screen
        XCTAssertEqual(screen.id, "streamlined_consent")
        XCTAssertEqual(screen.header?.title, "Log in to Test Institution")
        XCTAssertEqual(screen.header?.alignment, .center)

        // ...and the body bullets decode
        let entries = try XCTUnwrap(screen.body?.entries)
        XCTAssertEqual(entries.count, 1)
        guard case .bullets(let bulletsEntry) = entries.first else {
            return XCTFail("Expected a bullets body entry")
        }
        XCTAssertEqual(bulletsEntry.bullets.map(\.id), ["ease_of_use", "data_protection"])
        XCTAssertTrue(bulletsEntry.bullets.allSatisfy { $0.icon != nil })

        // ...and the footer decodes
        XCTAssertEqual(screen.footer?.primaryCta?.label, "Agree and continue")
        XCTAssertEqual(
            screen.footer?.belowCta,
            "[Manually verify instead](stripe://manual-entry?eventName=click.manual_entry) (may take 1-2 business days)"
        )
        XCTAssertNotNil(screen.footer?.disclaimer)

        // ...and the notices decode
        XCTAssertEqual(streamlinedConsentPane.dataAccessNotice?.title, "Data sharing")
        XCTAssertEqual(streamlinedConsentPane.legalDetailsNotice.title, "Terms and Privacy Policy")
        XCTAssertEqual(streamlinedConsentPane.moreInfoNotice?.header?.title, "About Stripe")
        XCTAssertEqual(streamlinedConsentPane.moreInfoNotice?.footer?.primaryCta?.label, "OK")
    }

    func testIDConsentContentResponseStillDecodes() throws {
        // When
        let payload = try FinancialConnectionsSelectInstitutionMock.idConsentContent.make()

        // Then
        XCTAssertEqual(payload.manifest.nextPane, .idConsentContent)
        XCTAssertEqual(payload.text?.idConsentContentPane?.screen.id, "id_consent_content")
        XCTAssertNil(payload.text?.streamlinedConsentPane)
    }
}
