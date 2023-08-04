//
//  STPPaymentCardTextField+SwiftUI.swift
//  StripePaymentsUI
//
//  Created by David Estes on 2/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
import SwiftUI

extension STPPaymentCardTextField {

    /// A SwiftUI representation of an STPPaymentCardTextField.
    public struct Representable: UIViewRepresentable {
        @Binding var paymentMethodParams: STPPaymentMethodParams?

        /// Initialize a SwiftUI representation of an STPPaymentCardTextField.
        /// - Parameter paymentMethodParams: A binding to the payment card text field's contents.
        /// The STPPaymentMethodParams will be `nil` if the payment card text field's contents are invalid.
        public init(
            paymentMethodParams: Binding<STPPaymentMethodParams?>
        ) {
            _paymentMethodParams = paymentMethodParams
        }

        public func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }

        public func makeUIView(context: Context) -> STPPaymentCardTextField {
            let paymentCardField = STPPaymentCardTextField()
            if let paymentMethodParams = paymentMethodParams {
                paymentCardField.paymentMethodParams = paymentMethodParams
            }
            paymentCardField.delegate = context.coordinator
            paymentCardField.setContentHuggingPriority(.required, for: .vertical)

            return paymentCardField
        }

        public func updateUIView(_ paymentCardField: STPPaymentCardTextField, context: Context) {
            if let paymentMethodParams = paymentMethodParams {
                paymentCardField.paymentMethodParams = paymentMethodParams
            }
        }

        public class Coordinator: NSObject, STPPaymentCardTextFieldDelegate {
            var parent: Representable
            init(
                parent: Representable
            ) {
                self.parent = parent
            }

            public func paymentCardTextFieldDidChange(_ cardField: STPPaymentCardTextField) {
                let paymentMethodParams = cardField.paymentMethodParams
                if !cardField.isValid {
                    parent.paymentMethodParams = nil
                    return
                }
                parent.paymentMethodParams = paymentMethodParams
            }
        }
    }
}
