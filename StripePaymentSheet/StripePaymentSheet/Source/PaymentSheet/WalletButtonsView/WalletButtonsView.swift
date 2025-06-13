//
//  WalletButtonsView.swift
//  StripePaymentSheet
//

import PassKit
import SwiftUI
import WebKit

@available(iOS 16.0, *)
@_spi(STP) public struct WalletButtonsView: View {
    enum ExpressType: Hashable {
        case applePay
        case link
        case linkInlineVerification(PaymentSheetLinkAccount)
        case shopPay
    }

    let flowController: PaymentSheet.FlowController
    let confirmHandler: (PaymentSheetResult) -> Void
    @State var orderedWallets: [ExpressType]

    @_spi(STP) public init(flowController: PaymentSheet.FlowController,
                           confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        self.confirmHandler = confirmHandler
        self.flowController = flowController

        let wallets = WalletButtonsView.determineAvailableWallets(for: flowController)
        self._orderedWallets = State(initialValue: wallets + [.shopPay])
    }

    init(flowController: PaymentSheet.FlowController,
         confirmHandler: @escaping (PaymentSheetResult) -> Void,
         orderedWallets: [ExpressType]) {
        self.flowController = flowController
        self.confirmHandler = confirmHandler
        self._orderedWallets = State(initialValue: orderedWallets + [.shopPay])
    }

    @_spi(STP) public var body: some View {
        if !orderedWallets.isEmpty {
            VStack(spacing: 8) {
                ForEach(orderedWallets, id: \.self) { wallet in
                    let completion: () -> Void = {
                        Task {
                            checkoutTapped(wallet)
                        }
                    }

                    switch wallet {
                    case .applePay:
                        ApplePayButton(action: completion)
                    case .link:
                        LinkButton(action: completion)
                    case .linkInlineVerification(let account):
                        LinkInlineVerificationView(
                            account: account,
                            appearance: flowController.configuration.appearance,
                            onComplete: completion
                        )
                    case .shopPay:
                        ShopPayButton {
                            Task {
                                checkoutTapped(.shopPay)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut, value: orderedWallets)
            .onAppear {
                flowController.walletButtonsShownExternally = true
            }
            .onDisappear {
                flowController.walletButtonsShownExternally = false
            }
        }
    }

    private static func determineAvailableWallets(for flowController: PaymentSheet.FlowController) -> [ExpressType] {
        // Determine available wallets and their order from elementsSession
        var wallets: [ExpressType] = []
        for type in flowController.elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "link":
                // Also check PaymentSheet local availability logic
                if PaymentSheet.isLinkEnabled(
                    elementsSession: flowController.elementsSession,
                    configuration: flowController.configuration
                ) {
                    let canUseLinkInlineVerification: Bool = {
                        let featureFlagEnabled = PaymentSheet.LinkFeatureFlags.enableLinkInlineVerification
                        let canUseNativeLink = deviceCanUseNativeLink(
                            elementsSession: flowController.elementsSession,
                            configuration: flowController.configuration
                        )
                        return featureFlagEnabled && canUseNativeLink
                    }()

                    if canUseLinkInlineVerification,
                       let linkAccount = LinkAccountContext.shared.account,
                       linkAccount.sessionState == .requiresVerification {
                        wallets.append(.linkInlineVerification(linkAccount))
                    } else {
                        wallets.append(.link)
                    }
                }
            case "apple_pay":
                if PaymentSheet.isApplePayEnabled(elementsSession: flowController.elementsSession, configuration: flowController.configuration) {
                    wallets.append(.applePay)
                }
            case "shop_pay":
                wallets.append(.shopPay)
            default:
                continue
            }
        }
        return wallets
    }

    func checkoutTapped(_ expressType: ExpressType) {
        switch expressType {
        case .applePay:
            // Launch directly into Apple Pay and confirm the payment
            PaymentSheet.confirm(
                configuration: flowController.configuration,
                authenticationContext: WindowAuthenticationContext(),
                intent: flowController.intent,
                elementsSession: flowController.elementsSession,
                paymentOption: .applePay,
                paymentHandler: flowController.paymentHandler,
                analyticsHelper: flowController.analyticsHelper
            ) { result, _ in
                confirmHandler(result)
            }
        case .link, .linkInlineVerification:
            let linkController = PayWithNativeLinkController(
                mode: .paymentMethodSelection,
                intent: flowController.intent,
                elementsSession: flowController.elementsSession,
                configuration: flowController.configuration,
                analyticsHelper: flowController.analyticsHelper
            )
            linkController.presentForPaymentMethodSelection(
                from: WindowAuthenticationContext().authenticationPresentingViewController(),
                initiallySelectedPaymentDetailsID: nil,
                shouldShowSecondaryCta: false,
                completion: { confirmOptions, _ in
                    guard let confirmOptions else {
                        self.orderedWallets = WalletButtonsView.determineAvailableWallets(for: flowController)
                        return
                    }
                    flowController.viewController.linkConfirmOption = confirmOptions
                    flowController.updatePaymentOption()
                }
            )
        case .shopPay:
            guard let shopPayConfig = flowController.configuration.shopPay else {
                // Shop Pay configuration is required
                let error = PaymentSheetError.integrationError(nonPIIDebugDescription: "Shop Pay configuration is missing")
                confirmHandler(.failed(error: error))
                return
            }
            
            // Present Shop Pay via ECE WebView
            let shopPayPresenter = ShopPayECEPresenter(
                flowController: flowController,
                configuration: shopPayConfig,
                confirmHandler: confirmHandler
            )
            shopPayPresenter.present(from: WindowAuthenticationContext().authenticationPresentingViewController())
        }
    }

    private struct ApplePayButton: View {
        let action: () -> Void

        var body: some View {
            PayWithApplePayButton(.plain, action: action)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .cornerRadius(100)
        }
    }
}

private class WindowAuthenticationContext: NSObject, STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        UIWindow.visibleViewController ?? UIViewController()
    }
}

