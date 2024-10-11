//
//  EmbeddedPaymentElementDelegate.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

import Foundation

@_spi(EmbeddedPaymentElementPrivateBeta)
@MainActor
public protocol EmbeddedPaymentElementDelegate: AnyObject {
  /// Called inside an animation block when the EmbeddedPaymentElement view is updating its height. Your implementation should call `setNeedsLayout()` and `layoutIfNeeded` on the scroll view that contains the EmbeddedPaymentElement view. This enables a smooth animation of the height change.
  func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement)

  /// Called immediately before the EmbeddedPaymentElement view presents
  func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement)

  /// Called when `embeddedPaymentElement.paymentOption` changes. For example, when the customer makes a selection in the view, or an `update` call invalidates the current payment option.
  func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement)
}

public extension EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement) {
        // Default implementation does nothing
    }
    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        // Default implementation does nothing
    }
}
