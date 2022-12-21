//
//  STPCardFormView+SwiftUI.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPCardFormView {

    /// A SwiftUI representation of STPCardFormView
    public struct Representable: UIViewRepresentable {
        @Binding var paymentMethodParams: STPPaymentMethodParams
        @Binding var isComplete: Bool

        let cardFormViewStyle: STPCardFormViewStyle

        /// Initialize a SwiftUI representation of an STPCardFormView.
        /// - Parameter style: The visual style to apply to the STPCardFormView. @see STPCardFormViewStyle
        /// - Parameter paymentMethodParams: A binding to the payment card text field's contents.
        /// The STPPaymentMethodParams will be `nil` if the card form view's contents are invalid or incomplete.
        public init(
            _ style: STPCardFormViewStyle = .standard,
            paymentMethodParams: Binding<STPPaymentMethodParams>,
            isComplete: Binding<Bool>
        ) {
            cardFormViewStyle = style
            _paymentMethodParams = paymentMethodParams
            _isComplete = isComplete
        }

        public func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }

        public func makeUIView(context: Context) -> STPCardFormView {
            let cardFormView = STPCardFormView(style: cardFormViewStyle)
            cardFormView.delegate = context.coordinator
            cardFormView.cardParams = paymentMethodParams
            return cardFormView
        }

        public func updateUIView(_ cardFormView: STPCardFormView, context: Context) {
            cardFormView.cardParams = paymentMethodParams
        }
    }

    /// :nodoc:
    public class Coordinator: NSObject, STPCardFormViewDelegate {

        var parent: Representable
        init(
            parent: Representable
        ) {
            self.parent = parent
        }

        /// :no-doc:
        public func cardFormView(_ form: STPCardFormView, didChangeToStateComplete complete: Bool) {
            parent.isComplete = complete
        }
    }
}
