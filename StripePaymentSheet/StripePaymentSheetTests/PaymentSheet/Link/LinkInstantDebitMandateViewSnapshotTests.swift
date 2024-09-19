//
//  LinkInstantDebitMandateViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 2/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import UIKit

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore

class LinkInstantDebitMandateViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testDefault() {
        let sut = makeSUT()
        verify(sut)
    }

    func testLocalization() {
        performLocalizedSnapshotTest(forLanguage: "de")
        performLocalizedSnapshotTest(forLanguage: "es")
        performLocalizedSnapshotTest(forLanguage: "el-GR")
        performLocalizedSnapshotTest(forLanguage: "it")
        performLocalizedSnapshotTest(forLanguage: "ja")
        performLocalizedSnapshotTest(forLanguage: "ko")
        performLocalizedSnapshotTest(forLanguage: "zh-Hans")
    }

}

// MARK: - Helpers

extension LinkInstantDebitMandateViewSnapshotTests {

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 250)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

    func performLocalizedSnapshotTest(
        forLanguage language: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPLocalizationUtils.overrideLanguage(to: language)
        let sut = makeSUT()
        STPLocalizationUtils.overrideLanguage(to: nil)
        verify(sut, identifier: language, file: file, line: line)
    }

}

// MARK: - Factory

extension LinkInstantDebitMandateViewSnapshotTests {

    func makeSUT() -> LinkInstantDebitMandateView {
        return LinkInstantDebitMandateView()
    }

}
