//
//  ExampleWalletButtonsView.swift
//  PaymentSheet Example
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct ExampleWalletButtonsView: View {
    @ObservedObject var model = ExampleWalletButtonsModel()
    var body: some View {
        if #available(iOS 16.0, *) {
            VStack {
                if let flowController = model.paymentSheetFlowController {
                    WalletButtonsView(flowController: flowController) { _ in
                    }
                } else {
                    ExampleLoadingView()
                }
            }.onAppear {
                model.preparePaymentSheet()
            }.padding()
        } else {
            Text("Use >= iOS 16.0")
                .padding()
        }
    }
}

class ExampleWalletButtonsModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?

    func preparePaymentSheet() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, _, error) in
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
                configuration.defaultBillingDetails = .init(email: "email@email.com")
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                    merchantCountryCode: "US"
                )
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
}
