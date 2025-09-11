//
//  CVCReconfirmationViewControllerSnapshotTest.swift
//  
//
//  Created by Yuki Tokuhiro on 9/5/25.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore

import XCTest

// @iOS26
final class CVCReconfirmationViewControllerSnapshotTest: STPSnapshotTestCase {
    func testCVCRecollectionScreen() {
        var configuration: PaymentSheet.Configuration = ._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.appearance.applyingLiquidGlassIfPossible()

        let sut = CVCReconfirmationViewController(paymentMethod: STPPaymentMethod._testCard(),
                                                  intent: ._testValue(),
                                                  configuration: configuration,
                                                  onCompletion: { _, _ in },
                                                  onCancel: { _ in })
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
