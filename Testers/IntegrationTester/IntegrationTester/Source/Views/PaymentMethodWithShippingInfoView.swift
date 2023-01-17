//
//  PaymentMethodWithShippingInfoView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/22/21.
//

import IntegrationTesterCommon
import Stripe
import SwiftUI

struct PaymentMethodWithShippingInfoView: View {
  let integrationMethod: IntegrationMethod
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false
  @State var name: String = "Jane Diaz"
  @State var email: String = "jane@example.com"
  @State var addressLine1: String = "123 Fake St"
  @State var postalCode: String = "12345"
  @State var country: String = "US"

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
        TextField("Shipping Address", text: $addressLine1)
          .padding()
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.streetAddressLine1)
        TextField("Postal Code", text: $postalCode)
          .padding()
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.postalCode)
        TextField("Country", text: $country)
          .padding()
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .textContentType(.countryName)
        if let paymentIntent = model.paymentIntentParams {
          Button("Buy") {
            paymentIntent.paymentMethodParams = integrationMethod.defaultPaymentMethodParams
            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.name = name
            billingDetails.email = email
            let billingAddress = STPPaymentMethodAddress()
            billingAddress.line1 = addressLine1
            billingDetails.address = billingAddress
            billingAddress.postalCode = postalCode
            billingAddress.country = country
            paymentIntent.paymentMethodParams?.billingDetails = billingDetails
            let shippingAddress = STPPaymentIntentShippingDetailsAddressParams(line1: addressLine1)
            shippingAddress.postalCode = postalCode
            shippingAddress.country = country
            let shipping = STPPaymentIntentShippingDetailsParams(address: shippingAddress, name: name)
            paymentIntent.shipping = shipping
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

struct PaymentMethodWithShippingInfoView_Preview: PreviewProvider {
  static var previews: some View {
    PaymentMethodWithShippingInfoView(integrationMethod: .oxxo)
  }
}
