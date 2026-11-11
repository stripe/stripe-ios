//
//  PaymentConfirmer+Routing.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// The payment method families PaymentSheet can confirm with `PaymentConfirmer`, in migration order. Each is routed only
/// once the parity harness shows the engine matches STPPaymentHandler for it, apart from deliberate, documented
/// differences (`PaymentConfirmerParityTests`).
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

    static func family(of type: STPPaymentMethodType) -> PaymentConfirmerFamily? {
        guard let metadata = ConfirmationMetadata.native(for: type) else {
            return nil
        }
        if metadata.performer == .stripePaymentHandler {
            return .stripeSDK
        }
        let presenters = metadata.nextActions.values.map(\.presenter)
        if presenters.contains(where: { if case .pollingScreen = $0 { return true } else { return false } }) {
            return .pollingScreen
        }
        if [.cashApp, .swish, .alipay].contains(type) {
            return .appToApp
        }
        // A hosted voucher: a redirect whose requires_action afterwards means the customer pays later.
        if metadata.nextActions.values.contains(where: { nextAction in
            if case .redirect = nextAction.presenter, nextAction.whileRequiresAction == .succeed { return true } else { return false }
        }) {
            return .voucher
        }
        if [.SEPADebit, .bacsDebit, .AUBECSDebit, .USBankAccount].contains(type) {
            return .noNextAction
        }
        return .redirect
    }

    var types: [STPPaymentMethodType] {
        return ConfirmationMetadata.nativeTypes.filter { Self.family(of: $0) == self }
    }
}

extension PaymentConfirmer {
    /// The families PaymentSheet confirms with the engine. Server-driven payment methods always use it. Prototype: a
    /// static allowlist; a shipping version would also need a server kill switch per type.
    static var routedFamilies: Set<PaymentConfirmerFamily> = [.redirect]

    static func isRouted(_ type: STPPaymentMethodType) -> Bool {
        return PaymentConfirmerFamily.family(of: type).map(routedFamilies.contains) ?? false
    }
}

extension PaymentSheet {
    /// The engine for this payment, or nil to confirm with STPPaymentHandler.
    /// - Parameters:
    ///   - paymentMethodType: The payment method being confirmed. `.unknown` for a server-driven payment method.
    ///   - serverDrivenPaymentMethod: Its server spec, which wins over the default table.
    @MainActor
    static func makePaymentConfirmer(
        paymentMethodType: STPPaymentMethodType,
        serverDrivenPaymentMethod: ServerDrivenPaymentMethod?,
        intentKind: ConfirmationMetadata.IntentKind,
        paymentHandler: STPPaymentHandler
    ) -> PaymentConfirmer? {
        let metadata: ConfirmationMetadata
        let policySource: PaymentConfirmer.PolicySource
        let analyticsType: String
        if let serverDrivenPaymentMethod {
            metadata = ConfirmationMetadata(serverSpec: serverDrivenPaymentMethod.confirmSpec, paymentMethodDataType: serverDrivenPaymentMethod.type)
            policySource = .server
            analyticsType = serverDrivenPaymentMethod.type
        } else if PaymentConfirmer.isRouted(paymentMethodType), let native = ConfirmationMetadata.native(for: paymentMethodType) {
            metadata = native
            policySource = .defaultTable
            analyticsType = paymentMethodType.identifier
        } else {
            return nil
        }
        // A type with no SetupIntent rules (server-driven PMs are PaymentIntent-only in v1) keeps today's path for SIs.
        if intentKind == .setupIntent && metadata.setupIntent == nil {
            return nil
        }
        return PaymentConfirmer(
            metadata: metadata,
            policySource: policySource,
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
        authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, intentKind: .paymentIntent, paymentHandler: paymentHandler) else {
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
        authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, intentKind: .setupIntent, paymentHandler: paymentHandler) else {
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
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, intentKind: .paymentIntent, paymentHandler: paymentHandler) else {
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
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        guard let confirmer = makePaymentConfirmer(paymentMethodType: paymentMethodType, serverDrivenPaymentMethod: serverDrivenPaymentMethod, intentKind: .setupIntent, paymentHandler: paymentHandler) else {
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
