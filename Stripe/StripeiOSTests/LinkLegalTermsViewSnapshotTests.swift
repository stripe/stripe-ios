//
//  LinkLegalTermsViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 1/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
import UIKit

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI
@testable@_spi(InternalOnlyAPI) import StripeUICore

class LinkLegalTermsViewSnapshotTests: STPSnapshotTestCase {

    func testDefault() {
        let sut = makeSUT()
        verify(sut)
    }

    func testDefaultOnelink() {
        let sut = makeSUT(brand: .onelink)
        verify(sut, identifier: "onelink")
    }

    func testCentered() {
        let sut = makeSUT(textAlignment: .center)
        verify(sut)
    }

    func testColorCustomization() {
        let sut = makeSUT()
        sut.textColor = .orange
        sut.tintColor = .purple
        verify(sut)
    }

    func testLocalization_de() {
        performLocalizedSnapshotTest(forLanguage: "de")
    }
    func testLocalization_es() {
        performLocalizedSnapshotTest(forLanguage: "es")
    }
    func testLocalization_el_GR() {
        performLocalizedSnapshotTest(forLanguage: "el-GR")
    }
    func testLocalization_it() {
        performLocalizedSnapshotTest(forLanguage: "it")
    }
    func testLocalization_ja() {
        performLocalizedSnapshotTest(forLanguage: "ja")
    }
    func testLocalization_ko() {
        performLocalizedSnapshotTest(forLanguage: "ko")
    }
    func testLocalization_zh_hans() {
        performLocalizedSnapshotTest(forLanguage: "zh-Hans")
    }

}

// MARK: - Helpers

extension LinkLegalTermsViewSnapshotTests {

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

extension LinkLegalTermsViewSnapshotTests {

    func makeSUT(brand: LinkBrand = .link) -> LinkLegalTermsView {
        return LinkLegalTermsView(brand: brand)
    }

    func makeSUT(textAlignment: NSTextAlignment) -> LinkLegalTermsView {
        return LinkLegalTermsView(textAlignment: textAlignment)
    }

}
