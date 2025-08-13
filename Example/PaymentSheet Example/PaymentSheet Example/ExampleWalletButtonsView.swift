//
//  ExampleWalletButtonsView.swift
//  PaymentSheet Example
//

@_spi(STP) @_spi(SharedPaymentToken) import StripePayments
@_spi(STP) @_spi(SharedPaymentToken) @_spi(CustomerSessionBetaAccess) @_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
import SwiftUI

struct ShopPayTestingOptions {
    var billingAddressRequired: Bool = false
    var emailRequired: Bool = false
    var shippingAddressRequired: Bool = true
    var allowedShippingCountries: String = ""
    var rejectShippingAddressChange: Bool = false
    var rejectShippingRateChange: Bool = false
    var simulatePaymentFailed: Bool = false
}

struct ExampleWalletButtonsContainerView: View {
    @State private var email: String = ""
    @State private var shopId: String = "69293637654"
    @State private var linkInlineVerificationEnabled: Bool = PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification
    @State private var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance()
    @State private var showingAppearancePlayground = false

    // Shop Pay testing options
    @State private var billingAddressRequired: Bool = false
    @State private var emailRequired: Bool = false
    @State private var shippingAddressRequired: Bool = true
    @State private var allowedShippingCountries: String = ""
    @State private var rejectShippingAddressChange: Bool = false
    @State private var rejectShippingRateChange: Bool = false
    @State private var simulatePaymentFailed: Bool = false

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

