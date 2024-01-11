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

    func testExpandedState() {
        let sut = makeSUT(saveCheckboxChecked: true, emailAddress: "user@example.com")
        verify(sut)
    }

    func testExpandedState_nonUS() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            emailAddress: "user@example.com",
            country: "CA"
        )
        verify(sut)
    }

    func testExpandedState_nonUS_preFilled() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            emailAddress: "user@example.com",
            country: "CA",
            preFillName: "Jane Diaz",
            preFillPhone: "+13105551234"
        )
        verify(sut)
    }

    // MARK: Textfield only mode

    func testDefaultState_textFieldsOnly() {
        let sut = makeSUT(mode: .textFieldsOnly)
        verify(sut)
    }

    func testExpandedState_textFieldsOnly() {
        let sut = makeSUT(saveCheckboxChecked: true, emailAddress: "user@example.com", mode: .textFieldsOnly)
        verify(sut)
    }

    func testExpandedState_nonUS_textFieldsOnly() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            emailAddress: "user@example.com",
            country: "CA",
            mode: .textFieldsOnly
        )
        verify(sut)
    }

    func testExpandedState_nonUS_preFilled_textFieldsOnly() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            emailAddress: "user@example.com",
            country: "CA",
            preFillName: "Jane Diaz",
            preFillPhone: "+13105551234",
            mode: .textFieldsOnly
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
            completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
        ) {
            completion(
                .success(
                    PaymentSheetLinkAccount(
                        email: "user@example.com",
                        session: nil,
                        publishableKey: nil
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
        emailAddress: String? = nil,
        country: String = "US",
        preFillName: String? = nil,
        preFillPhone: String? = nil,
        mode: LinkInlineSignupViewModel.Mode = .normal
    ) -> LinkInlineSignupElement {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "[Merchant]"
        configuration.defaultBillingDetails.name = preFillName
        configuration.defaultBillingDetails.phone = preFillPhone

        let viewModel = LinkInlineSignupViewModel(
            configuration: configuration,
            mode: mode,
            accountService: MockAccountService(),
            country: country
        )

        viewModel.saveCheckboxChecked = saveCheckboxChecked
        viewModel.emailAddress = emailAddress

        if emailAddress != nil {
            // Wait for account to load
            let expectation = notNullExpectation(for: viewModel, keyPath: \.linkAccount)
            wait(for: [expectation], timeout: 10)
        }

        return .init(viewModel: viewModel)
    }

}
