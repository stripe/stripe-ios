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
    private var didReceiveECEClick: Bool = false
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private var currentShippingRates: [PaymentSheet.ShopPayConfiguration.ShippingRate]

    init(
        flowController: PaymentSheet.FlowController,
        configuration: PaymentSheet.ShopPayConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.flowController = flowController
        self.shopPayConfiguration = configuration
        self.analyticsHelper = analyticsHelper
        self.currentShippingRates = configuration.shippingRates
        super.init()
    }

    func present(from viewController: UIViewController,
                 confirmHandler: @escaping (PaymentSheetResult) -> Void) {
        guard case .customerSession(let customerSessionClientSecret) = flowController.configuration.customer?.customerAccessProvider else {
            stpAssertionFailure("Integration Error: CustomerSessions is required")
            return
        }
        self.presentingViewController = viewController
        analyticsHelper.logShopPayWebviewLoadAttempt()

        let eceVC = ECEViewController(apiClient: flowController.configuration.apiClient,
                                      shopId: shopPayConfiguration.shopId,
                                      customerSessionClientSecret: customerSessionClientSecret,
                                      delegate: self)

        eceVC.expressCheckoutWebviewDelegate = self
        self.eceViewController = eceVC

        let transitionDelegate = FixedHeightTransitionDelegate(heightRatio: 0.85)
        eceVC.transitioningDelegate = transitionDelegate
        eceVC.modalPresentationStyle = .custom
        eceVC.view.layer.cornerRadius = self.flowController.configuration.appearance.sheetCornerRadius
        eceVC.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        eceVC.view.clipsToBounds = true
        viewController.present(eceVC, animated: true)
        eceVC.presentationController?.delegate = self
        // retain self while presented
        self.confirmHandler = { result in
            confirmHandler(result)
            self.confirmHandler = nil
        }
    }

    // If the sheet is pulled down
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        analyticsHelper.logShopPayWebviewCancelled(didReceiveECEClick: didReceiveECEClick)
        self.eceViewController?.unloadWebview()
        self.eceViewController = nil
        self.confirmHandler?(.canceled)
    }

    private func dismissECE(completion: (() -> Void)? = nil) {
        presentingViewController?.dismiss(animated: true) {
            self.eceViewController?.unloadWebview()
            self.eceViewController = nil
            completion?()
        }
    }
}

@available(iOS 16.0, *)
extension ShopPayECEPresenter: ECEViewControllerDelegate {
    func didCancel() {
        analyticsHelper.logShopPayWebviewCancelled(didReceiveECEClick: didReceiveECEClick)
        self.confirmHandler?(.canceled)
        dismissECE()
    }
}

