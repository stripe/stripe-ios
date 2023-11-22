//
//  SepaMandateViewControllerSnapshotTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class SepaMandateViewControllerSnapshotTest: STPSnapshotTestCase {

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
        configuration.appearance = ._testMSPaintTheme
        let sut = SepaMandateViewController(configuration: configuration) { _ in
           // no-op
        }
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
