//
//  PaymentConfirmer+Routing.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// How the engine groups payment method types that it handles alike, for the parity harnesses and analytics review.
/// Routing doesn't use it: the engine confirms any type the session carries a `confirm` for.
enum PaymentConfirmerFamily: String, CaseIterable {
    /// `redirect_to_url` only: the web-redirect LPMs, the 5s post-return poll group, Klarna (refresh) and MoMo.
    case redirect
    /// A hosted voucher, then `requires_action` means success: OXXO, Boleto, Konbini, Multibanco.
    case voucher
    /// No next action, or nothing to do (microdeposits): SEPA Debit, Bacs, BECS, US bank account.
    case noNextAction = "no_next_action"
    /// Their own app-to-app next action: Cash App, Swish, Alipay.
    case appToApp = "app_to_app"
    /// The polling screen, optionally behind the hosted instructions: BLIK, MB WAY, Bizum, PayNow, PromptPay, Pix.
    case pollingScreen = "polling_screen"
    /// Every next action goes to STPPaymentHandler: card and Link.
    case stripeSDK = "stripe_sdk"

    /// The family of a type confirmed with `metadata`, from the entry alone.
    init(metadata: ConfirmationMetadata) {
        // `use_stripe_sdk` can come for any type, and doesn't decide its family.
        let nextActions = metadata.nextActions.filter { $0.key != "use_stripe_sdk" }
        func isRedirect(_ nextAction: ConfirmationMetadata.NextAction) -> Bool {
            if case .redirect = nextAction.presenter { return true } else { return false }
        }
        if metadata.performer == .stripePaymentHandler {
            self = .stripeSDK
        } else if nextActions.values.contains(where: { if case .pollingScreen = $0.presenter { return true } else { return false } }) {
            self = .pollingScreen
        } else if nextActions.values.contains(where: { isRedirect($0) && $0.whileRequiresAction == .succeed }) {
            // A hosted voucher: a redirect whose requires_action afterwards means the customer pays later.
            self = .voucher
        } else if !nextActions.values.contains(where: isRedirect) {
            self = .noNextAction
        } else if nextActions.contains(where: { isRedirect($0.value) && $0.key != "redirect_to_url" }) {
            // A redirect through the type's own next action, which opens its app.
            self = .appToApp
        } else {
            self = .redirect
        }
    }
}

extension PaymentSheet {
    /// The engine for this payment, or nil to confirm with STPPaymentHandler.
    ///
    /// The engine confirms a type only when the session carries a `confirm` for it: a server-driven payment method's
    /// description, or a served `payment_method_confirmations` entry. Every other type, including one whose entry didn't
    /// decode or when the session has no `mobile_session` (or none at all, as for headless Link), goes to
    /// STPPaymentHandler. So the server's flag and killswitch for those entries are also the engine's off switch.
    /// - Parameters:
    ///   - paymentMethodType: The payment method being confirmed. `.unknown` for a server-driven payment method.
    ///   - serverDrivenPaymentMethod: Its description, which wins over a served entry.
    ///   - elementsSession: The session whose served entries to use.
    @MainActor
    static func makePaymentConfirmer(
        paymentMethodType: STPPaymentMethodType,
        serverDrivenPaymentMethod: ServerDrivenPaymentMethod?,
        elementsSession: STPElementsSession?,
        intentKind: ConfirmationMetadata.IntentKind,
        paymentHandler: STPPaymentHandler
    ) -> PaymentConfirmer? {
        let metadata: ConfirmationMetadata
        let analyticsType: String
        if let serverDrivenPaymentMethod {
            metadata = serverDrivenPaymentMethod.confirmation
            analyticsType = serverDrivenPaymentMethod.type
        } else if let served = elementsSession?.paymentMethodConfirmations[paymentMethodType.identifier] {
            metadata = served
            analyticsType = paymentMethodType.identifier
        } else {
            return nil
        }
        // A type with no SetupIntent rules keeps today's path for SIs.
        if intentKind == .setupIntent && metadata.setupIntent == nil {
            return nil
        }
        return PaymentConfirmer(
            metadata: metadata,
            paymentMethodType: analyticsType,
            apiClient: paymentHandler.apiClient,
            performer: PaymentSheetNextActionPerformer(paymentHandler: paymentHandler)
        )
    }

