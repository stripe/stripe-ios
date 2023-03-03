//
//  ExampleSwiftUILinkOnlyFlow.swift
//  PaymentSheet Example
//
//  Created by Bill Meltsner on 12/15/22.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

@_spi(LinkOnly) import StripePaymentSheet
import SwiftUI

struct ExampleSwiftUILinkOnlyFlow: View {
    @ObservedObject var model = LinkOnlyBackendModel()
    @State var isConfirmingPayment = false

    var body: some View {
        VStack {
            if let paymentController = model.paymentController {
                Text("Total: \(model.amount ?? "idk")")
                    .font(.largeTitle)
                Button(action: {
                    paymentController.present(from: UIApplication.shared.keyWindow!.rootViewController!, completion: { result in
                        switch result {
                        case .success:
                            model.linkSelected = true
                        case .failure(let error):
                            print(error)
                        }
                    })
                }) {
                    Text("Log in with Link")
                }
                Text(model.linkSelected ? "Link selected" : "Link not selected")
                Button(action: {
                    // If you need to update the PaymentIntent's amount, you should do it here and
                    // set the `isConfirmingPayment` binding after your update completes.
                    isConfirmingPayment = true
                    paymentController.confirm(from: UIApplication.shared.keyWindow!.rootViewController!, completion: { result in
                            model.onCompletion(result: result)
                            isConfirmingPayment = false
                    })
                }) {
                    if isConfirmingPayment {
                        ExampleLoadingView()
                    } else {
                        ExamplePaymentButtonView()
                    }
                }
                .disabled(isConfirmingPayment || !model.linkSelected)
            } else {
                ExampleLoadingView()
            }
            if let result = model.paymentResult {
                ExamplePaymentStatusView(result: result)
            }
            Toggle(isOn: $model.livemode) {
                if model.livemode {
                    Text("Livemode active!!")
                        .font(.title)
                        .foregroundColor(.red)
                } else {
                    Text("Livemode disabled")
                }
            }.frame(maxWidth: 200)
        }.onAppear { model.preparePaymentSheet() }
    }

}

class LinkOnlyBackendModel: ObservableObject {
    var backendCheckoutUrl: URL {
        URL(string: "https://stripe-link-only-sdk.glitch.me/checkout?livemode=\(livemode ? "1" : "0")")!  // An example backend endpoint
    }
    @Published var paymentController: LinkPaymentController?
    @Published var paymentResult: PaymentSheetResult?
    @Published var linkSelected = false
    @Published var livemode = false {
        didSet {
            LinkPaymentController.resetCustomer()
            linkSelected = false
            preparePaymentSheet()
        }
    }
    @Published var amount: String?

    func preparePaymentSheet() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        paymentController = nil
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let paymentIntentClientSecret = json["paymentIntent"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let rawAmount = json["amount"] as? Double
                else {
                    // Handle error
                    return
                }

                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey

                DispatchQueue.main.async {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    self?.amount = formatter.string(from: rawAmount as NSNumber)
                    self?.paymentController = LinkPaymentController(paymentIntentClientSecret: paymentIntentClientSecret, returnURL: "payments-example://stripe-redirect")
                }
            })
        task.resume()
    }

    func onCompletion(result: PaymentSheetResult) {
        self.paymentResult = result

        // MARK: Demo cleanup
        if case .completed = result {
            // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
            preparePaymentSheet()
        }
    }
}

struct ExampleSwiftUILinkOnlyFlow_Preview: PreviewProvider {
    static var previews: some View {
        ExampleSwiftUILinkOnlyFlow()
    }
}
