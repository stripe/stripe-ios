//
//  CapsulePKPaymentButton.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/5/25.
//

import Foundation
import PassKit

@_spi(STP) import StripeUICore

// PKPaymentButton does work with the corner configuration API.
// Instead, we add a capsule shaped mask to get the correct appearance.
final class CapsulePKPaymentButton: PKPaymentButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard LiquidGlassDetector.isEnabled else { return }
        let maskView = UIView(frame: self.frame)
        maskView.backgroundColor = .black
        maskView.ios26_applyCapsuleCornerConfiguration()
        self.mask = maskView
    }
}
