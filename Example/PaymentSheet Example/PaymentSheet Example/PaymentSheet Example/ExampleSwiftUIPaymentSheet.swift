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
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onCompletion
                ) {
                    ExamplePaymentButtonView()
                }
            } else {
                ExampleLoadingView()
            }
            if let result = model.paymentResult {
                ExamplePaymentStatusView(result: result)
            }
        }.onAppear { model.preparePaymentSheet() }
    }

}

class MyBackendModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!  // An example backend endpoint
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    func preparePaymentSheet() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, response, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
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
                // The following code creates the appearance shown in the screenshot above
                var appearance = PaymentSheet.Appearance()
                appearance.font.base = UIFont(name: "AvenirNext-Regular", size: UIFont.systemFontSize)!
                appearance.cornerRadius = 12
                appearance.shadow = .disabled
                appearance.borderWidth = 0.5
                appearance.colors.background = .white
                appearance.colors.primary = UIColor(red: 36/255, green: 36/255, blue: 47/255, alpha: 1)
                appearance.colors.textSecondary = .black
                appearance.colors.componentPlaceholderText = UIColor(red: 115/255, green: 117/255, blue: 123/255, alpha: 1)
                appearance.colors.componentText = .black
                appearance.colors.componentBorder = .clear
                appearance.colors.componentDivider = UIColor(red: 195/255, green: 213/255, blue: 200/255, alpha: 1)
                appearance.colors.componentBackground = UIColor(red: 243/255, green: 248/255, blue: 250/247, alpha: 1)
                appearance.primaryButton.cornerRadius = 20
                configuration.appearance = appearance
                
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "com.foo.example", merchantCountryCode: "US")
                configuration.customer = .init(
                    id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit and Sofort.
                configuration.allowsDelayedPaymentMethods = true
                DispatchQueue.main.async {
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: paymentIntentClientSecret,
                        configuration: configuration)
                }
            })
        task.resume()
    }

    func onCompletion(result: PaymentSheetResult) {
        self.paymentResult = result

        // MARK: Demo cleanup
        if case .completed = result {
            // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
            self.paymentSheet = nil
            preparePaymentSheet()
        }
    }
}

struct ExampleSwiftUIPaymentSheet_Preview: PreviewProvider {
    static var previews: some View {
        ExampleSwiftUIPaymentSheet()
    }
}
