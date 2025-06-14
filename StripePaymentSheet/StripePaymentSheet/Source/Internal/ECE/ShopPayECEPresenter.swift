//
//  ShopPayECEPresenter.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import WebKit

// MARK: - ShopPayECEPresenter
/// Handles presenting Shop Pay via the ECE WebView
@available(iOS 16.0, *)
class ShopPayECEPresenter: NSObject, UIAdaptivePresentationControllerDelegate {
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

        let eceVC = ECEViewController(apiClient: flowController.configuration.apiClient)
         eceVC.expressCheckoutWebviewDelegate = self
         self.eceViewController = eceVC
        let navController = UINavigationController(rootViewController: eceVC)
         navController.modalPresentationStyle = .pageSheet
         viewController.present(navController, animated: true)
        eceVC.presentationController?.delegate = self
        // retain self while presented
        self.confirmHandler = { result in
            confirmHandler(result)
            self.confirmHandler = nil
        }
    }

    // If the sheet is pulled down
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.confirmHandler?(.canceled)
    }

    private func dismissECE(completion: (() -> Void)? = nil) {
        presentingViewController?.dismiss(animated: true, completion: completion)
    }
}

// MARK: - ExpressCheckoutWebviewDelegate
@available(iOS 16.0, *)
extension ShopPayECEPresenter: ExpressCheckoutWebviewDelegate {
    func amountForECEView(_ eceView: ECEViewController) -> Int {
        let itemsTotal = shopPayConfiguration.lineItems.reduce(0) { $0 + $1.amount }
        // add default shipping amount if available
        let defaultShippingAmount = shopPayConfiguration.shippingRates.first?.amount ?? 0
        return itemsTotal + defaultShippingAmount
    }

