//
//  ExampleWalletButtonsView.swift
//  PaymentSheet Example
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
import SwiftUI

struct ExampleWalletButtonsContainerView: View {
    @State private var email: String = ""
    @State private var linkInlineVerificationEnabled: Bool = PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification

    var body: some View {
        if #available(iOS 16.0, *) {
            Form {
                Section("WalletButtonsView Configuration") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    Toggle("Enable inline verification", isOn: $linkInlineVerificationEnabled)
                        .onChange(of: linkInlineVerificationEnabled) { newValue in
                            PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification = newValue
                        }

                    NavigationLink("Launch") {
                        ExampleWalletButtonsView(email: email)
                    }
                }
            }
        } else {
            Text("Use >= iOS 16.0")
        }
    }
}

struct ExampleWalletButtonsView: View {
    @ObservedObject var model: ExampleWalletButtonsModel
    @State var isConfirmingPayment = false

    init(email: String) {
        self.model = ExampleWalletButtonsModel(email: email)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            VStack {
                if let flowController = model.paymentSheetFlowController {
                    WalletButtonsFlowControllerView(
                        flowController: flowController,
                        isConfirmingPayment: $isConfirmingPayment,
                        onCompletion: model.onCompletion
                    )
                } else {
                    ExampleLoadingView()
                }
            }
            .onAppear {
                model.preparePaymentSheet()
            }
            if let result = model.paymentResult {
                ExamplePaymentStatusView(result: result)
            }
        } else {
            Text("Use >= iOS 16.0")
        }
    }
}

@available(iOS 16.0, *)
struct WalletButtonsFlowControllerView: View {
    @ObservedObject var flowController: PaymentSheet.FlowController
    @Binding var isConfirmingPayment: Bool
    let onCompletion: (PaymentSheetResult) -> Void

    var body: some View {
        if flowController.paymentOption == nil {
            WalletButtonsView(flowController: flowController) { _ in
            }
        }
        PaymentSheet.FlowController.PaymentOptionsButton(
            paymentSheetFlowController: flowController,
            onSheetDismissed: {}
        ) {
            ExamplePaymentOptionView(
                paymentOptionDisplayData: flowController.paymentOption)
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
            paymentSheetFlowController: flowController,
            onCompletion: onCompletion
        )
        .disabled(flowController.paymentOption == nil || isConfirmingPayment)
        if let paymentOption = flowController.paymentOption {
            Text("Published payment option: \(paymentOption.label)")
        }
    }
}

class ExampleWalletButtonsModel: ObservableObject {
    let email: String

    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?

    init(email: String) {
        self.email = email
    }

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
                configuration.defaultBillingDetails.email = self.email
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                    merchantCountryCode: "US"
                )
                configuration.customer = .init(
                    id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                configuration.willUseWalletButtonsView = true
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
