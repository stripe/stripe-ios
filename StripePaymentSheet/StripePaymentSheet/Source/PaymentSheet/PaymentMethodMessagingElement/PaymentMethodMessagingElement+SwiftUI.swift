//
//  PaymentMethodMessagingElement+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/27/25.
//

import Foundation

extension PaymentMethodMessagingElement {
    /// Displayable data of an initialized Payment Method Messaging Element.
    /// For use by PaymentMethodMessagingElement.View.
    public struct ViewData {
        let mode: Mode
        let infoUrl: URL
        let promotion: String
        let appearance: PaymentMethodMessagingElement.Appearance
    }
}
