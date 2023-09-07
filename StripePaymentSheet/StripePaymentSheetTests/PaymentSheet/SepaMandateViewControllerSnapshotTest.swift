//
//  SepaMandateViewControllerSnapshotTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class SepaMandateViewControllerSnapshotTest: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testView() {
        let configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        let sut = SepaMandateViewController(configuration: configuration) { _ in
           // no-op
        }
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testViewWithAppearanceConfiguration() {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.appearance = PaymentSheetTestUtils.snapshotTestTheme
        let sut = SepaMandateViewController(configuration: configuration) { _ in
           // no-op
        }
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
