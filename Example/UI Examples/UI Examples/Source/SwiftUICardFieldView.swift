//
//  SwiftUICardFieldView.swift
//  UI Examples
//
//  Copyright © 2026 Stripe. All rights reserved.
//

import Stripe
import SwiftUI

struct SwiftUICardFieldView: View {

    @State private var paymentMethodParams: STPPaymentMethodParams? = {
        let params = STPPaymentMethodParams()
        params.billingDetails = STPPaymentMethodBillingDetails()
        params.billingDetails?.address = STPPaymentMethodAddress()
        params.billingDetails?.address?.country = "CA"
        return params
    }()

    var body: some View {
        VStack {
            Spacer().layoutPriority(1)
            STPPaymentCardTextField.Representable(paymentMethodParams: $paymentMethodParams)
                .padding()
            Button(action: {
                print("Process payment...")
            }, label: {
                Text("Buy")
            }).disabled(paymentMethodParams == nil)
            .padding()
            Spacer().layoutPriority(1)
        }
    }
}

struct SwiftUICardFieldView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUICardFieldView()
    }
}
