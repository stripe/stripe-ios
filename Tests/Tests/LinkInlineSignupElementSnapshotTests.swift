//
//  LinkInlineSignupElementSnapshotTests.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase

@testable import Stripe
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCoreTestUtils

class LinkInlineSignupElementSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testDefaultState() {
        let sut = makeSUT()
        verify(sut)
    }

    func testExpandedState() {
        let sut = makeSUT(saveCheckboxChecked: true, emailAddress: "user@example.com")
        verify(sut)
    }

    func verify(
        _ element: LinkInlineSignupElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        FBSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

}

extension LinkInlineSignupElementSnapshotTests {

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

    func makeSUT(
        saveCheckboxChecked: Bool = false,
        emailAddress: String? = nil
    ) -> LinkInlineSignupElement {
        let viewModel = LinkInlineSignupViewModel(
            merchantName: "[Merchant]",
            accountService: MockAccountService()
        )

        viewModel.saveCheckboxChecked = saveCheckboxChecked
        viewModel.emailAddress = emailAddress

        if emailAddress != nil {
            // Wait for account to load
            let expectation = notNullExpectation(for: viewModel, keyPath: \.linkAccount)
            wait(for: [expectation], timeout: 2)
        }

        return .init(viewModel: viewModel)
    }

}
