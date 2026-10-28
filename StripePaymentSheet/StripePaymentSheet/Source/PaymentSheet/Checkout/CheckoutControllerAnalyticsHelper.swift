//
//  CheckoutControllerAnalyticsHelper.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

@MainActor
final class CheckoutControllerAnalyticsHelper {
    /// Who initiated the action. For example, a merchant calling `updateShippingAddress`
    /// uses `.merchant`, while saving an address in ShippingAddressElement uses `.shippingAddressElement`.
    enum InvocationSource: String {
        case merchant
        case paymentElement = "payment_element"
        case expressCheckoutElement = "express_checkout_element"
        case shippingAddressElement = "shipping_address_element"
    }

    /// Checkout actions with started and succeeded/failed events (plus canceled for confirmation).
    /// Includes public API calls and element-driven work, such as Payment Element updating billing tax.
    enum CheckoutAction {
        case initialize, confirm, applyPromotionCode, removePromotionCode
        case updateEmail, updateShippingAddress, updateBillingAddress, updateCurrency, runServerUpdate

        fileprivate var startedEvent: STPAnalyticEvent {
            switch self {
            case .initialize:
                return .checkoutElementsInitStarted
            case .confirm:
                return .checkoutElementsConfirmStarted
            case .applyPromotionCode:
                return .checkoutElementsApplyPromotionCodeStarted
            case .removePromotionCode:
                return .checkoutElementsRemovePromotionCodeStarted
            case .updateEmail:
                return .checkoutElementsUpdateEmailStarted
            case .updateShippingAddress:
                return .checkoutElementsUpdateShippingAddressStarted
            case .updateBillingAddress:
                return .checkoutElementsUpdateBillingAddressStarted
            case .updateCurrency:
                return .checkoutElementsUpdateCurrencyStarted
            case .runServerUpdate:
                return .checkoutElementsRunServerUpdateStarted
            }
        }

        fileprivate var succeededEvent: STPAnalyticEvent {
            switch self {
            case .initialize:
                return .checkoutElementsInitSucceeded
            case .confirm:
                return .checkoutElementsConfirmSucceeded
            case .applyPromotionCode:
                return .checkoutElementsApplyPromotionCodeSucceeded
            case .removePromotionCode:
                return .checkoutElementsRemovePromotionCodeSucceeded
            case .updateEmail:
                return .checkoutElementsUpdateEmailSucceeded
            case .updateShippingAddress:
                return .checkoutElementsUpdateShippingAddressSucceeded
            case .updateBillingAddress:
                return .checkoutElementsUpdateBillingAddressSucceeded
            case .updateCurrency:
                return .checkoutElementsUpdateCurrencySucceeded
            case .runServerUpdate:
                return .checkoutElementsRunServerUpdateSucceeded
            }
        }

        fileprivate var failedEvent: STPAnalyticEvent {
            switch self {
            case .initialize:
                return .checkoutElementsInitFailed
            case .confirm:
                return .checkoutElementsConfirmFailed
            case .applyPromotionCode:
                return .checkoutElementsApplyPromotionCodeFailed
            case .removePromotionCode:
                return .checkoutElementsRemovePromotionCodeFailed
            case .updateEmail:
                return .checkoutElementsUpdateEmailFailed
            case .updateShippingAddress:
                return .checkoutElementsUpdateShippingAddressFailed
            case .updateBillingAddress:
                return .checkoutElementsUpdateBillingAddressFailed
            case .updateCurrency:
                return .checkoutElementsUpdateCurrencyFailed
            case .runServerUpdate:
                return .checkoutElementsRunServerUpdateFailed
            }
        }
    }

    /// One invocation that has started, with its monotonic start time for measuring elapsed duration.
    /// Each invocation has its own value, including overlapping calls for the same action.
    struct CheckoutActionWithStartTime {
        fileprivate let action: CheckoutAction
        fileprivate let startTime: TimeInterval
    }

    private let apiClient: STPAPIClient
    private let checkoutSessionId: String
    private let analyticsClient: STPAnalyticsClientProtocol

    init(
        apiClient: STPAPIClient,
        checkoutSessionId: String,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) {
        self.apiClient = apiClient
        self.checkoutSessionId = checkoutSessionId
        self.analyticsClient = analyticsClient
    }

