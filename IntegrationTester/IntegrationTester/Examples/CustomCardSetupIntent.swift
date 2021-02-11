//
//  CustomCardSetupIntent.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import SwiftUI
import Stripe

struct CustomCardSetupIntent: View {
  @StateObject var model = MySIBackendModel()
  @State var isConfirmingSetupIntent = false
  @State var paymentMethodParams: STPPaymentMethodParams?

  var body: some View {
      VStack {
        STPPaymentCardTextField.Representable(paymentMethodParams: $paymentMethodParams)
          .padding()
        if let setupIntent = model.intentParams {
          Button("Setup") {
            setupIntent.paymentMethodParams = paymentMethodParams
            isConfirmingSetupIntent = true
          }.setupIntentConfirmationSheet(isConfirmingSetupIntent: $isConfirmingSetupIntent,
                                     setupIntentParams: setupIntent,
                                     onCompletion: model.onCompletion)
          .disabled(isConfirmingSetupIntent || paymentMethodParams == nil)
        } else {
          ProgressView()
        }
        if let paymentStatus = model.paymentStatus {
          PaymentHandlerStatusView(actionStatus: paymentStatus, lastPaymentError: model.lastPaymentError)
        }
      }.onAppear { model.preparePaymentIntent() }
    }
}

struct CustomCardSetupIntent_Preview : PreviewProvider {
  static var previews: some View {
    CustomCardSetupIntent()
  }
}