    // MARK: - STPPaymentHandler-shaped entry points

    // These have the same shape as the STPPaymentHandler calls they replace at each confirm site, so the sites keep
    // their own completion handling (default payment method, Link logout, result mapping).

    @MainActor
    static func confirmPaymentIntent(
        using paymentHandler: STPPaymentHandler,
        params: STPPaymentIntentConfirmParams,
        paymentMethodType: STPPaymentMethodType,
        serverDrivenPaymentMethod: ServerDrivenPaymentMethod? = nil,
        elementsSession: STPElementsSession?,
        authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, elementsSession: elementsSession, intentKind: .paymentIntent, paymentHandler: paymentHandler) else {
            paymentHandler.confirmPaymentIntent(params: params, authenticationContext: authenticationContext, completion: completion)
            return
        }
        Task { @MainActor in
            let outcome = await confirmer.confirm(.paymentIntent(params), authenticationContext: authenticationContext)
            completion(outcome.result.paymentHandlerStatus, outcome.intent?.paymentIntent, outcome.result.paymentHandlerError)
        }
    }

    @MainActor
    static func confirmSetupIntent(
        using paymentHandler: STPPaymentHandler,
        params: STPSetupIntentConfirmParams,
        paymentMethodType: STPPaymentMethodType,
        serverDrivenPaymentMethod: ServerDrivenPaymentMethod? = nil,
        elementsSession: STPElementsSession?,
        authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, elementsSession: elementsSession, intentKind: .setupIntent, paymentHandler: paymentHandler) else {
            paymentHandler.confirmSetupIntent(params: params, authenticationContext: authenticationContext, completion: completion)
            return
        }
        Task { @MainActor in
            let outcome = await confirmer.confirm(.setupIntent(params), authenticationContext: authenticationContext)
            completion(outcome.result.paymentHandlerStatus, outcome.intent?.setupIntent, outcome.result.paymentHandlerError)
        }
    }

    @MainActor
    static func handleNextAction(
        using paymentHandler: STPPaymentHandler,
        for paymentIntent: STPPaymentIntent,
        paymentMethodType: STPPaymentMethodType,
        serverDrivenPaymentMethod: ServerDrivenPaymentMethod? = nil,
        elementsSession: STPElementsSession?,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, elementsSession: elementsSession, intentKind: .paymentIntent, paymentHandler: paymentHandler) else {
            paymentHandler.handleNextAction(for: paymentIntent, with: authenticationContext, returnURL: returnURL, completion: completion)
            return
        }
        Task { @MainActor in
            let outcome = await confirmer.handleNextAction(for: .paymentIntent(paymentIntent), returnURL: returnURL, authenticationContext: authenticationContext)
            completion(outcome.result.paymentHandlerStatus, outcome.intent?.paymentIntent, outcome.result.paymentHandlerError)
        }
    }

    @MainActor
    static func handleNextAction(
        using paymentHandler: STPPaymentHandler,
        for setupIntent: STPSetupIntent,
        paymentMethodType: STPPaymentMethodType,
        serverDrivenPaymentMethod: ServerDrivenPaymentMethod? = nil,
        elementsSession: STPElementsSession?,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, elementsSession: elementsSession, intentKind: .setupIntent, paymentHandler: paymentHandler) else {
            paymentHandler.handleNextAction(for: setupIntent, with: authenticationContext, returnURL: returnURL, completion: completion)
            return
        }
        Task { @MainActor in
            let outcome = await confirmer.handleNextAction(for: .setupIntent(setupIntent), returnURL: returnURL, authenticationContext: authenticationContext)
            completion(outcome.result.paymentHandlerStatus, outcome.intent?.setupIntent, outcome.result.paymentHandlerError)
        }
    }
}

extension PaymentSheetResult {
    /// The STPPaymentHandler status the confirm sites expect. `PaymentSheet.makePaymentSheetResult` maps it back.
    var paymentHandlerStatus: STPPaymentHandlerActionStatus {
        switch self {
        case .completed: return .succeeded
        case .canceled: return .canceled
        case .failed: return .failed
        }
    }

    var paymentHandlerError: NSError? {
        guard case .failed(let error) = self else { return nil }
        return error as NSError
    }
}