    func logStarted(
        _ action: CheckoutAction,
        session: CheckoutController.Session? = nil,
        additionalParams: [String: Any] = [:]
    ) -> CheckoutActionWithStartTime {
        let startedAction = CheckoutActionWithStartTime(action: action, startTime: ProcessInfo.processInfo.systemUptime)
        log(event: action.startedEvent, session: session, additionalParams: additionalParams)
        return startedAction
    }

    func logSucceeded(
        _ startedAction: CheckoutActionWithStartTime,
        session: CheckoutController.Session? = nil,
        additionalParams: [String: Any] = [:]
    ) {
        log(event: startedAction.action.succeededEvent, session: session, startedAction: startedAction, additionalParams: additionalParams)
    }

    func logFailed(
        _ startedAction: CheckoutActionWithStartTime,
        error: Error,
        session: CheckoutController.Session? = nil,
        additionalParams: [String: Any] = [:]
    ) {
        var params = additionalParams
        let analyticsError = (error as? CheckoutError)?.analyticsError ?? error
        params.merge(analyticsError.serializeForV1Analytics()) { _, errorValue in errorValue }
        log(event: startedAction.action.failedEvent, session: session, startedAction: startedAction, additionalParams: params)
    }

    func logCanceled(
        _ startedAction: CheckoutActionWithStartTime,
        session: CheckoutController.Session? = nil,
        additionalParams: [String: Any] = [:]
    ) {
        stpAssert(startedAction.action == .confirm, "Only confirmation has a canceled action event.")
        log(event: .checkoutElementsConfirmCanceled, session: session, startedAction: startedAction, additionalParams: additionalParams)
    }

    func logAddressUpdateFinished(
        _ startedAction: CheckoutActionWithStartTime,
        session: CheckoutController.Session,
        source: InvocationSource,
        didRequestTaxUpdate: Bool,
        error: Error?
    ) {
        let params: [String: Any] = [
            "invocation_source": source.rawValue,
            "did_request_tax_update": didRequestTaxUpdate,
        ]
        if let error {
            logFailed(startedAction, error: error, session: session, additionalParams: params)
        } else {
            logSucceeded(startedAction, session: session, additionalParams: params)
        }
    }

    func logClearPaymentOption(session: CheckoutController.Session) {
        log(event: .checkoutElementsClearPaymentOption, session: session)
    }

    /// Logs started and succeeded/failed around the body, preserving any thrown error.
    func track(
        _ action: CheckoutAction,
        checkout: CheckoutController,
        additionalParams: [String: Any] = [:],
        body: () async throws -> Void
    ) async rethrows {
        let startedAction = logStarted(action, session: checkout.session, additionalParams: additionalParams)
        do {
            try await body()
            logSucceeded(startedAction, session: checkout.session, additionalParams: additionalParams)
        } catch {
            logFailed(startedAction, error: error, session: checkout.session, additionalParams: additionalParams)
            throw error
        }
    }

    private func log(
        event: STPAnalyticEvent,
        session: CheckoutController.Session?,
        startedAction: CheckoutActionWithStartTime? = nil,
        additionalParams: [String: Any] = [:]
    ) {
        var params: [String: Any] = [:]
        let sessionId = session?.id ?? checkoutSessionId
        if !sessionId.isEmpty {
            params["checkout_session_id"] = sessionId
        }
        if let session {
            params["checkout_config_id"] = session.checkoutConfigID
            params["currency"] = session.currency
            params["elements_session_config_id"] = session.elementsSession.configID
            params["adaptive_pricing_active"] = session.adaptivePricingActive
            params["automatic_tax_enabled"] = session.automaticTaxEnabled
            switch session.status {
            case .open:
                params["session_status"] = "open"
            case .expired:
                params["session_status"] = "expired"
            case .complete:
                params["session_status"] = "complete"
            }
            switch session.paymentStatus {
            case .paid:
                params["payment_status"] = "paid"
            case .unpaid:
                params["payment_status"] = "unpaid"
            case .noPaymentRequired:
                params["payment_status"] = "no_payment_required"
            }
        }
        if let startedAction {
            params["duration"] = ProcessInfo.processInfo.systemUptime - startedAction.startTime
        }
        params.mergeAssertingOnOverwrites(additionalParams)
        analyticsClient.log(
            analytic: PaymentSheetAnalytic(event: event, additionalParams: params),
            apiClient: apiClient
        )
    }
}
