//
//  STPiDEALFormViewTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 2/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

final class STPiDEALFormViewTest: XCTestCase {
    func testMarkFormErrorsLogic() {
        let iDEALForm = STPiDEALFormView()

        // TODO(mludowise|MOBILESDK-161): Test that we're handling error codes
        // related to billing when that gets implemented. We can copy how
        // `STPCardFormViewTests.testMarkFormErrorsLogic` does this.

        let unhandledErrorTypes = [
            "processing_error",
            "payment_method_not_available",
            "invalid_ideal_bank",
            "",
            nil,
        ]

        for shouldNotHandle in unhandledErrorTypes {
            let error: NSError
            if let shouldNotHandle = shouldNotHandle {
                error = NSError(
                    domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue,
                    userInfo: [STPError.stripeErrorCodeKey: shouldNotHandle])
            } else {
                error = NSError(
                    domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue,
                    userInfo: nil)
            }
            XCTAssertFalse(
                iDEALForm.markFormErrors(for: error),
                "Incorrectly handled \(shouldNotHandle ?? "nil")")
        }
    }
}
