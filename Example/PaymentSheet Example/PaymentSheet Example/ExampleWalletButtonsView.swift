//
//  ExampleWalletButtonsView.swift
//  PaymentSheet Example
//

@_spi(STP) @_spi(SharedPaymentToken) import StripePayments
@_spi(STP) @_spi(SharedPaymentToken) @_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
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
    @State private var disableLink = false
    @State private var hideBankTab = false

    // Wallet button visibility options
    @State private var applePayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility = .automatic
    @State private var linkVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility = .automatic
    @State private var shopPayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility = .automatic
    @State private var applePayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility = .automatic
    @State private var linkVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility = .automatic
    @State private var shopPayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility = .automatic

    // Shop Pay testing options
    @State private var billingAddressRequired: Bool = false
    @State private var emailRequired: Bool = false
    @State private var shippingAddressRequired: Bool = true
    @State private var allowedShippingCountries: String = ""
    @State private var rejectShippingAddressChange: Bool = false
    @State private var rejectShippingRateChange: Bool = false
    @State private var simulatePaymentFailed: Bool = false

    // Click handler testing options
    @State private var enableClickHandler: Bool = false
    @State private var rejectApplePay: Bool = false
    @State private var rejectLink: Bool = false
    @State private var rejectShopPay: Bool = false

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
                        .autocorrectionDisabled()

                    Toggle("Enable inline verification", isOn: $linkInlineVerificationEnabled)
                        .onChange(of: linkInlineVerificationEnabled) { newValue in
                            PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification = newValue
                        }

                    Toggle("Disable Link", isOn: $disableLink)

                    Toggle("Hide Bank tab", isOn: $hideBankTab)

                    Button("Customize Appearance") {
                        showingAppearancePlayground = true
                    }
                }

                Section("Wallet Button Visibility") {
                    Group {
                        VStack(alignment: .leading) {
                            Text("Apple Pay in PaymentElement")
                                .font(.subheadline)
                            Picker("Apple Pay PaymentElement", selection: $applePayVisibilityInPaymentElement) {
                                Text("Automatic").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.automatic)
                                Text("Always").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.always)
                                Text("Never").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.never)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        VStack(alignment: .leading) {
                            Text("Link in PaymentElement")
                                .font(.subheadline)
                            Picker("Link PaymentElement", selection: $linkVisibilityInPaymentElement) {
                                Text("Automatic").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.automatic)
                                Text("Always").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.always)
                                Text("Never").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.never)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        VStack(alignment: .leading) {
                            Text("Shop Pay in PaymentElement")
                                .font(.subheadline)
                            Picker("Shop Pay PaymentElement", selection: $shopPayVisibilityInPaymentElement) {
                                Text("Automatic").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.automatic)
                                Text("Always").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.always)
                                Text("Never").tag(PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility.never)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    Group {
                        VStack(alignment: .leading) {
                            Text("Apple Pay in WalletButtonsView")
                                .font(.subheadline)
                            Picker("Apple Pay WalletButtonsView", selection: $applePayVisibilityInWalletButtonsView) {
                                Text("Automatic").tag(PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility.automatic)
                                Text("Never").tag(PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility.never)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        VStack(alignment: .leading) {
                            Text("Link in WalletButtonsView")
                                .font(.subheadline)
                            Picker("Link WalletButtonsView", selection: $linkVisibilityInWalletButtonsView) {
                                Text("Automatic").tag(PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility.automatic)
                                Text("Never").tag(PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility.never)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        VStack(alignment: .leading) {
                            Text("Shop Pay in WalletButtonsView")
                                .font(.subheadline)
                            Picker("Shop Pay WalletButtonsView", selection: $shopPayVisibilityInWalletButtonsView) {
                                Text("Automatic").tag(PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility.automatic)
                                Text("Never").tag(PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility.never)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }

                Section("Shop Pay Testing Options") {
                    Group {
                        Toggle("Billing Address Required", isOn: $billingAddressRequired)
                        Toggle("Email Required", isOn: $emailRequired)
                        Toggle("Shipping Address Required", isOn: $shippingAddressRequired)

                        TextField("Allowed Shipping Countries (comma separated)", text: $allowedShippingCountries)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Group {
                        Toggle("Reject Shipping Address Change", isOn: $rejectShippingAddressChange)
                        Toggle("Reject Shipping Rate Change", isOn: $rejectShippingRateChange)
                        Toggle("Simulate Payment Failed", isOn: $simulatePaymentFailed)
                    }
                }

                Section("Click Handler Testing") {
                    Toggle("Enable Click Handler", isOn: $enableClickHandler)
                    if enableClickHandler {
                        Toggle("Reject Apple Pay", isOn: $rejectApplePay)
                        Toggle("Reject Link", isOn: $rejectLink)
                        Toggle("Reject Shop Pay", isOn: $rejectShopPay)
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
                            disableLink: disableLink,
                            hideBankTab: hideBankTab,
                            appearance: appearance,
                            applePayVisibilityInPaymentElement: applePayVisibilityInPaymentElement,
                            linkVisibilityInPaymentElement: linkVisibilityInPaymentElement,
                            shopPayVisibilityInPaymentElement: shopPayVisibilityInPaymentElement,
                            applePayVisibilityInWalletButtonsView: applePayVisibilityInWalletButtonsView,
                            linkVisibilityInWalletButtonsView: linkVisibilityInWalletButtonsView,
                            shopPayVisibilityInWalletButtonsView: shopPayVisibilityInWalletButtonsView,
                            shopPayTestingOptions: ShopPayTestingOptions(
                                billingAddressRequired: billingAddressRequired,
                                emailRequired: emailRequired,
                                shippingAddressRequired: shippingAddressRequired,
                                allowedShippingCountries: allowedShippingCountries,
                                rejectShippingAddressChange: rejectShippingAddressChange,
                                rejectShippingRateChange: rejectShippingRateChange,
                                simulatePaymentFailed: simulatePaymentFailed
                            ),
                            enableClickHandler: enableClickHandler,
                            rejectApplePay: rejectApplePay,
                            rejectLink: rejectLink,
                            rejectShopPay: rejectShopPay
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

    init(
        email: String,
        shopId: String,
        disableLink: Bool,
        hideBankTab: Bool,
        appearance: PaymentSheet.Appearance = PaymentSheet.Appearance(),
        applePayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility = .automatic,
        linkVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility = .automatic,
        shopPayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility = .automatic,
        applePayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility = .automatic,
        linkVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility = .automatic,
        shopPayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility = .automatic,
        shopPayTestingOptions: ShopPayTestingOptions = ShopPayTestingOptions(),
        enableClickHandler: Bool = false,
        rejectApplePay: Bool = false,
        rejectLink: Bool = false,
        rejectShopPay: Bool = false
    ) {
        self.model = ExampleWalletButtonsModel(
            email: email,
            shopId: shopId,
            disableLink: disableLink,
            hideBankTab: hideBankTab,
            appearance: appearance,
            applePayVisibilityInPaymentElement: applePayVisibilityInPaymentElement,
            linkVisibilityInPaymentElement: linkVisibilityInPaymentElement,
            shopPayVisibilityInPaymentElement: shopPayVisibilityInPaymentElement,
            applePayVisibilityInWalletButtonsView: applePayVisibilityInWalletButtonsView,
            linkVisibilityInWalletButtonsView: linkVisibilityInWalletButtonsView,
            shopPayVisibilityInWalletButtonsView: shopPayVisibilityInWalletButtonsView,
            shopPayTestingOptions: shopPayTestingOptions,
            enableClickHandler: enableClickHandler,
            rejectApplePay: rejectApplePay,
            rejectLink: rejectLink,
            rejectShopPay: rejectShopPay
        )
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            VStack {
                if let flowController = model.paymentSheetFlowController, !model.isProcessing {
                    WalletButtonsFlowControllerView(
                        flowController: flowController,
                        isConfirmingPayment: $isConfirmingPayment,
                        onCompletion: model.onCompletion,
                        enableClickHandler: model.enableClickHandler,
                        rejectApplePay: model.rejectApplePay,
                        rejectLink: model.rejectLink,
                        rejectShopPay: model.rejectShopPay
                    )
                } else if model.paymentResult == nil {
                    ExampleLoadingView()
                } else {
                    Button("Reload", action: {
                        self.model.paymentResult = nil
                        self.model.preparePaymentSheet()
                    })
                }

                Button("Simulate update") {
                    self.model.update()
                }
                .disabled(model.paymentSheetFlowController == nil || model.isProcessing)

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
    let enableClickHandler: Bool
    let rejectApplePay: Bool
    let rejectLink: Bool
    let rejectShopPay: Bool

    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        if flowController.paymentOption == nil {
            WalletButtonsView(
                flowController: flowController,
                confirmHandler: { _ in },
                clickHandler: enableClickHandler ? { walletType in
                    let shouldReject = switch walletType {
                    case "apple_pay": rejectApplePay
                    case "link": rejectLink
                    case "shop_pay": rejectShopPay
                    default: false
                    }

                    if shouldReject {
                        errorMessage = "Click rejected for \(walletType)"
                        showingError = true
                        return false
                    }
                    return true
                } : nil
            )
            .padding(.horizontal)
            .alert("Click Handler Rejected", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
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
    let disableLink: Bool
    let hideBankTab: Bool
    let appearance: PaymentSheet.Appearance
    let applePayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility
    let linkVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility
    let shopPayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility
    let applePayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility
    let linkVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility
    let shopPayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility
    let shopPayTestingOptions: ShopPayTestingOptions
    let enableClickHandler: Bool
    let rejectApplePay: Bool
    let rejectLink: Bool
    let rejectShopPay: Bool

    let backendCheckoutUrl = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!
    let SPTTestCustomerUrl = URL(string: "https://2f6qwl-3000.csb.app/api/customer")!
    let SPTTestCreateIntentUrl = URL(string: "https://2f6qwl-3000.csb.app/api/create-intent")!
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isProcessing: Bool = false
    @Published var debugLogs: [String] = []

    private var latestIntentConfig: PaymentSheet.IntentConfiguration?

    init(
        email: String,
        shopId: String,
        disableLink: Bool,
        hideBankTab: Bool,
        appearance: PaymentSheet.Appearance,
        applePayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility,
        linkVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility,
        shopPayVisibilityInPaymentElement: PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility,
        applePayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility,
        linkVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility,
        shopPayVisibilityInWalletButtonsView: PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility,
        shopPayTestingOptions: ShopPayTestingOptions = ShopPayTestingOptions(),
        enableClickHandler: Bool = false,
        rejectApplePay: Bool = false,
        rejectLink: Bool = false,
        rejectShopPay: Bool = false
    ) {
        self.email = email
        self.shopId = shopId
        self.disableLink = disableLink
        self.hideBankTab = hideBankTab
        self.appearance = appearance
        self.applePayVisibilityInPaymentElement = applePayVisibilityInPaymentElement
        self.linkVisibilityInPaymentElement = linkVisibilityInPaymentElement
        self.shopPayVisibilityInPaymentElement = shopPayVisibilityInPaymentElement
        self.applePayVisibilityInWalletButtonsView = applePayVisibilityInWalletButtonsView
        self.linkVisibilityInWalletButtonsView = linkVisibilityInWalletButtonsView
        self.shopPayVisibilityInWalletButtonsView = shopPayVisibilityInWalletButtonsView
        self.shopPayTestingOptions = shopPayTestingOptions
        self.enableClickHandler = enableClickHandler
        self.rejectApplePay = rejectApplePay
        self.rejectLink = rejectLink
        self.rejectShopPay = rejectShopPay
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

    func update() {
        guard let paymentSheetFlowController, let latestIntentConfig else {
            return
        }

        addDebugLog("Updating FlowController…")

        paymentSheetFlowController.update(intentConfiguration: latestIntentConfig) { [weak self] _ in
            self?.addDebugLog("Updating FlowController complete")
        }
    }

    private func preparePaymentSheetWithSPTTestBackend() {
        // First, create customer and get customer session
        self.addDebugLog("Creating customer with SPT test backend...")
        let body = [
            "customerId": nil,
            "customerEmail": email.nonEmpty ?? "test-\(UUID().uuidString)@stripe.com",
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
                guard let self else {
                    return
                }
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let customerId = json["customerId"] as? String,
                    let customerSessionClientSecret = json["customerSessionClientSecret"] as? String
                else {
                    self.addDebugLog("Error creating customer: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self.addDebugLog("Customer created successfully: \(customerId)")

                // MARK: Set your Stripe publishable key for rough-lying-carriage backend
                // Using test publishable key - in production, this should come from the backend
                STPAPIClient.shared.publishableKey = "pk_test_51LsBpsAoVfWZ5CNZi82L5ALZB9C89AyblMIWBHERPJRvSTaLYjaTsjT7hMeVRuXzTIc9VkkiZQ59KqXqVxYL7Rn600Homq7UPk"

                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Rough Lying Carriage, Inc."
                configuration.applePay = .init(
                    merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
                    merchantCountryCode: "US",
                    customHandlers: .init(paymentRequestHandler: { paymentRequest in
                        paymentRequest.requiredShippingContactFields = [.postalAddress, .emailAddress]
                        return paymentRequest
                    })
                )
                configuration.shopPay = self.shopPayConfiguration
                configuration.customer = .init(id: customerId, customerSessionClientSecret: customerSessionClientSecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                configuration.willUseWalletButtonsView = true
                configuration.appearance = self.appearance ?? PaymentSheet.Appearance()

                var linkConfiguration = PaymentSheet.LinkConfiguration()
                linkConfiguration.display = self.disableLink == true ? .never : .automatic
                linkConfiguration.disallowFundingSourceCreation = self.hideBankTab ? ["usInstantBankPayment"] : []
                configuration.link = linkConfiguration

                // Configure wallet button visibility
                configuration.walletButtonsVisibility.paymentElement[.applePay] = self.applePayVisibilityInPaymentElement
                configuration.walletButtonsVisibility.paymentElement[.link] = self.linkVisibilityInPaymentElement
                configuration.walletButtonsVisibility.paymentElement[.shopPay] = self.shopPayVisibilityInPaymentElement
                configuration.walletButtonsVisibility.walletButtonsView[.applePay] = self.applePayVisibilityInWalletButtonsView
                configuration.walletButtonsVisibility.walletButtonsView[.link] = self.linkVisibilityInWalletButtonsView
                configuration.walletButtonsVisibility.walletButtonsView[.shopPay] = self.shopPayVisibilityInWalletButtonsView

                self.latestIntentConfig = .init(sharedPaymentTokenSessionWithMode: .payment(amount: 9999, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil), sellerDetails: .init(networkId: "stripe", externalId: "acct_1HvTI7Lu5o3P18Zp", businessName: "Till's Pills"), paymentMethodTypes: ["card", "shop_pay"], preparePaymentMethodHandler: { [weak self] paymentMethod, address in
                    self?.isProcessing = true
                    self?.addDebugLog("PaymentMethod prepared: \(paymentMethod.stripeId)")
                    self?.addDebugLog("Address: \(address)")
                    // Create the payment intent on the rough-lying-carriage backend
                    self?.createPaymentIntentWithSPTTestBackend(customerId: customerId, paymentMethod: paymentMethod.stripeId)
                })

                self.addDebugLog("Creating PaymentSheet FlowController...")
                PaymentSheet.FlowController.create(
                    intentConfiguration: latestIntentConfig!,
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
                                self?.onCompletion(result: .completed)
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
                        self?.onCompletion(result: .completed)
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
                    shippingRates: shippingRates + [.init(id: "newAmount", amount: 100, displayName: "newAmount", deliveryEstimate: nil)]
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
                        shippingRates: shippingRates + [.init(id: "newAmount", amount: 100, displayName: "newAmount", deliveryEstimate: nil)]
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
                        .init(name: "Shipping", amount: shippingRates.first?.amount ?? 0), ],
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
