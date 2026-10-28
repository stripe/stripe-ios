//
//  CVCReconfirmationViewControllerSnapshotTest.swift
//  
//
//  Created by Yuki Tokuhiro on 9/5/25.
//

@_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) @testable import StripeUICore

import XCTest

// @iOS26
final class CVCReconfirmationViewControllerSnapshotTest: STPSnapshotTestCase {
    func testCVCRecollectionScreen() {
        var configuration: PaymentSheet.Configuration = ._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.appearance.applyLiquidGlassIfPossible()

        let sut = CVCReconfirmationViewController(paymentMethod: STPPaymentMethod._testCard(),
                                                  intent: ._testValue(),
                                                  configuration: configuration,
                                                  onCompletion: { _, _ in },
                                                  onCancel: { _ in })
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