// MARK: - ExpressCheckoutWebviewDelegate
@available(iOS 16.0, *)
extension ShopPayECEPresenter: ExpressCheckoutWebviewDelegate {
    func amountForECEView(_ eceView: ECEViewController) -> Int {
        return shopPayConfiguration.lineItems.reduce(0) { $0 + $1.amount }
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
                        // Update our current shipping rates
                        self.currentShippingRates = update.shippingRates

                        // Create typed response
                        let response = ECEShippingUpdateResponse(
                            lineItems: update.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
                            shippingRates: update.shippingRates.map { rate in
                                ECEShippingRate(
                                    id: rate.id,
                                    amount: rate.amount,
                                    displayName: rate.displayName,
                                    deliveryEstimate: self.convertDeliveryEstimate(rate.deliveryEstimate)
                                )
                            },
                            applePay: nil,
                            totalAmount: self.calculateTotal(lineItems: update.lineItems)
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
                shippingRates: currentShippingRates.map { rate in
                    ECEShippingRate(
                        id: rate.id,
                        amount: rate.amount,
                        displayName: rate.displayName,
                        deliveryEstimate: self.convertDeliveryEstimate(rate.deliveryEstimate)
                    )
                },
                applePay: nil,
                totalAmount: calculateTotal(lineItems: shopPayConfiguration.lineItems)
            )

            return try ECEBridgeTypes.encode(response)
        }
    }

    func eceView(_ eceView: ECEViewController, didReceiveShippingRateChange shippingRate: [String: Any]) async throws -> [String: Any] {
        // Decode the shipping rate
        let selectedRate = try ECEBridgeTypes.decode(ECEShippingRate.self, from: shippingRate)

        guard let matchingRate = currentShippingRates.first(where: { $0.id == selectedRate.id }) else {
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
                        // Update our current shipping rates
                        self.currentShippingRates = update.shippingRates

                        // Create typed response
                        let response = ECEShippingUpdateResponse(
                            lineItems: update.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
                            shippingRates: update.shippingRates.map { rate in
                                ECEShippingRate(
                                    id: rate.id,
                                    amount: rate.amount,
                                    displayName: rate.displayName,
                                    deliveryEstimate: self.convertDeliveryEstimate(rate.deliveryEstimate)
                                )
                            },
                            applePay: nil,
                            totalAmount: self.calculateTotal(lineItems: update.lineItems)
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
                shippingRates: currentShippingRates.map { rate in
                    ECEShippingRate(
                        id: rate.id,
                        amount: rate.amount,
                        displayName: rate.displayName,
                        deliveryEstimate: self.convertDeliveryEstimate(rate.deliveryEstimate)
                    )
                },
                applePay: nil,
                totalAmount: calculateTotal(lineItems: shopPayConfiguration.lineItems)
            )

            return try ECEBridgeTypes.encode(response)
        }
    }

    func eceView(_ eceView: ECEViewController, didReceiveECEClick event: [String: Any]) async throws -> [String: Any] {
        didReceiveECEClick = true
        // Build the configuration for Shop Pay
        let clickConfig = ECEClickConfiguration(
            lineItems: shopPayConfiguration.lineItems.map { ECELineItem(name: $0.name, amount: $0.amount) },
            shippingRates: shopPayConfiguration.shippingAddressRequired ? currentShippingRates.map { rate in
                ECEShippingRate(
                    id: rate.id,
                    amount: rate.amount,
                    displayName: rate.displayName,
                    deliveryEstimate: self.convertDeliveryEstimate(rate.deliveryEstimate)
                )
            } : nil,
            applePay: nil
        )

        // Convert to dictionary and add Shop Pay specific fields
        var response = try ECEBridgeTypes.encode(clickConfig)

        let businessName = flowController.intent.sellerDetails?.businessName ?? flowController.configuration.merchantDisplayName

        // Add Shop Pay specific configuration
        response["billingAddressRequired"] = shopPayConfiguration.billingAddressRequired
        response["emailRequired"] = shopPayConfiguration.emailRequired
        response["phoneNumberRequired"] = true // Shop Pay always requires phone
        response["shippingAddressRequired"] = shopPayConfiguration.shippingAddressRequired
        response["business"] = ["name": businessName]
        response["allowedShippingCountries"] = shopPayConfiguration.allowedShippingCountries
        response["shopId"] = shopPayConfiguration.shopId

        return response
    }

    func eceView(_ eceView: ECEViewController, didReceiveECEConfirmation paymentDetails: [String: Any]) async throws -> [String: Any] {
        // Decode the confirmation data
        let confirmData = try ECEBridgeTypes.decode(ECEConfirmEventData.self, from: paymentDetails)

        guard let billingDetails = confirmData.billingDetails else {
            let error = ExpressCheckoutError.missingRequiredField(field: "billingDetails")
            dismissECE { [weak self] in
                guard let self = self else { return }
                self.confirmHandler?(.failed(error: error))
            }
            throw error
        }
        guard let externalSourceId = confirmData.paymentMethodOptions?.shopPay?.externalSourceId else {
            let error = ExpressCheckoutError.missingRequiredField(field: "externalSourceId")
            dismissECE { [weak self] in
                guard let self = self else { return }
                self.confirmHandler?(.failed(error: error))
            }
            throw error
        }

        // Create Shop Pay payment method params
        let shopPayParams = STPPaymentMethodShopPayParams()
        shopPayParams.externalSourceId = externalSourceId
        let paymentMethodParams = STPPaymentMethodParams(shopPay: shopPayParams,
                                                         billingDetails: STPPaymentMethodBillingDetails(),
                                                         metadata: nil)

        // Add billing details
        paymentMethodParams.billingDetails?.email = billingDetails.email
        paymentMethodParams.billingDetails?.phone = billingDetails.phone
        paymentMethodParams.billingDetails?.name = billingDetails.name
        paymentMethodParams.billingDetails?.address = billingDetails.address?.stpPaymentMethodAddress

        // Create payment method
        do {
            let paymentMethod = try await flowController.configuration.apiClient.createPaymentMethod(with: paymentMethodParams)
            // Dismiss ECE and return the payment method ID on the main thread
            Task { @MainActor in
                dismissECE { [weak self] in
                    guard let self = self else { return }

                    guard case .deferredIntent(let intentConfig) = self.flowController.intent else  {
                        stpAssertionFailure("Integration Error: Shop Pay ECE flow requires a deferred intent.")
                        return
                    }
                    // Call the intent config confirm handler first
                    guard let preparePaymentMethodHandler = intentConfig.preparePaymentMethodHandler else {
                        stpAssertionFailure("Integration Error: Shop Pay ECE flow requires a preparePaymentMethodHandler")
                        return
                    }

                    // Try to create a radar session for the payment method before calling the handler
                    flowController.configuration.apiClient.createSavedPaymentMethodRadarSession(paymentMethodId: paymentMethod.stripeId) { _, error in
                        // If radar session creation fails, just continue with the payment method directly
                        if let error {
                            // Log the error but don't fail the payment
                            let errorAnalytic = ErrorAnalytic(event: .savedPaymentMethodRadarSessionFailure, error: error)
                            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: self.flowController.configuration.apiClient)
                        }

                        // Call the handler regardless of radar session success/failure
                        preparePaymentMethodHandler(paymentMethod, confirmData.shippingAddress?.toSTPAddress())

                        // Log successful completion
                        self.analyticsHelper.logShopPayWebviewConfirmSuccess()
                        // And then the PaymentSheet presentation handler
                        self.confirmHandler?(.completed)
                    }
                }
            }
        } catch {
            dismissECE { [weak self] in
                guard let self = self else { return }
                self.confirmHandler?(.failed(error: error))
            }
            throw error
        }

        // Return success response to webview
        return [
            "status": "success",
            "requiresAction": false,
        ]
    }

    // MARK: - Helper Functions

    private func convertDeliveryEstimate(_ estimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate?) -> ECEDeliveryEstimate? {
        guard let estimate else {
            return nil
        }
        switch estimate {
        case .unstructured(let deliveryEstimateString):
            return ECEDeliveryEstimate.string(deliveryEstimateString)
        case .structured(let minimum, let maximum):
            var minimumEstimate: ECEDeliveryEstimateUnit?
            if let minimum {
                minimumEstimate = ECEDeliveryEstimateUnit(unit: convertDeliveryUnit(minimum.unit), value: minimum.value)
            }
            var maximumEstimate: ECEDeliveryEstimateUnit?
            if let maximum {
                maximumEstimate = ECEDeliveryEstimateUnit(unit: convertDeliveryUnit(maximum.unit), value: maximum.value)
            }
            return .structured(ECEStructuredDeliveryEstimate(maximum: maximumEstimate, minimum: minimumEstimate))
        }
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

    private func calculateTotal(lineItems: [PaymentSheet.ShopPayConfiguration.LineItem]) -> Int {
        return lineItems.reduce(0) { $0 + $1.amount }
    }
}
