//
//  EmbeddedPaymentElementDelegate.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

import Foundation

@MainActor
public protocol EmbeddedPaymentElementDelegate: AnyObject {
  /// Called inside an animation block when either EmbeddedPaymentElement surface updates its height.
  /// Call `setNeedsLayout()` and `layoutIfNeeded` on the containers holding `view` and the separate form view.
  /// This enables a smooth animation of the height change.
  func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement)

  /// Called immediately before the EmbeddedPaymentElement view presents
  func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement)

  /// Called when `embeddedPaymentElement.paymentOption` changes or its separate `formView` becomes available or unavailable. For example, when the customer makes a selection in the view, or an `update` call invalidates the current payment option.
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
