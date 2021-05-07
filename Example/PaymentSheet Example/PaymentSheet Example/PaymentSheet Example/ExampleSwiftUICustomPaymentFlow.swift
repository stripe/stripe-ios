//
//  ExampleSwiftUICustomPaymentFlow.swift
//  PaymentSheet Example
//
//  Created by David Estes on 1/15/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import Stripe
import SwiftUI

struct ExampleSwiftUICustomPaymentFlow: View {
    @ObservedObject var model = MyCustomBackendModel()
    @State var isConfirmingPayment = false

    var body: some View {
        VStack {
            if let paymentSheetFlowController = model.paymentSheetFlowController {
                PaymentSheet.FlowController.PaymentOptionsButton(
                    paymentSheetFlowController: paymentSheetFlowController,
                    onSheetDismissed: model.onOptionsCompletion
                ) {
                    ExamplePaymentOptionView(
                        paymentOptionDisplayData: paymentSheetFlowController.paymentOption)
                }
                Button(action: {
                    // If you need to update the PaymentIntent's amount, you should do it here and
                    // set the `isConfirmingPayment` binding after your update completes.
                    isConfirmingPayment = true
                }) {
                    if isConfirmingPayment {
                        ExampleLoadingView()
                    } else {
                        ExamplePaymentButtonView()
                    }
                }.paymentConfirmationSheet(
                    isConfirming: $isConfirmingPayment,
                    paymentSheetFlowController: paymentSheetFlowController,
                    onCompletion: model.onCompletion
                )
                .disabled(paymentSheetFlowController.paymentOption == nil || isConfirmingPayment)
            } else {
                ExampleLoadingView()
            }
            if let result = model.paymentResult {
                ExamplePaymentStatusView(result: result)
            }
        }.onAppear { model.preparePaymentSheet() }
    }

}

class MyCustomBackendModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!  // An example backend endpoint
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
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
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "com.foo.example", merchantCountryCode: "US")
                configuration.customer = .init(
                    id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                PaymentSheet.FlowController.create(
                    paymentIntentClientSecret: paymentIntentClientSecret,
                    configuration: configuration
                ) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let paymentSheetFlowController):
                        DispatchQueue.main.async {
                            self?.paymentSheetFlowController = paymentSheetFlowController
                        }
                    }
                }
            })
        task.resume()
    }

    func onOptionsCompletion() {
        // Tell our observer to refresh
        objectWillChange.send()
    }

    func onCompletion(result: PaymentSheetResult) {
        self.paymentResult = result

        // MARK: Demo cleanup
        if case .completed = result {
            // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
            self.paymentSheetFlowController = nil
            preparePaymentSheet()
        }
    }
}

struct ExampleSwiftUICustomPaymentFlow_Preview: PreviewProvider {
    static var previews: some View {
        ExampleSwiftUICustomPaymentFlow()
    }
}
