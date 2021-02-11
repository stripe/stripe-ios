//
//  STPPaymentCardTextField+SwiftUI.swift
//  StripeiOS
//
//  Created by David Estes on 2/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPPaymentCardTextField {
  
  /// A SwiftUI representation of an STPPaymentCardTextField.
  public struct Representable: UIViewRepresentable {
    @Binding var paymentMethodParams: STPPaymentMethodParams?

    /// Initialize a SwiftUI representation of an STPPaymentCardTextField.
    /// - Parameter paymentMethodParams: A binding to the payment card text field's contents.
    /// The STPPaymentMethodParams will be `nil` if the payment card text field's contents are invalid.
    public init(paymentMethodParams: Binding<STPPaymentMethodParams?>) {
      _paymentMethodParams = paymentMethodParams
    }
    
    public func makeCoordinator() -> Coordinator {
      return Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> STPPaymentCardTextField {
      let paymentCardField = STPPaymentCardTextField()
      if let cardParams = paymentMethodParams?.card {
        paymentCardField.cardParams = cardParams
      }
      if let postalCode = paymentMethodParams?.billingDetails?.address?.postalCode {
        paymentCardField.postalCode = postalCode
      }
      if let countryCode = paymentMethodParams?.billingDetails?.address?.country {
        paymentCardField.countryCode = countryCode
      }
      paymentCardField.delegate = context.coordinator
      paymentCardField.setContentHuggingPriority(.required, for: .vertical)
      
      return paymentCardField
    }

    public func updateUIView(_ paymentCardField: STPPaymentCardTextField, context: Context) {
      if let cardParams = paymentMethodParams?.card {
        paymentCardField.cardParams = cardParams
      }
      if let postalCode = paymentMethodParams?.billingDetails?.address?.postalCode {
        paymentCardField.postalCode = postalCode
      }
      if let countryCode = paymentMethodParams?.billingDetails?.address?.country {
        paymentCardField.countryCode = countryCode
      }
    }

    public class Coordinator: NSObject, STPPaymentCardTextFieldDelegate {
      var parent: Representable
      init(parent: Representable) {
        self.parent = parent
      }
      
      public func paymentCardTextFieldDidChange(_ cardField: STPPaymentCardTextField) {
        let paymentMethodParams = STPPaymentMethodParams(card: cardField.cardParams, billingDetails: nil, metadata: nil)
        if !cardField.isValid {
          parent.paymentMethodParams = nil
          return
        }
        if let postalCode = cardField.postalCode, let countryCode = cardField.countryCode {
          let billingDetails = STPPaymentMethodBillingDetails()
          let address = STPPaymentMethodAddress()
          address.postalCode = postalCode
          address.country = countryCode
          billingDetails.address = address
          paymentMethodParams.billingDetails = billingDetails
        }
        parent.paymentMethodParams = paymentMethodParams
      }
    }
  }
}
