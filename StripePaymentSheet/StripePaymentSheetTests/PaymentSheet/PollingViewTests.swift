//
//  PollingViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Fionn Barrett on 08/08/2023.
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet

import XCTest

class PollingViewTests: XCTestCase {

    func testPollingViewModelBLIK() {
        let pollingViewModel = PollingViewModel(paymentMethodType: .blik)
        let deadlineInterval = pollingViewModel.deadline.timeIntervalSinceNow
        XCTAssertTrue(deadlineInterval > 60 - 0.5 && deadlineInterval <= 60, "The deadline is not within the specified range")
        XCTAssertEqual(pollingViewModel.CTA, .Localized.blik_confirm_payment)
    }
}
