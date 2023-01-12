//
//  SEPADebitView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/11/21.
//

import IntegrationTesterCommon
import Stripe
import SwiftUI

struct SEPADebitView: View {
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false
  @State var name: String = "Jane Diaz"
  @State var email: String = "jane@example.com"
  @State var iban: String = "AT611904300234573201"

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
        TextField("IBAN", text: $iban)
          .padding()
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .disableAutocorrection(true)
          .autocapitalization(.none)
        if let paymentIntent = model.paymentIntentParams {
          Button("Buy") {
            let params = IntegrationMethod.sepaDebit.defaultPaymentMethodParams
            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.name = name
            billingDetails.email = email
            params.sepaDebit?.iban = iban
            params.billingDetails = billingDetails
            paymentIntent.paymentMethodParams = params
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
        Text(mandateAuthText)
          .font(.footnote)
          .padding()
      }.onAppear {
        model.integrationMethod = .sepaDebit
        model.preparePaymentIntent()
      }
    }

  // This text is required by https://www.europeanpaymentscouncil.eu/what-we-do/sepa-schemes/sepa-direct-debit/sdd-mandate
  let mandateAuthText = "By providing your IBAN and confirming this payment, you are authorizing EXAMPLE COMPANY NAME and Stripe, our payment service provider, to send instructions to your bank to debit your account and your bank to debit your account in accordance with those instructions. You are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited."
}

struct SEPADebitView_Preview: PreviewProvider {
  static var previews: some View {
    SEPADebitView()
  }
}