extension PaymentSheetLinkAccount: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct WalletButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        WalletButtonsView(
            flowController: PaymentSheet.FlowController._mockFlowController(),
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

fileprivate extension PaymentSheet.FlowController {
    static func _mockFlowController() -> PaymentSheet.FlowController {
        let psConfig = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession(allResponseFields: [:], sessionID: "", orderedPaymentMethodTypes: [], orderedPaymentMethodTypesAndWallets: ["card", "link", "apple_pay"], unactivatedPaymentMethodTypes: [], countryCode: nil, merchantCountryCode: nil, linkSettings: nil, experimentsData: nil, flags: [:], paymentMethodSpecs: nil, cardBrandChoice: nil, isApplePayEnabled: true, externalPaymentMethods: [], customPaymentMethods: [], customer: nil)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        return PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)
    }
}
#endif

// MARK: - ShopPayECEPresenter
/// Handles presenting Shop Pay via the ECE WebView
@available(iOS 16.0, *)
private class ShopPayECEPresenter: NSObject {
    private let flowController: PaymentSheet.FlowController
    private let shopPayConfiguration: PaymentSheet.ShopPayConfiguration
    private let confirmHandler: (PaymentSheetResult) -> Void
    private var eceViewController: ECEViewController?
    private weak var presentingViewController: UIViewController?
    
    init(
        flowController: PaymentSheet.FlowController,
        configuration: PaymentSheet.ShopPayConfiguration,
        confirmHandler: @escaping (PaymentSheetResult) -> Void
    ) {
        self.flowController = flowController
        self.shopPayConfiguration = configuration
        self.confirmHandler = confirmHandler
        super.init()
    }
    
