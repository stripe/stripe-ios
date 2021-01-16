//
//  ExampleSwiftUIPaymentSheet.swift
//  PaymentSheet Example
//
//  Created by David Estes on 1/15/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import Stripe
import SwiftUI

struct ExampleSwiftUIPaymentSheet: View {
  @ObservedObject var model = MyBackendModel()

  var body: some View {
    VStack {
      if let paymentSheet = model.paymentSheet {
        PaymentSheet.ConfirmButton(
          paymentSheet: paymentSheet,
          onCompletion: model.onPaymentCompletion
        ) {
          ExamplePaymentButtonView()
        }
      } else {
        LoadingView()
      }
      if let result = model.paymentResult {
        PaymentStatusView(result: result)
      }
    }.onAppear { model.preparePaymentIntent() }
  }

}

class MyBackendModel: ObservableObject {
  let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!  // An example backend endpoint
  @Published var paymentSheet: PaymentSheet?
  @Published var paymentResult: PaymentResult?

  func preparePaymentIntent() {
    // MARK: Fetch the PaymentIntent and Customer information from the backend
    var request = URLRequest(url: backendCheckoutUrl)
    request.httpMethod = "POST"
    let task = URLSession.shared.dataTask(
      with: request,
      completionHandler: { (data, response, error) in
        guard let data = data,
          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let customerId = json["customer"] as? String,
          let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
          let paymentIntentClientSecret = json["paymentIntent"] as? String,
          let publishableKey = json["publishableKey"] as? String
        else {
          // Handle error
          return
        }
        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey

        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(merchantId: "com.foo.example", merchantCountryCode: "US")
        configuration.customer = .init(
          id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        DispatchQueue.main.async {
          self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
        }
      })
    task.resume()
  }

  func onPaymentCompletion(result: PaymentResult) {
    self.paymentResult = result

    // MARK: Demo cleanup
    if case .completed(_) = result {
      // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
      self.paymentSheet = nil
      preparePaymentIntent()
    }
  }
}

struct ExampleSwiftUIPaymentSheet_Preview: PreviewProvider {
  static var previews: some View {
    ExampleSwiftUIPaymentSheet()
  }
}
