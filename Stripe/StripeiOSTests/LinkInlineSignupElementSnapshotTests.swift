//
//  LinkInlineSignupElementSnapshotTests.swift
//  StripeiOS Tests
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripeUICore
import UIKit

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class LinkInlineSignupElementSnapshotTests: STPSnapshotTestCase {

    // MARK: Normal mode

    func testDefaultState() {
        let sut = makeSUT()
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState() {
        let sut = makeSUT(saveCheckboxChecked: true, userTypedEmailAddress: "user@example.com")
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_nonUS() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            userTypedEmailAddress: "user@example.com",
            country: "CA"
        )
        verify(sut)
    }

    func testExpandedState_nonUS_preFilled() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            userTypedEmailAddress: "user@example.com",
            country: "CA",
            preFillName: "Jane Diaz",
            preFillPhone: "+13105551234"
        )
        verify(sut)
    }

    // MARK: Textfield only mode

    func testDefaultState_textFieldsOnly() {
        let sut = makeSUT(showCheckbox: false)
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_textFieldsOnly() {
        let sut = makeSUT(saveCheckboxChecked: true, userTypedEmailAddress: "user@example.com", showCheckbox: false)
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_nonUS_textFieldsOnly() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            userTypedEmailAddress: "user@example.com",
            country: "CA",
            showCheckbox: false
        )
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_nonUS_preFilled_textFieldsOnly() {
        // In textFieldsOnly mode, the phone number should *not* be prefilled.
        let sut = makeSUT(
            saveCheckboxChecked: true,
            linkAccountEmailAddress: "user@example.com",
            country: "CA",
            preFillName: "Jane Diaz",
            preFillPhone: "+13105551234",
            showCheckbox: false
        )
        verify(sut)
    }

    func verify(
        _ element: LinkInlineSignupElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

}

extension LinkInlineSignupElementSnapshotTests {

    struct MockAccountService: LinkAccountServiceProtocol {
        func lookupAccount(
            withEmail email: String?,
            emailSource: StripePaymentSheet.EmailSource,
            completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
        ) {
            completion(
                .success(
                    PaymentSheetLinkAccount(
                        email: "user@example.com",
                        session: nil,
                        publishableKey: nil,
                        useMobileEndpoints: false,
                        elementsSessionID: "abc123"
                    )
                )
            )
        }

        func hasEmailLoggedOut(email: String) -> Bool {
            // TODO(porter): Determine if we want to implement this in tests
            return false
        }
    }

    func makeSUT(
        saveCheckboxChecked: Bool = false,
        linkAccountEmailAddress: String? = nil,
        userTypedEmailAddress: String? = nil,
        country: String = "US",
        preFillName: String? = nil,
        preFillPhone: String? = nil,
        showCheckbox: Bool = true
    ) -> LinkInlineSignupElement {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "[Merchant]"
        configuration.defaultBillingDetails.name = preFillName
        configuration.defaultBillingDetails.phone = preFillPhone

        var linkAccount: PaymentSheetLinkAccount?

        if let linkAccountEmailAddress {
            linkAccount = PaymentSheetLinkAccount(email: linkAccountEmailAddress, session: nil, publishableKey: nil, useMobileEndpoints: false, elementsSessionID: "abc123")
        }

        let viewModel = LinkInlineSignupViewModel(
            configuration: configuration,
            showCheckbox: showCheckbox,
            accountService: MockAccountService(),
            linkAccount: linkAccount,
            country: country
        )

        viewModel.saveCheckboxChecked = saveCheckboxChecked
        // Won't trigger the "email address prefilled" path, because it wasn't there when initialized
        if let userTypedEmailAddress {
            viewModel.emailAddress = userTypedEmailAddress
        }

        if userTypedEmailAddress != nil || linkAccountEmailAddress != nil  {
            // Wait for account to load
            let expectation = notNullExpectation(for: viewModel, keyPath: \.linkAccount)
            wait(for: [expectation], timeout: 10)
        }

        return .init(viewModel: viewModel)
    }

}