    func present(from viewController: UIViewController) {
        self.presentingViewController = viewController
        
         // Create ECE view controller
         let eceVC = ECEViewController()
         eceVC.expressCheckoutWebviewDelegate = self
         self.eceViewController = eceVC
        
         // Configure ECE for Shop Pay
         configureECEForShopPay(eceVC)
        
         // Present as a navigation controller
         let navController = UINavigationController(rootViewController: eceVC)
         navController.modalPresentationStyle = .pageSheet
         viewController.present(navController, animated: true)
    }
    
     private func configureECEForShopPay(_ eceViewController: ECEViewController) {
         // Configure the ECE view controller with Shop Pay specific settings
         // This will be handled by the ECE WebView when it loads
     }
    
    private func dismissECE(completion: (() -> Void)? = nil) {
        presentingViewController?.dismiss(animated: true, completion: completion)
    }
    
    private func mockShopPaySuccess() {
        // Mock a successful payment
        confirmHandler(.completed)
    }
}

// MARK: - ExpressCheckoutWebviewDelegate
@available(iOS 16.0, *)
extension ShopPayECEPresenter: ExpressCheckoutWebviewDelegate {
    
    func webView(_ webView: WKWebView, didReceiveShippingAddressChange shippingAddress: [String: Any]) async throws -> [String: Any] {
        // Convert the webview shipping address to our format
        guard let name = shippingAddress["firstName"] as? String,
              let city = shippingAddress["city"] as? String,
              let state = shippingAddress["provinceCode"] as? String,
              let postalCode = shippingAddress["postalCode"] as? String,
              let country = shippingAddress["countryCode"] as? String else {
            throw ExpressCheckoutError.missingRequiredField(field: "shipping address")
        }
        
        let selectedAddress = PaymentSheet.ShopPayConfiguration.PartialAddress(
            city: city,
            state: state,
            postalCode: postalCode,
            country: country
        )
        
        let selectedContact = PaymentSheet.ShopPayConfiguration.ShippingContactSelected(
            name: name,
            address: selectedAddress
        )
        
        // Call the merchant's handler if available
        if let handler = shopPayConfiguration.handlers?.shippingContactUpdateHandler {
            return await withCheckedContinuation { continuation in
                handler(selectedContact) { update in
                    if let update = update {
                        // Convert update to webview format
                        let response: [String: Any] = [
                            "merchantDecision": "accepted",
                            "lineItems": update.lineItems.map { ["name": $0.name, "amount": $0.amount] },
                            "shippingRates": update.shippingRates.map { rate in
                                var rateDict: [String: Any] = [
                                    "id": rate.id,
                                    "displayName": rate.displayName,
                                    "amount": rate.amount
                                ]
                                if let deliveryEstimate = rate.deliveryEstimate {
                                    rateDict["deliveryEstimate"] = self.formatDeliveryEstimate(deliveryEstimate)
                                }
                                return rateDict
                            },
                            "totalAmount": self.calculateTotal(lineItems: update.lineItems, shippingRates: update.shippingRates)
                        ]
                        continuation.resume(returning: response)
                    } else {
                        // Merchant rejected the address
                        continuation.resume(returning: [
                            "merchantDecision": "rejected",
                            "error": "Cannot ship to this address"
                        ])
                    }
                }
            }
        } else {
            // No handler, accept with default values
            return [
                "merchantDecision": "accepted",
                "lineItems": shopPayConfiguration.lineItems.map { ["name": $0.name, "amount": $0.amount] },
                "shippingRates": shopPayConfiguration.shippingRates.map { rate in
                    var rateDict: [String: Any] = [
                        "id": rate.id,
                        "displayName": rate.displayName,
                        "amount": rate.amount
                    ]
                    if let deliveryEstimate = rate.deliveryEstimate {
                        rateDict["deliveryEstimate"] = formatDeliveryEstimate(deliveryEstimate)
                    }
                    return rateDict
                },
                "totalAmount": calculateTotal(lineItems: shopPayConfiguration.lineItems, shippingRates: shopPayConfiguration.shippingRates)
            ]
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveShippingRateChange shippingRate: [String: Any]) async throws -> [String: Any] {
        guard let rateId = shippingRate["id"] as? String,
              let selectedRate = shopPayConfiguration.shippingRates.first(where: { $0.id == rateId }) else {
            throw ExpressCheckoutError.invalidShippingRate(rateId: shippingRate["id"] as? String ?? "unknown")
        }
        
        let rateSelected = PaymentSheet.ShopPayConfiguration.ShippingRateSelected(
            shippingRate: selectedRate
        )
        
        // Call the merchant's handler if available
        if let handler = shopPayConfiguration.handlers?.shippingMethodUpdateHandler {
            return await withCheckedContinuation { continuation in
                handler(rateSelected) { update in
                    if let update = update {
                        // Convert update to webview format
                        let response: [String: Any] = [
                            "merchantDecision": "accepted",
                            "lineItems": update.lineItems.map { ["name": $0.name, "amount": $0.amount] },
                            "shippingRates": update.shippingRates.map { rate in
                                var rateDict: [String: Any] = [
                                    "id": rate.id,
                                    "displayName": rate.displayName,
                                    "amount": rate.amount
                                ]
                                if let deliveryEstimate = rate.deliveryEstimate {
                                    rateDict["deliveryEstimate"] = self.formatDeliveryEstimate(deliveryEstimate)
                                }
                                return rateDict
                            },
                            "totalAmount": self.calculateTotal(lineItems: update.lineItems, selectedShippingRate: selectedRate)
                        ]
                        continuation.resume(returning: response)
                    } else {
                        // Merchant rejected the rate
                        continuation.resume(returning: [
                            "merchantDecision": "rejected",
                            "error": "Invalid shipping rate"
                        ])
                    }
                }
            }
        } else {
            // No handler, return current configuration with updated total
            return [
                "merchantDecision": "accepted",
                "lineItems": shopPayConfiguration.lineItems.map { ["name": $0.name, "amount": $0.amount] },
                "shippingRates": shopPayConfiguration.shippingRates.map { rate in
                    var rateDict: [String: Any] = [
                        "id": rate.id,
                        "displayName": rate.displayName,
                        "amount": rate.amount
                    ]
                    if let deliveryEstimate = rate.deliveryEstimate {
                        rateDict["deliveryEstimate"] = formatDeliveryEstimate(deliveryEstimate)
                    }
                    return rateDict
                },
                "totalAmount": calculateTotal(lineItems: shopPayConfiguration.lineItems, selectedShippingRate: selectedRate)
            ]
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveECEClick event: [String: Any]) async throws -> [String: Any] {
        // Handle ECE click event for Shop Pay
        guard let walletType = event["walletType"] as? String,
              walletType == "shop_pay" else {
            throw ExpressCheckoutError.missingRequiredField(field: "walletType")
        }
        
        // Build the configuration for Shop Pay
        var config: [String: Any] = [
            "lineItems": shopPayConfiguration.lineItems.map { ["name": $0.name, "amount": $0.amount] },
            "billingAddressRequired": shopPayConfiguration.billingAddressRequired,
            "emailRequired": shopPayConfiguration.emailRequired,
            "phoneNumberRequired": true, // Shop Pay always requires phone
            "shippingAddressRequired": shopPayConfiguration.shippingAddressRequired,
            "business": ["name": flowController.configuration.merchantDisplayName],
            "shopId": shopPayConfiguration.shopId
        ]
        
        // Add shipping rates if shipping is required
        if shopPayConfiguration.shippingAddressRequired {
            config["shippingRates"] = shopPayConfiguration.shippingRates.map { rate in
                var rateDict: [String: Any] = [
                    "id": rate.id,
                    "displayName": rate.displayName,
                    "amount": rate.amount
                ]
                if let deliveryEstimate = rate.deliveryEstimate {
                    rateDict["deliveryEstimate"] = formatDeliveryEstimate(deliveryEstimate)
                }
                return rateDict
            }
        }
        
        return config
    }
    
    func webView(_ webView: WKWebView, didReceiveECEConfirmation paymentDetails: [String: Any]) async throws -> [String: Any] {
        // Extract payment details
        guard let billingDetails = paymentDetails["billingDetails"] as? [String: Any] else {
            throw ExpressCheckoutError.missingRequiredField(field: "billingDetails")
        }
        
        // Create Shop Pay payment method params
        let paymentMethodParams = STPPaymentMethodParams()
        paymentMethodParams.type = .unknown
        paymentMethodParams.billingDetails = STPPaymentMethodBillingDetails()
        
        // Add billing details
        if let email = billingDetails["email"] as? String {
            paymentMethodParams.billingDetails?.email = email
        }
        if let phone = billingDetails["phone"] as? String {
            paymentMethodParams.billingDetails?.phone = phone
        }
        if let name = billingDetails["name"] as? String {
            paymentMethodParams.billingDetails?.name = name
        }
        
        // Create payment option
        let confirmParams = IntentConfirmParams(type: .stripe(.unknown))
        confirmParams.paymentMethodParams.billingDetails = paymentMethodParams.billingDetails
        let paymentOption = PaymentOption.new(confirmParams: confirmParams)
        
        // Dismiss ECE and confirm payment
        dismissECE { [weak self] in
            guard let self = self else { return }
            
            // Confirm the payment through PaymentSheet
            PaymentSheet.confirm(
                configuration: self.flowController.configuration,
                authenticationContext: WindowAuthenticationContext(),
                intent: self.flowController.intent,
                elementsSession: self.flowController.elementsSession,
                paymentOption: paymentOption,
                paymentHandler: self.flowController.paymentHandler,
                analyticsHelper: self.flowController.analyticsHelper
            ) { result, _ in
                self.confirmHandler(result)
            }
        }
        
        // Return success response to webview
        return [
            "status": "success",
            "requiresAction": false
        ]
    }
    
    // MARK: - Helper Functions
    
    private func formatDeliveryEstimate(_ estimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate) -> String {
        let minUnit = formatTimeUnit(estimate.minimum)
        let maxUnit = formatTimeUnit(estimate.maximum)
        
        if estimate.minimum.value == estimate.maximum.value && estimate.minimum.unit == estimate.maximum.unit {
            return minUnit
        } else {
            return "\(minUnit) - \(maxUnit)"
        }
    }
    
    private func formatTimeUnit(_ unit: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit) -> String {
        let value = unit.value
        let unitString: String
        
        switch unit.unit {
        case .hour:
            unitString = value == 1 ? "Hour" : "Hours"
        case .day:
            unitString = value == 1 ? "Day" : "Days"
        case .business_day:
            unitString = value == 1 ? "Business Day" : "Business Days"
        case .week:
            unitString = value == 1 ? "Week" : "Weeks"
        case .month:
            unitString = value == 1 ? "Month" : "Months"
        }
        
        return "\(value) \(unitString)"
    }
    
    private func calculateTotal(lineItems: [PaymentSheet.ShopPayConfiguration.LineItem], shippingRates: [PaymentSheet.ShopPayConfiguration.ShippingRate]) -> Int {
        let itemsTotal = lineItems.reduce(0) { $0 + $1.amount }
        let defaultShippingAmount = shippingRates.first?.amount ?? 0
        return itemsTotal + defaultShippingAmount
    }
    
    private func calculateTotal(lineItems: [PaymentSheet.ShopPayConfiguration.LineItem], selectedShippingRate: PaymentSheet.ShopPayConfiguration.ShippingRate) -> Int {
        let itemsTotal = lineItems.reduce(0) { $0 + $1.amount }
        return itemsTotal + selectedShippingRate.amount
    }
}
