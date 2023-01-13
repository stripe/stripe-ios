//
//  CardView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import Stripe
import SwiftUI

struct CardView: View {
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false
  @State var paymentMethodParams: STPPaymentMethodParams?

  var body: some View {
      VStack {
        STPPaymentCardTextField.Representable(paymentMethodParams: $paymentMethodParams)
          .padding()
        if let paymentIntent = model.paymentIntentParams {
          Button("Buy") {
            paymentIntent.paymentMethodParams = paymentMethodParams
            isConfirmingPayment = true
          }.paymentConfirmationSheet(isConfirmingPayment: $isConfirmingPayment,
                                     paymentIntentParams: paymentIntent,
                                     onCompletion: model.onCompletion)
          .disabled(isConfirmingPayment || paymentMethodParams == nil)
        } else {
          ProgressView()
        }
        if let paymentStatus = model.paymentStatus {
          PaymentHandlerStatusView(actionStatus: paymentStatus, lastPaymentError: model.lastPaymentError)
        }
      }.onAppear { model.preparePaymentIntent() }
    }
}

struct CardView_Preview: PreviewProvider {
  static var previews: some View {
    CardView()
  }
}
