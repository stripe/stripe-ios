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

class LinkInlineSignupViewModelTests: XCTestCase {

    func test_defaults() {
        let sut = makeSUT()

        XCTAssertFalse(sut.shouldShowEmailField)
        XCTAssertFalse(sut.shouldShowPhoneField)
    }

    func test_shouldShowEmailFieldWhenCheckboxIsChecked() {
        let sut = makeSUT()

        sut.saveCheckboxChecked = true
        XCTAssertTrue(sut.shouldShowEmailField)

        sut.saveCheckboxChecked = false
        XCTAssertFalse(sut.shouldShowEmailField)
    }

    func test_shouldShowPhoneNumberWhenEmailIsProvided() {
        let sut = makeSUT()

        sut.saveCheckboxChecked = true
        sut.emailAddress = "user@example.com"

        // Wait for async change on `shouldShowPhoneField`.
        let showPhoneFieldExpectation = expectation(for: sut, keyPath: \.shouldShowPhoneField, equalsToValue: true)
        wait(for: [showPhoneFieldExpectation], timeout: 2)

        sut.emailAddress = nil

        // Wait for async change on `shouldShowPhoneField`.
        let hidePhoneFieldExpectation = expectation(for: sut, keyPath: \.shouldShowPhoneField, equalsToValue: false)
        wait(for: [hidePhoneFieldExpectation], timeout: 2)
    }

}

extension LinkInlineSignupViewModelTests {

    struct MockAccountService: LinkAccountServiceProtocol {
        func lookupAccount(
            withEmail email: String?,
            completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
        ) {
            completion(.success(
                PaymentSheetLinkAccount(email: "user@example.com", session: nil)
            ))
        }
        
        func hasEmailLoggedOut(email: String) -> Bool {
            // TODO(porter): Determine if we want to implement this in tests
            return false
        }
    }

    func makeSUT() -> LinkInlineSignupViewModel {
        return LinkInlineSignupViewModel(
            merchantName: "[Merchant]",
            accountService: MockAccountService()
        )
    }

}
