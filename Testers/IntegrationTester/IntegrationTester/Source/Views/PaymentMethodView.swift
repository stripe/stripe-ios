//
//  PaymentMethodView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/11/21.
//

import IntegrationTesterCommon
import Stripe
import SwiftUI

struct PaymentMethodView: View {
  let integrationMethod: IntegrationMethod
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false

  var body: some View {
      VStack {
        if let paymentIntent = model.paymentIntentParams {
          Button("Buy") {
            isConfirmingPayment = true
          }.paymentConfirmationSheet(isConfirmingPayment: $isConfirmingPayment,
                                     paymentIntentParams: paymentIntent,
                                     onCompletion: model.onCompletion)
          .disabled(isConfirmingPayment)
        } else {
          ProgressView()
        }
        if let paymentStatus = model.paymentStatus {
          PaymentHandlerStatusView(actionStatus: paymentStatus, lastPaymentError: model.lastPaymentError)
        }
      }.onAppear {
        model.integrationMethod = integrationMethod
        model.preparePaymentIntent()
      }
    }
}

struct PaymentMethodView_Preview: PreviewProvider {
  static var previews: some View {
    PaymentMethodView(integrationMethod: .iDEAL)
  }
}
