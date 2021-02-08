//
//  ExampleCustomCard.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import SwiftUI
import Stripe

struct ExampleCustomCard: View {
  @ObservedObject var model = MyPIBackendModel()
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
          Text("Loading...")
        }
        if let paymentStatus = model.paymentStatus {
          HStack {
            switch paymentStatus {
            case .succeeded:
              Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
              Text("Payment complete!")
            case .failed:
              Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
              Text("Payment failed! \(model.lastPaymentError ?? NSError())")
            case .canceled:
              Image(systemName: "xmark.octagon.fill").foregroundColor(.orange)
              Text("Payment canceled.")
            @unknown default:
              Text("Unknown status")
            }
          }
        }
      }.onAppear { model.preparePaymentIntent() }
    }

}

class MyPIBackendModel : ObservableObject {
  let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")! // An example backend endpoint
  @Published var paymentStatus: STPPaymentHandlerActionStatus?
  @Published var paymentIntentParams: STPPaymentIntentParams?
  @Published var lastPaymentError: NSError?

  func preparePaymentIntent() {
    // MARK: Fetch the PaymentIntent from the backend
    var request = URLRequest(url: backendCheckoutUrl)
    request.httpMethod = "POST"
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
            let paymentIntentClientSecret = json["paymentIntent"] as? String,
            let publishableKey = json["publishableKey"] as? String else {
        // Handle error
        return
      }
      // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
      STPAPIClient.shared.publishableKey = publishableKey

      // MARK: Create the PaymentIntent
      DispatchQueue.main.async {
        self.paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
      }
    })
    task.resume()
  }

  func onCompletion(status: STPPaymentHandlerActionStatus, pi: STPPaymentIntent?, error: NSError?)
 {
    self.paymentStatus = status
    self.lastPaymentError = error

    // MARK: Demo cleanup
    if status == .succeeded {
      // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
      self.paymentIntentParams = nil
      preparePaymentIntent()
    }
  }
}

struct ExampleCustomCard_Preview : PreviewProvider {
  static var previews: some View {
    ExampleCustomCard()
  }
}
