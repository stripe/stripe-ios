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
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class LinkInlineSignupViewModelTests: XCTestCase {

    // Should be ~4x the debounce time for best results.
    let accountLookupTimeout: TimeInterval = 4

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
        wait(for: [showPhoneFieldExpectation], timeout: accountLookupTimeout)

        XCTAssertFalse(sut.shouldShowNameField, "Should not show name field for US customers")
        XCTAssertTrue(sut.shouldShowLegalTerms, "Should show legal terms when creating a new account")

        sut.emailAddress = nil

        // Wait for async change on `shouldShowPhoneField`.
        let hidePhoneFieldExpectation = expectation(for: sut, keyPath: \.shouldShowPhoneField, equalsToValue: false)
        wait(for: [hidePhoneFieldExpectation], timeout: accountLookupTimeout)
        XCTAssertFalse(sut.shouldShowNameField)
        XCTAssertFalse(sut.shouldShowLegalTerms)
    }

    func test_shouldShowNameField_nonUSCustomers() {
        let sut = makeSUT(country: "CA", hasAccount: true)
        sut.saveCheckboxChecked = true
        XCTAssertTrue(sut.shouldShowNameField, "Should show name field for non-US customers")
    }

    func test_action_returnsNilUnlessPhoneRequirementIsFulfilled() {
        let sut = makeSUT(country: "US", hasAccount: true)

        sut.saveCheckboxChecked = true
        XCTAssertNil(sut.action)

        sut.phoneNumber = PhoneNumber(number: "5555555555", countryCode: "US")
        XCTAssertNotNil(sut.action)
    }

    func test_action_returnsNilUnlessNameRequirementIsFulfilled() {
        // Non-US customers require providing a name
        let sut = makeSUT(country: "CA", hasAccount: true)

        sut.saveCheckboxChecked = true
        sut.phoneNumber = PhoneNumber(number: "5555555555", countryCode: "CA")
        XCTAssertNil(sut.action, "`action` must be nil unless a name is provided")

        sut.legalName = "Jane Doe"
        XCTAssertNotNil(sut.action)
    }

    func test_action_returnsContinueWithoutLinkIfCheckboxIsNotChecked() {
        let sut = makeSUT(country: "US")

        sut.saveCheckboxChecked = false
        XCTAssertEqual(sut.action, .continueWithoutLink)
    }

    func test_action_returnsContinueWithoutLinkIfLookupFails() {
        let sut = makeSUT(country: "US", shouldFailLookup: true)

        sut.saveCheckboxChecked = true
        sut.emailAddress = "user@example.com"

        // Wait for lookup to fail
        let lookupFailedExpectation = expectation(for: sut, keyPath: \.lookupFailed, equalsToValue: true)
        wait(for: [lookupFailedExpectation], timeout: accountLookupTimeout)

        XCTAssertEqual(sut.action, .continueWithoutLink)
    }

}

extension LinkInlineSignupViewModelTests {

    struct MockAccountService: LinkAccountServiceProtocol {
        let shouldFailLookup: Bool

        func lookupAccount(
            withEmail email: String?,
            completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
        ) {
            if shouldFailLookup {
                completion(.failure(NSError.stp_genericConnectionError()))
            } else {
                completion(.success(
                    PaymentSheetLinkAccount(email: "user@example.com", session: nil, publishableKey: nil)
                ))
            }
        }
        
        func hasEmailLoggedOut(email: String) -> Bool {
            // TODO(porter): Determine if we want to implement this in tests
            return false
        }
    }

    func makeSUT(
        country: String,
        hasAccount: Bool = false,
        shouldFailLookup: Bool = false
    ) -> LinkInlineSignupViewModel {
        let linkAccount: PaymentSheetLinkAccount? = hasAccount
            ? PaymentSheetLinkAccount(email: "user@example.com", session: nil, publishableKey: nil)
            : nil

        return LinkInlineSignupViewModel(
            configuration: .init(),
            accountService: MockAccountService(shouldFailLookup: shouldFailLookup),
            linkAccount: linkAccount,
            country: country
        )
    }

}