    func eceView(_ eceView: ECEViewController, didReceiveShippingAddressChange shippingAddress: [String: Any]) async throws -> [String: Any] {
        // Decode the shipping address using typed struct
        let event = try ECEBridgeTypes.decode(ECEShippingAddressChangeEvent.self, from: shippingAddress)

        // Extract address components
        let address = event.address

        let selectedAddress = PaymentSheet.ShopPayConfiguration.PartialAddress(
            city: address.city ?? "",
            state: address.state ?? "",
            postalCode: address.postalCode ?? "",
            country: address.country ?? ""
        )

        let selectedContact = PaymentSheet.ShopPayConfiguration.ShippingContactSelected(
            name: event.name ?? "",
            address: selectedAddress
        )

        // Call the merchant's handler if available
        if let handler = shopPayConfiguration.handlers?.shippingContactUpdateHandler {
            return try await withCheckedThrowingContinuation { continuation in
                handler(selectedContact) { update in
                    if let update = update {
                        // Create typed response
                        let response = ECEShippingUpdateResponse(
                            lineItems: update.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
                            shippingRates: update.shippingRates.map { rate in
                                ECEShippingRate(
                                    id: rate.id,
                                    amount: rate.amount,
                                    displayName: rate.displayName,
                                    deliveryEstimate: rate.deliveryEstimate.map { self.convertDeliveryEstimate($0) }
                                )
                            },
                            applePay: nil,
                            totalAmount: self.calculateTotal(lineItems: update.lineItems, shippingRates: update.shippingRates)
                        )

                        // Convert to dictionary for JavaScript
                        do {
                            let responseDict = try ECEBridgeTypes.encode(response)
                            continuation.resume(returning: responseDict)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        // Merchant rejected the address
                        continuation.resume(returning: [
                            "error": "Cannot ship to this address"
                        ])
                    }
                }
            }
        } else {
            // No handler, accept with default values
            let response = ECEShippingUpdateResponse(
                lineItems: shopPayConfiguration.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
                shippingRates: shopPayConfiguration.shippingRates.map { rate in
                    ECEShippingRate(
                        id: rate.id,
                        amount: rate.amount,
                        displayName: rate.displayName,
                        deliveryEstimate: rate.deliveryEstimate.map { convertDeliveryEstimate($0) }
                    )
                },
                applePay: nil,
                totalAmount: calculateTotal(lineItems: shopPayConfiguration.lineItems, shippingRates: shopPayConfiguration.shippingRates)
            )

            return try ECEBridgeTypes.encode(response)
        }
    }

    func eceView(_ eceView: ECEViewController, didReceiveShippingRateChange shippingRate: [String: Any]) async throws -> [String: Any] {
        // Decode the shipping rate
        let selectedRate = try ECEBridgeTypes.decode(ECEShippingRate.self, from: shippingRate)

        guard let matchingRate = shopPayConfiguration.shippingRates.first(where: { $0.id == selectedRate.id }) else {
            throw ExpressCheckoutError.invalidShippingRate(rateId: selectedRate.id)
        }

        let rateSelected = PaymentSheet.ShopPayConfiguration.ShippingRateSelected(
            shippingRate: matchingRate
        )

        // Call the merchant's handler if available
        if let handler = shopPayConfiguration.handlers?.shippingMethodUpdateHandler {
            return await withCheckedContinuation { continuation in
                handler(rateSelected) { update in
                    if let update = update {
                        // Create typed response
                        let response = ECEShippingUpdateResponse(
                            lineItems: update.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
                            shippingRates: update.shippingRates.map { rate in
                                ECEShippingRate(
                                    id: rate.id,
                                    amount: rate.amount,
                                    displayName: rate.displayName,
                                    deliveryEstimate: rate.deliveryEstimate.map { self.convertDeliveryEstimate($0) }
                                )
                            },
                            applePay: nil,
                            totalAmount: self.calculateTotal(lineItems: update.lineItems, selectedShippingRate: matchingRate)
                        )

                        // Convert to dictionary for JavaScript
                        do {
                            let responseDict = try ECEBridgeTypes.encode(response)
                            continuation.resume(returning: responseDict)
                        } catch {
                            continuation.resume(returning: ["error": error.localizedDescription])
                        }
                    } else {
                        // Merchant rejected the rate
                        continuation.resume(returning: [
                            "error": "Invalid shipping rate"
                        ])
                    }
                }
            }
        } else {
            // No handler, return current configuration
            let response = ECEShippingUpdateResponse(
                lineItems: shopPayConfiguration.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
                shippingRates: shopPayConfiguration.shippingRates.map { rate in
                    ECEShippingRate(
                        id: rate.id,
                        amount: rate.amount,
                        displayName: rate.displayName,
                        deliveryEstimate: rate.deliveryEstimate.map { convertDeliveryEstimate($0) }
                    )
                },
                applePay: nil,
                totalAmount: calculateTotal(lineItems: shopPayConfiguration.lineItems, selectedShippingRate: matchingRate)
            )

            return try ECEBridgeTypes.encode(response)
        }
    }

    func eceView(_ eceView: ECEViewController, didReceiveECEClick event: [String: Any]) async throws -> [String: Any] {
        // Build the configuration for Shop Pay
        let clickConfig = ECEClickConfiguration(
            lineItems: shopPayConfiguration.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
            shippingRates: shopPayConfiguration.shippingAddressRequired ? shopPayConfiguration.shippingRates.map { rate in
                ECEShippingRate(
                    id: rate.id,
                    amount: rate.amount,
                    displayName: rate.displayName,
                    deliveryEstimate: rate.deliveryEstimate.map { convertDeliveryEstimate($0) }
                )
            } : nil,
            applePay: nil
        )

        // Convert to dictionary and add Shop Pay specific fields
        var response = try ECEBridgeTypes.encode(clickConfig)

        // Add Shop Pay specific configuration
        response["billingAddressRequired"] = shopPayConfiguration.billingAddressRequired
        response["emailRequired"] = shopPayConfiguration.emailRequired
        response["phoneNumberRequired"] = true // Shop Pay always requires phone
        response["shippingAddressRequired"] = shopPayConfiguration.shippingAddressRequired
        response["business"] = ["name": flowController.configuration.merchantDisplayName]
        response["allowedShippingCountries"] = shopPayConfiguration.allowedShippingCountries
        response["shopId"] = shopPayConfiguration.shopId

        return response
    }

    func eceView(_ eceView: ECEViewController, didReceiveECEConfirmation paymentDetails: [String: Any]) async throws -> [String: Any] {
        // Decode the confirmation data
        let confirmData = try ECEBridgeTypes.decode(ECEConfirmEventData.self, from: paymentDetails)

        guard let billingDetails = confirmData.billingDetails else {
            throw ExpressCheckoutError.missingRequiredField(field: "billingDetails")
        }

        // Create Shop Pay payment method params
        let paymentMethodParams = STPPaymentMethodParams()
        paymentMethodParams.type = .unknown
        paymentMethodParams.billingDetails = STPPaymentMethodBillingDetails()

        // Add billing details
        if let email = billingDetails.email {
            paymentMethodParams.billingDetails?.email = email
        }
        if let phone = billingDetails.phone {
            paymentMethodParams.billingDetails?.phone = phone
        }
        if let name = billingDetails.name {
            paymentMethodParams.billingDetails?.name = name
        }

        // Create payment option
        let confirmParams = IntentConfirmParams(type: .stripe(.unknown))
        confirmParams.paymentMethodParams.billingDetails = paymentMethodParams.billingDetails

        // TODO: Create a payment method here from the data (using STPAPIClient) once the API is available
        // For now, use a mock STPPaymentMethod instead
        let paymentMethod = STPPaymentMethod(stripeId: "pm_123abc", type: .unknown)

        // Dismiss ECE and return the payment method ID on the main thread
        Task { @MainActor in

            dismissECE { [weak self] in
                guard let self = self else { return }

                guard case .deferredIntent(let intentConfig) = self.flowController.intent else  {
                    stpAssertionFailure("Integration Error: Shop Pay ECE flow requires a deferred intent.")
                    return
                }
                // TODO: Replace this to use the new facilitatedPaymentSession confirmation handler when ready
                // Call the intent config confirm handler first
                intentConfig.confirmHandler(paymentMethod, false, { _ in })
                // And then the PaymentSheet presentation handler
                self.confirmHandler?(.completed)
            }
        }

        // Return success response to webview
        return [
            "status": "success",
            "requiresAction": false,
        ]
    }

    // MARK: - Helper Functions

    private func convertDeliveryEstimate(_ estimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate) -> ECEDeliveryEstimate {
        // Convert to structured format
        let structured = ECEStructuredDeliveryEstimate(
            maximum: ECEDeliveryEstimateUnit(
                unit: convertDeliveryUnit(estimate.maximum.unit),
                value: estimate.maximum.value
            ),
            minimum: ECEDeliveryEstimateUnit(
                unit: convertDeliveryUnit(estimate.minimum.unit),
                value: estimate.minimum.value
            )
        )
        return .structured(structured)
    }

    private func convertDeliveryUnit(_ unit: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit.TimeUnit) -> ECEDeliveryEstimateUnit.DeliveryTimeUnit {
        switch unit {
        case .hour:
            return .hour
        case .day:
            return .day
        case .business_day:
            return .businessDay
        case .week:
            return .week
        case .month:
            return .month
        }
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
