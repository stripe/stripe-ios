//
//  ShopPayECEPresenter.swift
//  StripePaymentSheet
//

import Foundation
import WebKit

// MARK: - ShopPayECEPresenter
/// Handles presenting Shop Pay via the ECE WebView
@available(iOS 16.0, *)
private class ShopPayECEPresenter: NSObject {
    private let flowController: PaymentSheet.FlowController
    private let shopPayConfiguration: PaymentSheet.ShopPayConfiguration
    private var confirmHandler: ((PaymentSheetResult) -> Void)?
    private var eceViewController: ECEViewController?
    private weak var presentingViewController: UIViewController?

    init(
        flowController: PaymentSheet.FlowController,
        configuration: PaymentSheet.ShopPayConfiguration
    ) {
        self.flowController = flowController
        self.shopPayConfiguration = configuration
        super.init()
    }

    func present(from viewController: UIViewController,
    confirmHandler: @escaping (PaymentSheetResult) -> Void) {
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
        // retain self while presented
        self.confirmHandler = { result in
            confirmHandler(result)
            self.confirmHandler = nil
        }
    }

     private func configureECEForShopPay(_ eceViewController: ECEViewController) {
         // Configure the ECE view controller with Shop Pay specific settings
         // This will be handled by the ECE WebView when it loads
     }

    private func dismissECE(completion: (() -> Void)? = nil) {
        presentingViewController?.dismiss(animated: true, completion: completion)
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
                                    "amount": rate.amount,
                                ]
                                if let deliveryEstimate = rate.deliveryEstimate {
                                    rateDict["deliveryEstimate"] = self.formatDeliveryEstimate(deliveryEstimate)
                                }
                                return rateDict
                            },
                            "totalAmount": self.calculateTotal(lineItems: update.lineItems, shippingRates: update.shippingRates),
                        ]
                        continuation.resume(returning: response)
                    } else {
                        // Merchant rejected the address
                        continuation.resume(returning: [
                            "merchantDecision": "rejected",
                            "error": "Cannot ship to this address",
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
                        "amount": rate.amount,
                    ]
                    if let deliveryEstimate = rate.deliveryEstimate {
                        rateDict["deliveryEstimate"] = formatDeliveryEstimate(deliveryEstimate)
                    }
                    return rateDict
                },
                "totalAmount": calculateTotal(lineItems: shopPayConfiguration.lineItems, shippingRates: shopPayConfiguration.shippingRates),
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
                                    "amount": rate.amount,
                                ]
                                if let deliveryEstimate = rate.deliveryEstimate {
                                    rateDict["deliveryEstimate"] = self.formatDeliveryEstimate(deliveryEstimate)
                                }
                                return rateDict
                            },
                            "totalAmount": self.calculateTotal(lineItems: update.lineItems, selectedShippingRate: selectedRate),
                        ]
                        continuation.resume(returning: response)
                    } else {
                        // Merchant rejected the rate
                        continuation.resume(returning: [
                            "merchantDecision": "rejected",
                            "error": "Invalid shipping rate",
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
                        "amount": rate.amount,
                    ]
                    if let deliveryEstimate = rate.deliveryEstimate {
                        rateDict["deliveryEstimate"] = formatDeliveryEstimate(deliveryEstimate)
                    }
                    return rateDict
                },
                "totalAmount": calculateTotal(lineItems: shopPayConfiguration.lineItems, selectedShippingRate: selectedRate),
            ]
        }
    }

    func webView(_ webView: WKWebView, didReceiveECEClick event: [String: Any]) async throws -> [String: Any] {
        // Build the configuration for Shop Pay
        var config: [String: Any] = [
            "lineItems": shopPayConfiguration.lineItems.map { ["name": $0.name, "amount": $0.amount] },
            "billingAddressRequired": shopPayConfiguration.billingAddressRequired,
            "emailRequired": shopPayConfiguration.emailRequired,
            "phoneNumberRequired": true, // Shop Pay always requires phone
            "shippingAddressRequired": shopPayConfiguration.shippingAddressRequired,
            "business": ["name": flowController.configuration.merchantDisplayName],
            "allowedShippingCountries": shopPayConfiguration.allowedShippingCountries,
            "shopId": shopPayConfiguration.shopId,
        ]

        // Add shipping rates if shipping is required
        if shopPayConfiguration.shippingAddressRequired {
            config["shippingRates"] = shopPayConfiguration.shippingRates.map { rate in
                var rateDict: [String: Any] = [
                    "id": rate.id,
                    "displayName": rate.displayName,
                    "amount": rate.amount,
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
                self.confirmHandler?(result)
            }
        }

        // Return success response to webview
        return [
            "status": "success",
            "requiresAction": false,
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
