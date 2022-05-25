//
//  LinkInlineSignupViewModelTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils

@testable import Stripe
@_spi(STP) import StripeUICore

class LinkInlineSignupViewModelTests: XCTestCase {

    func test_defaults() {
        let sut = makeSUT(country: "US")

        XCTAssertFalse(sut.shouldShowEmailField)
        XCTAssertFalse(sut.shouldShowPhoneField)
        XCTAssertFalse(sut.shouldShowNameField)
        XCTAssertFalse(sut.shouldShowLegalTerms)
    }

    func test_shouldShowEmailFieldWhenCheckboxIsChecked() {
        let sut = makeSUT(country: "US")

        sut.saveCheckboxChecked = true
        XCTAssertTrue(sut.shouldShowEmailField)

        sut.saveCheckboxChecked = false
        XCTAssertFalse(sut.shouldShowEmailField)
    }

    func test_shouldShowRegistrationFieldsWhenEmailIsProvided() {
        let sut = makeSUT(country: "US")

        sut.saveCheckboxChecked = true
        sut.emailAddress = "user@example.com"

        // Wait for async change on `shouldShowPhoneField`.
        let showPhoneFieldExpectation = expectation(for: sut, keyPath: \.shouldShowPhoneField, equalsToValue: true)
        wait(for: [showPhoneFieldExpectation], timeout: 2)

        XCTAssertFalse(sut.shouldShowNameField, "Should not show name field for US customers")
        XCTAssertTrue(sut.shouldShowLegalTerms, "Should show legal terms when creating a new account")

        sut.emailAddress = nil

        // Wait for async change on `shouldShowPhoneField`.
        let hidePhoneFieldExpectation = expectation(for: sut, keyPath: \.shouldShowPhoneField, equalsToValue: false)
        wait(for: [hidePhoneFieldExpectation], timeout: 2)
        XCTAssertFalse(sut.shouldShowNameField)
        XCTAssertFalse(sut.shouldShowLegalTerms)
    }

    func test_shouldShowNameField_nonUSCustomers() {
        let sut = makeSUT(country: "CA", hasAccount: true)
        sut.saveCheckboxChecked = true
        XCTAssertTrue(sut.shouldShowNameField, "Should show name field for non-US customers")
    }

    func test_signupDetails() {
        let sut = makeSUT(country: "US", hasAccount: true)

        sut.saveCheckboxChecked = true
        XCTAssertNil(sut.signupDetails)

        sut.phoneNumber = PhoneNumber(number: "5555555555", countryCode: "US")
        XCTAssertNotNil(sut.signupDetails)
    }

    func test_signupDetails_nonUS() {
        let sut = makeSUT(country: "CA", hasAccount: true)

        sut.saveCheckboxChecked = true
        sut.phoneNumber = PhoneNumber(number: "5555555555", countryCode: "CA")
        XCTAssertNil(sut.signupDetails)

        sut.legalName = "Jane Doe"
        XCTAssertNotNil(sut.signupDetails)
    }

}

extension LinkInlineSignupViewModelTests {

    struct MockAccountService: LinkAccountServiceProtocol {
        func lookupAccount(
            withEmail email: String?,
            completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
        ) {
            completion(.success(
                PaymentSheetLinkAccount(email: "user@example.com", session: nil, publishableKey: nil)
            ))
        }
        
        func hasEmailLoggedOut(email: String) -> Bool {
            // TODO(porter): Determine if we want to implement this in tests
            return false
        }
    }

    func makeSUT(
        country: String,
        hasAccount: Bool = false
    ) -> LinkInlineSignupViewModel {
        let linkAccount: PaymentSheetLinkAccount? = hasAccount
            ? PaymentSheetLinkAccount(email: "user@example.com", session: nil, publishableKey: nil)
            : nil

        return LinkInlineSignupViewModel(
            configuration: .init(),
            accountService: MockAccountService(),
            linkAccount: linkAccount,
            country: country
        )
    }

}
