//
//  ExampleWalletButtonsView.swift
//  PaymentSheet Example
//

@_spi(STP) import StripePayments
@_spi(STP)  @_spi(SharedPaymentToken) @_spi(CustomerSessionBetaAccess) import StripePaymentSheet
import SwiftUI

struct ExampleWalletButtonsContainerView: View {
    @State private var email: String = ""
    @State private var shopId: String = "shop_id_123"
    @State private var linkInlineVerificationEnabled: Bool = PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification
    @State private var useSPTTestBackend: Bool = false

    var body: some View {
        if #available(iOS 16.0, *) {
            Form {
                Section("WalletButtonsView Configuration") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField("ShopId", text: $shopId)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    Toggle("Enable inline verification", isOn: $linkInlineVerificationEnabled)
                        .onChange(of: linkInlineVerificationEnabled) { newValue in
                            PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification = newValue
                        }

                    Toggle("Use SPT test backend", isOn: $useSPTTestBackend)

                    NavigationLink("Launch") {
                        ExampleWalletButtonsView(email: email, shopId: shopId, useSPTTestBackend: useSPTTestBackend)
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

    init(email: String, shopId: String, useSPTTestBackend: Bool) {
        self.model = ExampleWalletButtonsModel(email: email, shopId: shopId, useSPTTestBackend: useSPTTestBackend)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            VStack {
                if let flowController = model.paymentSheetFlowController, !model.isProcessing {
                    WalletButtonsFlowControllerView(
                        flowController: flowController,
                        isConfirmingPayment: $isConfirmingPayment,
                        onCompletion: model.onCompletion
                    )
                } else {
                    ExampleLoadingView()
                }

                // Debug logs section
                if !model.debugLogs.isEmpty {
                    DebugLogView(logs: model.debugLogs, onClearLogs: model.clearDebugLogs)
                }
            }
            .onAppear {
                model.clearDebugLogs()
                model.addDebugLog("ExampleWalletButtonsView appeared")
                model.preparePaymentSheet()
            }
            .onDisappear {
                model.addDebugLog("ExampleWalletButtonsView disappeared")
                model.paymentSheetFlowController = nil
                model.paymentResult = nil
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
            WalletButtonsView(flowController: flowController) { _ in }
                .padding(.horizontal)
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
            VStack {
                Text("Payment option label: \(paymentOption.label)")
                Text("Payment option labels.label: \(paymentOption.labels.label)")
                if let sublabel = paymentOption.labels.sublabel {
                    Text("Payment option labels.sublabel: \(sublabel)")
                }
            }
        }
    }
}

class ExampleWalletButtonsModel: ObservableObject {
    let email: String
    let shopId: String
    let useSPTTestBackend: Bool

    let backendCheckoutUrl = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!
    let SPTTestCustomerUrl = URL(string: "https://rough-lying-carriage.glitch.me/customer")!
    let SPTTestCreateIntentUrl = URL(string: "https://rough-lying-carriage.glitch.me/create-intent")!
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isProcessing: Bool = false
    @Published var debugLogs: [String] = []

    init(email: String, shopId: String, useSPTTestBackend: Bool) {
        self.email = email
        self.shopId = shopId
        self.useSPTTestBackend = useSPTTestBackend
    }

    func addDebugLog(_ message: String) {
        DispatchQueue.main.async {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            let timestamp = formatter.string(from: Date())
            self.debugLogs.append("[\(timestamp)] \(message)")
        }
    }

    func clearDebugLogs() {
        DispatchQueue.main.async {
            self.debugLogs.removeAll()
        }
    }

    func preparePaymentSheet() {
        self.addDebugLog("Preparing payment sheet...")
        if useSPTTestBackend {
            self.addDebugLog("Using SPT test backend")
            preparePaymentSheetWithSPTTestBackend()
        } else {
            self.addDebugLog("Using original backend")
            preparePaymentSheetWithOriginalBackend()
        }
    }

    private func preparePaymentSheetWithOriginalBackend() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        self.addDebugLog("Creating customer with original backend...")
        let body = [
            "mode": "payment",
            "merchant_country_code": "US",
            "customer_email": self.email,
            "amount": "5000",
            "currency": "usd",
            "customer": "new",
            "customer_key_type": "customer_session",
            "customer_session_component_name": "mobile_payment_element",
            "customer_session_payment_method_save": "enabled",
            "customer_session_payment_method_remove": "enabled",
            "customer_session_payment_method_remove_last": "enabled",
            "customer_session_payment_method_redisplay": "enabled",
        ] as [String: Any]
        let json = try! JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let customerId = json["customerId"] as? String,
                    let customerSessionClientSecret = json["customerSessionClientSecret"] as? String,
                    let paymentIntentClientSecret = json["intentClientSecret"] as? String,
                    let publishableKey = json["publishableKey"] as? String
                else {
                    self?.addDebugLog("Error creating customer with original backend: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self?.addDebugLog("Customer created successfully with original backend: \(customerId)")

                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey

                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.defaultBillingDetails.email = self?.email ?? ""
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                    merchantCountryCode: "US",
                    customHandlers: .init(paymentRequestHandler: { paymentRequest in
                        paymentRequest.requiredShippingContactFields = [.postalAddress, .emailAddress]
                        return paymentRequest
                    })
                )
                configuration.shopPay = self?.shopPayConfiguration
                configuration.customer = .init(id: customerId, customerSessionClientSecret: customerSessionClientSecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                configuration.willUseWalletButtonsView = true

                self?.addDebugLog("Creating PaymentSheet FlowController with original backend...")
                PaymentSheet.FlowController.create(
                    intentConfiguration: .init(sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil), sellerDetails: .init(networkId: "internal", externalId: "stripe_test_merchant"), paymentMethodTypes: ["card", "link", "shop_pay"], preparePaymentMethodHandler: { [weak self] paymentMethod, address in
                        self?.addDebugLog("PaymentMethod prepared: \(paymentMethod.stripeId)")
                        self?.addDebugLog("Address: \(address)")
                        // Create the SPT on your backend here
                    }),
                    configuration: configuration
                ) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.addDebugLog("FlowController creation error: \(error)")
                    case .success(let paymentSheetFlowController):
                        self?.addDebugLog("FlowController created successfully with original backend")
                        DispatchQueue.main.async {
                            self?.paymentSheetFlowController = paymentSheetFlowController
                        }
                    }
                }
            })
        task.resume()
    }

    private func preparePaymentSheetWithSPTTestBackend() {
        // First, create customer and get customer session
        self.addDebugLog("Creating customer with SPT test backend...")
        let body = [
            "customerId": nil // Let backend create a new customer
        ] as [String: Any?]
        let json = try! JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: SPTTestCustomerUrl)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let customerId = json["customerId"] as? String,
                    let customerSessionClientSecret = json["customerSessionClientSecret"] as? String
                else {
                    self?.addDebugLog("Error creating customer: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self?.addDebugLog("Customer created successfully: \(customerId)")

                // MARK: Set your Stripe publishable key for rough-lying-carriage backend
                // Using test publishable key - in production, this should come from the backend
                STPAPIClient.shared.publishableKey = "pk_test_51LsBpsAoVfWZ5CNZi82L5ALZB9C89AyblMIWBHERPJRvSTaLYjaTsjT7hMeVRuXzTIc9VkkiZQ59KqXqVxYL7Rn600Homq7UPk"

                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.defaultBillingDetails.email = self?.email ?? ""
                configuration.merchantDisplayName = "Rough Lying Carriage, Inc."
                configuration.applePay = .init(
                    merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                    merchantCountryCode: "US",
                    customHandlers: .init(paymentRequestHandler: { paymentRequest in
                        paymentRequest.requiredShippingContactFields = [.postalAddress, .emailAddress]
                        return paymentRequest
                    })
                )
                configuration.shopPay = self?.shopPayConfiguration
                configuration.customer = .init(id: customerId, customerSessionClientSecret: customerSessionClientSecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                configuration.willUseWalletButtonsView = true

                self?.addDebugLog("Creating PaymentSheet FlowController...")
                PaymentSheet.FlowController.create(
                    intentConfiguration: .init(sharedPaymentTokenSessionWithMode: .payment(amount: 9999, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil), sellerDetails: .init(networkId: "internal", externalId: "stripe_test_merchant"), paymentMethodTypes: ["card"], preparePaymentMethodHandler: { [weak self] paymentMethod, address in
                        self?.isProcessing = true
                        self?.addDebugLog("PaymentMethod prepared: \(paymentMethod.stripeId)")
                        self?.addDebugLog("Address: \(address)")
                        // Create the payment intent on the rough-lying-carriage backend
                        self?.createPaymentIntentWithSPTTestBackend(customerId: customerId, paymentMethod: paymentMethod.stripeId)
                    }),
                    configuration: configuration
                ) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.addDebugLog("FlowController creation error: \(error)")
                    case .success(let paymentSheetFlowController):
                        self?.addDebugLog("FlowController created successfully")
                        DispatchQueue.main.async {
                            self?.paymentSheetFlowController = paymentSheetFlowController
                        }
                    }
                }
            })
        task.resume()
    }

    private func createPaymentIntentWithSPTTestBackend(customerId: String, paymentMethod: String) {
        self.addDebugLog("Creating payment intent with SPT test backend...")
        self.addDebugLog("Customer ID: \(customerId)")
        self.addDebugLog("Payment Method: \(paymentMethod)")

        let body = [
            "customerId": customerId,
            "paymentMethod": paymentMethod,
        ] as [String: Any]
        let json = try! JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: SPTTestCreateIntentUrl)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any]
                else {
                    self?.addDebugLog("Error creating payment intent: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self?.addDebugLog("Payment intent response: \(json)")

                if let requiresAction = json["requiresAction"] as? Bool, requiresAction,
                   let nextActionValue = json["nextActionValue"] as? String {
                    self?.addDebugLog("Payment requires action: \(nextActionValue)")
                    STPPaymentHandler.shared().handleNextAction(forPaymentHashedValue: nextActionValue, with: WindowAuthenticationContext(), returnURL: nil) { [weak self] status, intent, error in
                        self?.addDebugLog("Payment handler status: \(status.rawValue)")
                        if let intent = intent {
                            self?.addDebugLog("Payment intent: \(intent.stripeId)")
                        }
                        if let error = error {
                            self?.addDebugLog("Payment handler error: \(error.localizedDescription)")
                        }

                        self?.isProcessing = false
                        // Only complete the transaction after the next action is handled
                        if status == .succeeded {
                            self?.addDebugLog("Payment completed successfully after handling next action")
                            DispatchQueue.main.async {
                                self?.paymentResult = .completed
                                self?.cleanupDemo()
                            }
                        } else if status == .failed {
                            self?.addDebugLog("Payment failed after handling next action")
                            DispatchQueue.main.async {
                                self?.paymentResult = .failed(error: error ?? NSError(domain: "PaymentHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment failed"]))
                            }
                        } else if status == .canceled {
                            self?.addDebugLog("Payment canceled after handling next action")
                            DispatchQueue.main.async {
                                self?.paymentResult = .canceled
                            }
                        }
                    }
                } else if let clientSecret = json["clientSecret"] as? String {
                    self?.addDebugLog("Payment intent created with client secret: \(clientSecret)")
                    DispatchQueue.main.async {
                        self?.paymentResult = .completed
                    }
                }
            })
        task.resume()
    }

    func onCompletion(result: PaymentSheetResult) {
        self.addDebugLog("PaymentSheet completion called with result: \(result)")

        if useSPTTestBackend {
            // We'll handle completion after handling the SPT next actions manually
            return
        }

        // Only set the result if it hasn't been set by the payment handler
        if self.paymentResult == nil {
            self.paymentResult = result
        }

        // MARK: Demo cleanup
        if case .completed = result {
            cleanupDemo()
        }
    }

    func cleanupDemo() {
        // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
        self.paymentSheetFlowController = nil
        self.addDebugLog("Preparing new payment sheet for demo")
        preparePaymentSheet()
    }

    var shopPayConfiguration: PaymentSheet.ShopPayConfiguration {
        let singleBusinessDay = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .business_day)
        let fiveBusinessDays = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .business_day)
        let sevenBusinessDays = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 7, unit: .business_day)

        let handlers = PaymentSheet.ShopPayConfiguration.Handlers(
            shippingMethodUpdateHandler: { [weak self] shippingRateSelected, completion in
                // Process the selected shipping method
                // For example, you might recalculate totals based on the shipping rate
                let selectedRate = shippingRateSelected.shippingRate
                self?.addDebugLog("User selected shipping rate: \(selectedRate.displayName) with cost \(selectedRate.amount)")

                // Create the update with the new line items and available shipping rates
                let update = PaymentSheet.ShopPayConfiguration.ShippingRateUpdate(
                    lineItems: [.init(name: "Subtotal", amount: 200),
                                .init(name: "Tax", amount: 200),
                                .init(name: "Shipping", amount: selectedRate.amount), ],
                    shippingRates: [
                        PaymentSheet.ShopPayConfiguration.ShippingRate(
                            id: "standard",
                            amount: 500,
                            displayName: "Standard Shipping",
                            deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                                minimum: .init(value: 3, unit: .business_day),
                                maximum: .init(value: 5, unit: .business_day)
                            )
                        ),
                        PaymentSheet.ShopPayConfiguration.ShippingRate(
                            id: "express",
                            amount: 1000,
                            displayName: "Express Shipping",
                            deliveryEstimate: .init(
                                minimum: .init(value: 1, unit: .business_day),
                                maximum: .init(value: 2, unit: .business_day)
                            )
                        ),
                    ]
                )

                // Return the update to the Shop Pay UI
                completion(update)
            },
            shippingContactUpdateHandler: { [weak self] shippingContactSelected, completion in
                // Process the selected shipping contact information
                let name = shippingContactSelected.name
                let address = shippingContactSelected.address

                self?.addDebugLog("User selected shipping to: \(name) in \(address.city), \(address.state)")
                // Check if we can ship to this location
                let canShipToLocation = self?.isValidShippingLocation(address) ?? false

                if canShipToLocation {
                    // Create available shipping rates based on the location
                    let shippingRates = self?.getShippingRatesForLocation(address) ?? []

                    // Return the update with new line items and shipping rates
                    let update = PaymentSheet.ShopPayConfiguration.ShippingContactUpdate(
                        lineItems: [.init(name: "Subtotal", amount: 200),
                                    .init(name: "Tax", amount: 200),
                                    .init(name: "Shipping", amount: shippingRates.first?.amount ?? 0), ],
                        shippingRates: shippingRates
                    )

                    completion(update)
                } else {
                    // If we can't ship to this location, pass nil to reject it
                    self?.addDebugLog("Cannot ship to selected location")
                    completion(nil)
                }
            }
        )

        return PaymentSheet.ShopPayConfiguration(shippingAddressRequired: true,
                                                 lineItems: [.init(name: "Golden Potato", amount: 500), .init(name: "Silver Potato", amount: 345), .init(name: "Tax", amount: 200)],
                                                 shippingRates: [.init(id: "express", amount: 1099, displayName: "Overnight", deliveryEstimate: .init(minimum: singleBusinessDay, maximum: singleBusinessDay)),
                                                                 .init(id: "standard", amount: 0, displayName: "Free", deliveryEstimate: .init(minimum: fiveBusinessDays, maximum: sevenBusinessDays)),
                                                                ],
                                                 shopId: self.shopId,
                                                 handlers: handlers)
    }
    func isValidShippingLocation(_ address: PaymentSheet.ShopPayConfiguration.PartialAddress) -> Bool {
        return true
    }
    func getShippingRatesForLocation(_ address: PaymentSheet.ShopPayConfiguration.PartialAddress) -> [PaymentSheet.ShopPayConfiguration.ShippingRate] {
        return [
            PaymentSheet.ShopPayConfiguration.ShippingRate(
                id: "standard",
                amount: 500,
                displayName: "Standard Shipping",
                deliveryEstimate: .init(
                    minimum: .init(value: 3, unit: .business_day),
                    maximum: .init(value: 5, unit: .business_day)
                )
            ),
            PaymentSheet.ShopPayConfiguration.ShippingRate(
                id: "express",
                amount: 1000,
                displayName: "Express Shipping",
                deliveryEstimate: .init(
                    minimum: .init(value: 1, unit: .business_day),
                    maximum: .init(value: 2, unit: .business_day)
                )
            ),
        ]
    }
}

class WindowAuthenticationContext: NSObject, STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        UIViewController.topMostViewController() ?? UIViewController()
    }
}

@available(iOS 15.0, *)
struct DebugLogView: View {
    let logs: [String]
    let onClearLogs: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Debug Logs")
                    .font(.headline)
                Spacer()
                Text("\(logs.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Clear") {
                    onClearLogs()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onAppear {
                    if !logs.isEmpty {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(logs.count - 1, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: logs.count) { _ in
                    if !logs.isEmpty {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
