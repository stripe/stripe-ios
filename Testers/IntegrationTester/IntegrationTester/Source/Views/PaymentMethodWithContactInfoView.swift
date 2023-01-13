//
//  OXXOView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/11/21.
//

import IntegrationTesterCommon
import Stripe
import SwiftUI

struct PaymentMethodWithContactInfoView: View {
  let integrationMethod: IntegrationMethod
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false
  @State var name: String = "Jane Diaz"
  @State var email: String = "jane@example.com"

  var body: some View {
      VStack {
        TextField("Name", text: $name)
          .padding()
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.name)
        TextField("Email", text: $email)
          .padding()
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.emailAddress)
        if let paymentIntent = model.paymentIntentParams {
          Button("Buy") {
            paymentIntent.paymentMethodParams = integrationMethod.defaultPaymentMethodParams
            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.name = name
            billingDetails.email = email
            paymentIntent.paymentMethodParams?.billingDetails = billingDetails
            isConfirmingPayment = true
          }.paymentConfirmationSheet(isConfirmingPayment: $isConfirmingPayment,
                                     paymentIntentParams: paymentIntent,
                                     onCompletion: model.onCompletion)
          .disabled(isConfirmingPayment || name.isEmpty || email.isEmpty)
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

struct PaymentMethodWithContactInfoView_Preview: PreviewProvider {
  static var previews: some View {
    PaymentMethodWithContactInfoView(integrationMethod: .oxxo)
  }
}