                    Button("Customize Appearance") {
                        showingAppearancePlayground = true
                    }
                }

                Section("Shop Pay Testing Options") {
                    Group {
                        Toggle("Billing Address Required", isOn: $billingAddressRequired)
                        Toggle("Email Required", isOn: $emailRequired)
                        Toggle("Shipping Address Required", isOn: $shippingAddressRequired)

                        TextField("Allowed Shipping Countries (comma separated)", text: $allowedShippingCountries)
                            .textInputAutocapitalization(.never)
                    }

                    Group {
                        Toggle("Reject Shipping Address Change", isOn: $rejectShippingAddressChange)
                        Toggle("Reject Shipping Rate Change", isOn: $rejectShippingRateChange)
                        Toggle("Simulate Payment Failed", isOn: $simulatePaymentFailed)
                    }
                }.sheet(isPresented: $showingAppearancePlayground) {
                    AppearancePlaygroundView(appearance: appearance) { updatedAppearance in
                        appearance = updatedAppearance
                        showingAppearancePlayground = false
                    }
                }

                Section {
                    NavigationLink("Launch") {
                        ExampleWalletButtonsView(
                            email: email,
                            shopId: shopId,
                            appearance: appearance,
                            shopPayTestingOptions: ShopPayTestingOptions(
                                billingAddressRequired: billingAddressRequired,
                                emailRequired: emailRequired,
                                shippingAddressRequired: shippingAddressRequired,
                                allowedShippingCountries: allowedShippingCountries,
                                rejectShippingAddressChange: rejectShippingAddressChange,
                                rejectShippingRateChange: rejectShippingRateChange,
                                simulatePaymentFailed: simulatePaymentFailed
                            )
                        )
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

    init(email: String, shopId: String, appearance: PaymentSheet.Appearance = PaymentSheet.Appearance(), shopPayTestingOptions: ShopPayTestingOptions = ShopPayTestingOptions()) {
        self.model = ExampleWalletButtonsModel(email: email, shopId: shopId, appearance: appearance, shopPayTestingOptions: shopPayTestingOptions)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            VStack {
                if let flowController = model.paymentSheetFlowController {
                    let isProcessing = Binding {
                        model.isProcessing
                    } set: { _ in
                        // Ignore anything set by FlowController, since `PreparePaymentMethodHandler`
                        // has a mind of its own.
                    }

                    WalletButtonsFlowControllerView(
                        flowController: flowController,
                        isProcessing: isProcessing,
                        purchase: { model.isProcessing = true },
                        onCompletion: model.onCompletion
                    )
                } else if model.paymentResult == nil {
                    ExampleLoadingView()
                } else {
                    Button("Reload", action: {
                        self.model.paymentResult = nil
                        self.model.preparePaymentSheet()
                    })
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
    @Binding var isProcessing: Bool
    let purchase: () -> Void
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
        Button(action: purchase) {
            if isProcessing {
                ExampleLoadingView()
            } else {
                ExamplePaymentButtonView()
            }
        }.paymentConfirmationSheet(
            isConfirming: $isProcessing,
            paymentSheetFlowController: flowController,
            onCompletion: onCompletion
        )
        .disabled(flowController.paymentOption == nil || isProcessing)
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
    let appearance: PaymentSheet.Appearance
    let shopPayTestingOptions: ShopPayTestingOptions

    let backendCheckoutUrl = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!
    let SPTTestCustomerUrl = URL(string: "https://2f6qwl-3000.csb.app/api/customer")!
    let SPTTestCreateIntentUrl = URL(string: "https://2f6qwl-3000.csb.app/api/create-intent")!
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isProcessing: Bool = false
    @Published var debugLogs: [String] = []

    init(email: String, shopId: String, appearance: PaymentSheet.Appearance, shopPayTestingOptions: ShopPayTestingOptions = ShopPayTestingOptions()) {
        self.email = email
        self.shopId = shopId
        self.appearance = appearance
        self.shopPayTestingOptions = shopPayTestingOptions
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
        self.addDebugLog("Using SPT test backend")
        preparePaymentSheetWithSPTTestBackend()
    }

    private func preparePaymentSheetWithSPTTestBackend() {
        // First, create customer and get customer session
        self.addDebugLog("Creating customer with SPT test backend...")
        let body = [
            "customerId": nil, // Let backend create a new customer if no email is passed
            "customerEmail": email.nonEmpty,
            "isMobile": true,
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
                configuration.appearance = self?.appearance ?? PaymentSheet.Appearance()

                self?.addDebugLog("Creating PaymentSheet FlowController...")
                PaymentSheet.FlowController.create(
                    intentConfiguration: .init(sharedPaymentTokenSessionWithMode: .payment(amount: 9999, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil), sellerDetails: .init(networkId: "stripe", externalId: "acct_1HvTI7Lu5o3P18Zp"), paymentMethodTypes: ["card", "shop_pay"], preparePaymentMethodHandler: { [weak self] paymentMethod, address in
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
                    DispatchQueue.main.async {
                        self?.isProcessing = false
                        self?.addDebugLog("Error creating payment intent: \(error?.localizedDescription ?? "Unknown error")")
                        self?.setResultAfterSPTConfirmation(error: error ?? PaymentSheetError.unknown(debugDescription: "Unknown error"))
                    }
                    return
                }

                if let stripeError = NSError.stp_error(fromStripeResponse: json) {
                    DispatchQueue.main.async {
                        self?.isProcessing = false
                        self?.addDebugLog("Error creating payment intent: \(error?.localizedDescription ?? "Unknown error")")
                        self?.setResultAfterSPTConfirmation(error: stripeError)
                    }
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
                                self?.setResultAfterSPTConfirmation(error: nil)
                            }
                        } else if status == .failed {
                            self?.addDebugLog("Payment failed after handling next action")
                            DispatchQueue.main.async {
                                self?.onCompletion(result: .failed(error: error ?? NSError(domain: "PaymentHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment failed"])))

                            }
                        } else if status == .canceled {
                            self?.addDebugLog("Payment canceled after handling next action")
                            DispatchQueue.main.async {
                                self?.onCompletion(result: .canceled)
                            }
                        }
                    }
                } else {
                    let paymentIntentID = json["paymentIntent"] as? String
                    self?.addDebugLog("Payment intent created: \(paymentIntentID)")
                    DispatchQueue.main.async {
                        self?.isProcessing = false
                        self?.setResultAfterSPTConfirmation(error: nil)
                    }
                }
            })
        task.resume()
    }

    func onCompletion(result: PaymentSheetResult) {
        self.addDebugLog("PaymentSheet completion called with result: \(result)")

        // Check if we should simulate payment failure for testing
        if shopPayTestingOptions.simulatePaymentFailed {
            self.addDebugLog("[TEST MODE] Simulating payment failure")
            self.paymentResult = .failed(error: NSError(domain: "TestMode", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated payment failure for testing"]))
            return
        }
    }

    private func setResultAfterSPTConfirmation(error: Error?) {
        DispatchQueue.main.async {
            if let error {
                self.paymentResult = .failed(error: error)
            } else {
                self.paymentResult = .completed
                self.cleanupDemo()
            }
        }
    }

    func cleanupDemo() {
        // A PaymentIntent can't be reused after a successful payment. Prepare a new one for the demo.
        self.paymentSheetFlowController = nil
    }

    var shopPayConfiguration: PaymentSheet.ShopPayConfiguration {
        let twoBusinessDays = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 2, unit: .business_day)
        let fiveBusinessDays = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .business_day)
        let sevenBusinessDays = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 7, unit: .business_day)
        let twoWeeks = PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 2, unit: .week)

        let shippingRates: [PaymentSheet.ShopPayConfiguration.ShippingRate] = [
            .init(id: "immediate", amount: 1099, displayName: "2-hour", deliveryEstimate: .unstructured("Get your item in 2 hours")),
            .init(id: "fast", amount: 500, displayName: "Expedited", deliveryEstimate: .structured(minimum: twoBusinessDays, maximum: fiveBusinessDays)),
            .init(id: "regular", amount: 200, displayName: "Standard", deliveryEstimate: .structured(minimum: nil, maximum: sevenBusinessDays)),
            .init(id: "no_rush", amount: 100, displayName: "No Rush", deliveryEstimate: .structured(minimum: twoWeeks, maximum: nil)),
            .init(id: "no_estimate", amount: 0, displayName: "Free (No estimate)", deliveryEstimate: nil),
        ]

        let handlers = PaymentSheet.ShopPayConfiguration.Handlers(
            shippingMethodUpdateHandler: { [weak self] shippingRateSelected, completion in
                // Process the selected shipping method
                // For example, you might recalculate totals based on the shipping rate
                let selectedRate = shippingRateSelected.shippingRate
                self?.addDebugLog("User selected shipping rate: \(selectedRate.displayName) with cost \(selectedRate.amount)")

                // Check if we should reject the shipping rate change for testing
                if self?.shopPayTestingOptions.rejectShippingRateChange == true {
                    self?.addDebugLog("[TEST MODE] Rejecting shipping rate change")
                    completion(nil)
                    return
                }

                // Create the update with the new line items and available shipping rates
                let update = PaymentSheet.ShopPayConfiguration.ShippingRateUpdate(
                    lineItems: [.init(name: "Golden Potato", amount: 500),
                                .init(name: "Silver Potato", amount: 345),
                                .init(name: "Tax", amount: 200),
                                .init(name: "Shipping", amount: selectedRate.amount), ],
                    shippingRates: shippingRates
                )

                // Return the update to the Shop Pay UI
                completion(update)
            },
            shippingContactUpdateHandler: { [weak self] shippingContactSelected, completion in
                // Process the selected shipping contact information
                let name = shippingContactSelected.name
                let address = shippingContactSelected.address

                self?.addDebugLog("User selected shipping to: \(name) in \(address.city), \(address.state)")

                // Check if we should reject the shipping address change for testing
                if self?.shopPayTestingOptions.rejectShippingAddressChange == true {
                    self?.addDebugLog("[TEST MODE] Rejecting shipping address change")
                    completion(nil)
                    return
                }

                // Check if we can ship to this location
                let canShipToLocation = self?.isValidShippingLocation(address) ?? false

                if canShipToLocation {
                    // Return the update with new line items and shipping rates
                    let update = PaymentSheet.ShopPayConfiguration.ShippingContactUpdate(
                        lineItems: [.init(name: "Golden Potato", amount: 500),
                                    .init(name: "Silver Potato", amount: 345),
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

        // Parse allowed shipping countries if provided
        var allowedCountries: [String] = []
        if !shopPayTestingOptions.allowedShippingCountries.isEmpty {
            allowedCountries = shopPayTestingOptions.allowedShippingCountries
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
        }

        // Create configuration with test options
        var config = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: shopPayTestingOptions.billingAddressRequired,
            emailRequired: shopPayTestingOptions.emailRequired,
            shippingAddressRequired: shopPayTestingOptions.shippingAddressRequired,
            lineItems: [.init(name: "Golden Potato", amount: 500),
                        .init(name: "Silver Potato", amount: 345),
                        .init(name: "Tax", amount: 200),
                        .init(name: "Shipping", amount: shippingRates.first!.amount), ],
            shippingRates: shippingRates,
            shopId: self.shopId,
            allowedShippingCountries: allowedCountries,
            handlers: handlers
        )

        // Log the testing configuration
        addDebugLog("[SHOP PAY CONFIG] Billing Address Required: \(shopPayTestingOptions.billingAddressRequired)")
        addDebugLog("[SHOP PAY CONFIG] Email Required: \(shopPayTestingOptions.emailRequired)")
        addDebugLog("[SHOP PAY CONFIG] Shipping Address Required: \(shopPayTestingOptions.shippingAddressRequired)")
        addDebugLog("[SHOP PAY CONFIG] Allowed Countries: \(allowedCountries.joined(separator: ", "))")
        addDebugLog("[SHOP PAY CONFIG] Reject Shipping Address: \(shopPayTestingOptions.rejectShippingAddressChange)")
        addDebugLog("[SHOP PAY CONFIG] Reject Shipping Rate: \(shopPayTestingOptions.rejectShippingRateChange)")
        addDebugLog("[SHOP PAY CONFIG] Simulate Payment Failed: \(shopPayTestingOptions.simulatePaymentFailed)")

        return config
    }
    func isValidShippingLocation(_ address: PaymentSheet.ShopPayConfiguration.PartialAddress) -> Bool {
        return address.postalCode != "91911"
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
