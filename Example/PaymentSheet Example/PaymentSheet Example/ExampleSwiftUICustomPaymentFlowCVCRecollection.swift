//
//  ExampleSwiftUICustomPaymentFlowCVCRecollection.swift
//  PaymentSheet Example
//

@_spi(EarlyAccessCVCRecollectionFeature) import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct ExampleSwiftUICustomPaymentFlowCVCRecollection: View {
    @ObservedObject var model = MyCustomBackendCVCRecollectionModel()
    @State var isConfirmingPayment: Bool = false

    var body: some View {
        VStack {
            if let paymentSheetFlowController = model.paymentSheetFlowController {
                HStack {
                    Text("CustomerId:").font(.subheadline)
                    TextField("CustomerId", text: $model.publishedCustomerId)
                    Button {
                        model.resetCustomer()
                    } label: {
                        Text("Reset").font(.callout.smallCaps())
                    }.buttonStyle(.bordered)
                }
                SettingView(setting: $model.recollectCVC)
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

enum RecollectCVCEnabled: String, PickerEnum {
    static var enumName: String { "RecollectCVCEnabled" }
    case on
    case off
}

class MyCustomBackendCVCRecollectionModel: ObservableObject {
    private static let customerIdNSUserDefaultsKey = "com.stripe.PaymentSheetExample.ExampleSwiftUICustomPaymentFlowCVCRecollection.customerId"
    static let backendCheckoutEndpoint = "https://stripe-mobile-payment-sheet-custom-deferred-cvc.glitch.me"
    let backendInitUrl = URL(string: "\(backendCheckoutEndpoint)/init")!
    let backendCheckoutUrl = URL(string: "\(backendCheckoutEndpoint)/checkout")!

    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?
    @Published var recollectCVC: RecollectCVCEnabled = .off
    @Published var publishedCustomerId: String = ""

    func preparePaymentSheet() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendInitUrl)
        let body: [String: Any?] = [
            "customer_id": self.getLastCustomerId(),
        ]
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let customerId = json["customer"] as? String,
                    let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                    let publishableKey = json["publishableKey"] as? String
                else {
                    // Handle error
                    return
                }

                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey
                DispatchQueue.main.async {
                    self.setLastCustomerId(customerId: customerId)
                    // MARK: Create a PaymentSheet instance
                    var configuration = PaymentSheet.Configuration()
                    configuration.merchantDisplayName = "Example, Inc."
                    configuration.applePay = .init(
                        merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                        merchantCountryCode: "US"
                    )
                    configuration.customer = .init(
                        id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                    configuration.returnURL = "payments-example://stripe-redirect"
                    // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit and Sofort.
                    configuration.allowsDelayedPaymentMethods = true

                    let intentConfiguration = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "usd", setupFutureUsage: .offSession, captureMethod: .automatic),
                                                                               confirmHandler: { [weak self] paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
                        self?.serverSideConfirmHandler(paymentMethod.stripeId, shouldSavePaymentMethod, intentCreationCallback)
                    }, isCVCRecollectionEnabledCallback: { [weak self] in
                        return self?.isCVCRecollectionEnabledCallback() ?? false
                    })

                    PaymentSheet.FlowController.create(intentConfiguration: intentConfiguration, configuration: configuration) { [weak self] result in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let paymentSheetFlowController):
                            DispatchQueue.main.async {
                                self?.paymentSheetFlowController = paymentSheetFlowController
                            }
                        }
                    }
                }
            })
        task.resume()
    }
    func serverSideConfirmHandler(_ paymentMethodID: String,
                                  _ shouldSavePaymentMethod: Bool,
                                  _ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
        // Create and confirm an intent on your server and invoke `intentCreationCallback` with the client secret
        confirmIntent(paymentMethodID: paymentMethodID, shouldSavePaymentMethod: shouldSavePaymentMethod) { result in
            switch result {
            case .success(let clientSecret):
                intentCreationCallback(.success(clientSecret))
            case .failure(let error):
                intentCreationCallback(.failure(error))
            }
        }
    }
    func confirmIntent(paymentMethodID: String,
                       shouldSavePaymentMethod: Bool,
                       completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let body: [String: Any?] = [
            "payment_method_id": paymentMethodID,
            "currency": "USD",
            "should_save_payment_method": shouldSavePaymentMethod,
            "return_url": "payments-example://stripe-redirect",
            "customer_id": paymentSheetFlowController?.configuration.customer?.id,
            "require_cvc_recollection": self.isCVCRecollectionEnabledCallback(),
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, _, error) in
                guard
                    error == nil,
                    let data = data,
                    let json = try? JSONDecoder().decode([String: String].self, from: data)
                else {
                    completion(.failure(error ?? ExampleError(errorDescription: "An unknown error occurred.")))
                    return
                }
                if let clientSecret = json["paymentIntent"] {
                    completion(.success(clientSecret))
                } else {
                    completion(.failure(error ?? ExampleError(errorDescription: json["error"] ?? "An unknown error occurred.")))
                }
        })

        task.resume()
    }

    func isCVCRecollectionEnabledCallback() -> Bool {
        return self.recollectCVC == .on
    }

    func resetCustomer() {
        setLastCustomerId(customerId: "")
        preparePaymentSheet()
    }

    func setLastCustomerId(customerId: String) {
        UserDefaults.standard.set(customerId, forKey: MyCustomBackendCVCRecollectionModel.customerIdNSUserDefaultsKey)
        UserDefaults.standard.synchronize()
        self.publishedCustomerId = customerId
    }

    func getLastCustomerId() -> String {
        guard let retrievedValue = UserDefaults.standard.object(forKey: MyCustomBackendCVCRecollectionModel.customerIdNSUserDefaultsKey) as? String,
              !retrievedValue.isEmpty else {
            return ""
        }
        return retrievedValue
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
    struct ExampleError: LocalizedError {
       var errorDescription: String?
    }
}

@available(iOS 15.0, *)
struct ExampleSwiftUICustomPaymentFlowCVCRecollection_Preview: PreviewProvider {
    static var previews: some View {
        ExampleSwiftUICustomPaymentFlowCVCRecollection()
    }
}
