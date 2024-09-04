//
//  EmbeddedPaymentMethodsViewSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/24.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet

class EmbeddedPaymentMethodsViewSnapshotTests: STPSnapshotTestCase {
    
    // MARK: Flat radio snapshot tests
    
    func testEmbeddedPaymentMethodsView_flatRadio() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView.style = .flatRadio
        
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }
    
    // TODO(porter) Add more tests

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
