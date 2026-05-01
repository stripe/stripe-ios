//
//  LinkSignUpViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 5/6/25.
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@testable@_spi(STP) import StripePaymentSheet

// @iOS26
final class LinkSignUpViewControllerSnapshotTests: STPSnapshotTestCase {

    override static func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testEmptyView() throws {
        let sut = try makeSUT(email: nil)
        sut.updateUI()

        verify(sut.stackView)
    }

    func testWithEmail() throws {
        let sut = try makeSUT(email: "user@example.com")
        sut.updateUI()

        verify(sut.stackView)
    }

    func testWithEmailSuggestion() throws {
        let sut = try makeSUT(email: "user@example.con", suggestedEmail: "user@example.com")
        sut.updateUI()

        verify(sut.stackView)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 335)
        view.backgroundColor = .white
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

extension LinkSignUpViewControllerSnapshotTests {

    func makeSUT(email: String?, suggestedEmail: String? = nil) throws -> LinkSignUpViewController {
        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()
        let session = email == nil ? LinkStubs.consumerSession(supportedPaymentDetailsTypes: [.card]) : nil

        let linkAccount = PaymentSheetLinkAccount(
            email: email ?? "",
            session: session,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
        linkAccount.suggestedEmail = suggestedEmail

        return LinkSignUpViewController(
            accountService: LinkAccountService(elementsSession: elementsSession),
            linkAccount: linkAccount,
            defaultBillingDetails: nil
        )
    }
}
