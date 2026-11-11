//
//  ConfirmationMetadata+Native.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

/// The default table: one `ConfirmationMetadata` per payment method type PaymentSheet confirms, derived from today's
/// per-type rules. Each rule cites where it comes from. `ConfirmationMetadataParityTests` compares this table with
/// what STPPaymentHandler actually does.
extension ConfirmationMetadata {
    typealias NativeType = STPPaymentMethodType

    /// Every type PaymentSheet confirms through STPPaymentHandler: `PaymentSheet.supportedPaymentMethods` plus Link.
    static var nativeTypes: [NativeType] {
        return PaymentSheet.supportedPaymentMethods + [.link]
    }

    /// The native policy for `type`, or nil if PaymentSheet doesn't confirm it.
    static func native(for type: NativeType) -> ConfirmationMetadata? {
        guard nativeTypes.contains(type) else {
            return nil
        }
        var nextActions: [String: NextAction] = ["redirect_to_url": .redirectToURL]
        for (key, value) in specificNextActions(for: type) {
            nextActions[key] = value
        }
        return ConfirmationMetadata(
            params: params(for: type),
            nextActions: nextActions,
            paymentIntent: paymentIntentRules(for: type),
            setupIntent: supportsSetup(type) ? setupIntentRules(for: type) : nil,
            retrieval: refreshingTypes.contains(type) ? .refresh : .retrieve,
            beforeFetch: type == .alipay ? .loadAlipayMarlinReturnURL : nil,
            onCancel: [.card, .link].contains(type) ? .cancel3DSSource : .none,
            performer: [.card, .link].contains(type) ? .stripePaymentHandler : .engine
        )
    }

    /// The policy PaymentSheet confirms with: the server's spec if it sent one, otherwise the native table.
    /// The server wins cleanly: a server spec replaces the whole native policy, so a type never runs half server
    /// rules and half native rules. Fields the contract doesn't have take the contract's defaults, not the native ones.
    static func resolved(for type: NativeType, serverSpec: ServerDrivenConfirmSpec?, paymentMethodDataType: String? = nil) -> ConfirmationMetadata? {
        if let serverSpec {
            return ConfirmationMetadata(serverSpec: serverSpec, paymentMethodDataType: paymentMethodDataType ?? type.identifier)
        }
        return native(for: type)
    }

    // MARK: - Status rules

    /// `processing` counts as success for these, because funds take days to move.
    /// STPPaymentHandler.swift:820 `_isProcessingIntentSuccess`.
    static let processingIsSuccessTypes: Set<NativeType> = [.momo, .SEPADebit, .bacsDebit, .AUBECSDebit, .USBankAccount, .card]

    /// After a next action, a `requires_action` intent is read again for this long before canceling.
    /// PollingBudget.swift:43 `init?(startDate:paymentMethodType:)`. Card's 15s is only for `use_stripe_sdk`
    /// (STPPaymentHandler.swift:1701), so it's on card's next action instead.
    static let requiresActionPollSeconds: [NativeType: Int] = [
        .amazonPay: 5, .revolutPay: 5, .swish: 5, .twint: 5, .przelewy24: 5, .payPay: 5, .link: 5,
    ]

    /// After a next action, a `processing` intent that isn't success is read again for this long, then fails.
    /// STPPaymentHandler.swift:1664 and :1761.
    static let processingPollSeconds = 30

    /// STPPaymentMethodEnums.swift:435 `supportsRefreshing`.
    static let refreshingTypes: Set<NativeType> = [.cashApp, .klarna]

    static func paymentIntentRules(for type: NativeType) -> IntentRules {
        let processingIsSuccess = processingIsSuccessTypes.contains(type)
        var rules = IntentRules(
            // STPPaymentHandler.swift:1098 `_handlePaymentIntentStatus`.
            afterConfirm: StatusRules(
                processing: processingIsSuccess ? .succeed : .fail,
                requiresAction: .performNextAction
            ),
            // STPPaymentHandler.swift:1658-1723.
            afterNextAction: StatusRules(
                processing: processingIsSuccess ? .succeed : .poll(seconds: processingPollSeconds, onTimeout: .fail),
                requiresAction: requiresActionPollSeconds[type].map { .poll(seconds: $0, onTimeout: .cancel) } ?? .cancel
            ),
            afterWebViewDismissed: nil
        )
        if type == .card {
            // A card payment approved in a web view the customer then closed can race the read, so keep reading a
            // `processing` intent; it still succeeds when the time runs out. STPPaymentHandler.swift:1660.
            rules.afterWebViewDismissed = StatusRules(
                processing: .poll(seconds: processingPollSeconds, onTimeout: .succeed),
                requiresAction: rules.afterNextAction.requiresAction
            )
        }
        return rules
    }

    static func setupIntentRules(for type: NativeType) -> IntentRules {
        let processingIsSuccess = processingIsSuccessTypes.contains(type)
        var rules = IntentRules(
            // A `processing` SetupIntent always fails. STPPaymentHandler.swift:1026 `_handleSetupIntentStatus`.
            afterConfirm: StatusRules(processing: .fail, requiresAction: .performNextAction),
            // STPPaymentHandler.swift:1756-1809. The polling still fails at the end (:1026).
            afterNextAction: StatusRules(
                processing: processingIsSuccess ? .fail : .poll(seconds: processingPollSeconds, onTimeout: .fail),
                requiresAction: requiresActionPollSeconds[type].map { .poll(seconds: $0, onTimeout: .cancel) } ?? .cancel
            ),
            afterWebViewDismissed: nil
        )
        if type == .card {
            rules.afterWebViewDismissed = StatusRules(
                processing: .poll(seconds: processingPollSeconds, onTimeout: .fail),
                requiresAction: rules.afterNextAction.requiresAction
            )
        }
        return rules
    }

    // MARK: - Next actions

    static func specificNextActions(for type: NativeType) -> [String: NextAction] {
        typealias PollingScreen = NextAction.PollingScreen
        switch type {
        case .card, .link:
            // Card 3DS2. Only `use_stripe_sdk` keeps being read after the challenge (STPPaymentHandler.swift:1701);
            // Link reads any next action for 5s (PollingBudget.swift:46).
            let pollSeconds = type == .card ? 15 : nil
            let threeDS2 = NextAction(
                presenter: .threeDS2,
                urlPath: nil,
                fallbackURLPath: nil,
                returnURL: .confirmIfSet,
                appToApp: .none,
                whileRequiresAction: pollSeconds.map { .poll(seconds: $0, onTimeout: .cancel) }
            )
            return ["use_stripe_sdk": threeDS2]
        case .alipay:
            // STPPaymentHandler.swift:1169.
            return ["alipay_handle_redirect": NextAction(presenter: .redirect(browser: .safariViewController), urlPath: "native_url", fallbackURLPath: "url", returnURL: .confirmThenNextAction, appToApp: .nativeURLThenWeb, whileRequiresAction: nil)]
        case .cashApp:
            // STPPaymentHandler.swift:1454.
            return ["cashapp_handle_redirect_or_display_qr_code": NextAction(presenter: .redirect(browser: .safariViewController), urlPath: "mobile_auth_url", fallbackURLPath: nil, returnURL: .confirmRequired, appToApp: .universalLinksOnly, whileRequiresAction: nil)]
        case .swish:
            // STPPaymentHandler.swift:1534.
            return ["swish_handle_redirect_or_display_qr_code": NextAction(presenter: .redirect(browser: .safariViewController), urlPath: "mobile_auth_url", fallbackURLPath: nil, returnURL: .confirmRequired, appToApp: .universalLinksOnly, whileRequiresAction: nil)]
        case .OXXO:
            return ["oxxo_display_details": .voucher]
        case .boleto:
            return ["boleto_display_details": .voucher]
        case .konbini:
            return ["konbini_display_details": .voucher]
        case .multibanco:
            return ["multibanco_display_details": .voucher]
        case .USBankAccount:
            // STPPaymentHandler.swift:1450: the customer verifies microdeposits later.
            return ["verify_with_microdeposits": NextAction(presenter: .none, urlPath: nil, fallbackURLPath: nil, returnURL: .none, appToApp: .none, whileRequiresAction: .succeed)]
        case .blik:
            return ["blik_authorize": .pollingScreen(PollingScreen(seconds: 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, instructions: .blik))]
        case .mbWay:
            return ["mb_way_await_authorization": .pollingScreen(PollingScreen(seconds: 4 * 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, instructions: .mbWay))]
        case .bizum:
            return ["await_authorization": .pollingScreen(PollingScreen(seconds: 70 * 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, instructions: .bizum))]
        case .paynow:
            return ["paynow_display_qr_code": .qrCodeWithPollingScreen(PollingScreen(seconds: 60 * 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, instructions: .paynow), returnURL: .confirmRequired, whileRequiresAction: .waitForNextActionScreen)]
        case .promptPay:
            return ["promptpay_display_qr_code": .qrCodeWithPollingScreen(PollingScreen(seconds: 60 * 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, instructions: .paynow), returnURL: .confirmRequired, whileRequiresAction: .waitForNextActionScreen)]
        case .pix:
            // Like PayNow and PromptPay, the polling screen finishes the payment. STPPaymentHandler differs: closing Pix's
            // web view cancels the payment while the polling screen is still up, then drops the screen's later success
            // (STPPaymentHandler.swift:1708 only exempts PayNow and PromptPay; reproduced in task #62). Fixed here on purpose.
            return ["pix_display_qr_code": .qrCodeWithPollingScreen(PollingScreen(seconds: 24 * 60 * 60, intervalSeconds: 2, showsCountdown: false, deadlineField: "expires_at", instructions: .pix), returnURL: .confirmIfSet, whileRequiresAction: .waitForNextActionScreen)]
        default:
            return [:]
        }
    }

    // MARK: - Params

    /// `PaymentMethodType.swift:401-426`: types that can be set up (`setup_future_usage` or a SetupIntent). Link isn't a
    /// form type, but its own flows confirm SetupIntents (`PaymentSheet+API.swift:463`).
    static let setupCapableTypes: Set<NativeType> = [
        .card, .pix, .gcash, .touchNGo, .trueMoney, .alipay, .payPal, .cashApp, .revolutPay, .amazonPay, .klarna,
        .satispay, .twint, .kakaoPay, .naverPay, .krCard, .USBankAccount, .boleto, .iDEAL, .bancontact, .SEPADebit,
        .AUBECSDebit, .bacsDebit, .link,
    ]

    static func supportsSetup(_ type: NativeType) -> Bool {
        return setupCapableTypes.contains(type)
    }

    /// `PaymentMethodType.swift:428-451`: types offered only when the merchant set `returnURL`, plus the types whose
    /// next action fails without one (STPPaymentHandler.swift:1455, :1467, :1496, :1535).
    static let returnURLRequiredTypes: Set<NativeType> = [
        .momo, .shopeePay, .qris, .gcash, .ngCard, .ngBankTransfer, .ngUSSD, .ngWallet, .mondu, .touchNGo, .trueMoney,
        .goPay, .alipay, .EPS, .FPX, .grabPay, .payPal, .przelewy24, .klarna, .bancontact, .iDEAL, .cashApp,
        .affirm, .zip, .revolutPay, .amazonPay, .alma, .mobilePay, .vipps, .swish, .twint, .sunbit, .billie, .satispay,
        .crypto, .afterpayClearpay, .payPay, .wero, .payByBank, .kakaoPay, .krCard, .naverPay, .payco, .sequra,
        .scalapay, .bacsDebit, .paynow, .promptPay,
    ]

    /// `mandate_data` on every confirm: `STPPaymentIntentConfirmParams.mandateDataIfRequired` (STPPaymentIntentConfirmParams.swift:317).
    static let alwaysMandateTypes: Set<NativeType> = [.gcash, .AUBECSDebit, .bacsDebit, .bancontact, .iDEAL, .SEPADebit, .EPS, .link, .USBankAccount]

    /// `mandate_data` only when setting up: `requiresMandateDataForPaymentIntent` and `requiresMandateDataForSetupIntent`
    /// (PaymentSheet+PaymentMethodAvailability.swift:395-402) and `STPSetupIntentConfirmParams.mandateDataIfRequired`
    /// (STPSetupIntentConfirmParams.swift:211).
    static let settingUpMandateTypes: Set<NativeType> = [
        .touchNGo, .trueMoney, .alipay, .payPal, .cashApp, .revolutPay, .amazonPay, .klarna, .satispay, .twint,
        .kakaoPay, .naverPay, .krCard, .pix,
    ]

    static func params(for type: NativeType) -> Params {
        let mandateData: Params.MandateData
        if alwaysMandateTypes.contains(type) {
            mandateData = .always
        } else if settingUpMandateTypes.contains(type) {
            mandateData = .whenSettingUp
        } else {
            mandateData = .none
        }
        var options: [Params.PaymentMethodOption] = []
        if type == .card {
            options = [.cardCVCRecollection, .cardNetwork]
        } else if type == .USBankAccount {
            options = [.usBankAccountVerificationMethod]
        }
        return Params(
            paymentMethodDataType: type.identifier,
            returnURL: returnURLRequiredTypes.contains(type) ? .required : .sentIfSet,
            mandateData: mandateData,
            setupFutureUsage: Params.SetupFutureUsage(
                supportsSetup: supportsSetup(type),
                // IntentConfirmParams.swift:248 `setSetupFutureUsageIfNecessary` (Link only with a CustomerSession).
                sendsCustomerChoiceInPaymentMethodOptions: [.card, .USBankAccount, .link].contains(type)
            ),
            paymentMethodOptions: options
        )
    }
}

// MARK: - Building blocks

extension ConfirmationMetadata.NextAction {
    /// `redirect_to_url`, which STPPaymentHandler performs for any type (STPPaymentHandler.swift:1157).
    static let redirectToURL = ConfirmationMetadata.NextAction(
        presenter: .redirect(browser: .fromNextAction),
        urlPath: "url",
        fallbackURLPath: nil,
        returnURL: .nextAction,
        appToApp: .universalLinksOnly,
        whileRequiresAction: nil
    )

    /// A hosted voucher the customer pays later, so `requires_action` means success (STPPaymentHandler.swift:2134).
    static let voucher = ConfirmationMetadata.NextAction(
        presenter: .redirect(browser: .safariViewController),
        urlPath: "hosted_voucher_url",
        fallbackURLPath: nil,
        returnURL: .none,
        appToApp: .universalLinksOnly,
        whileRequiresAction: .succeed
    )

    /// BLIK, MB WAY and Bizum: PaymentSheet's polling screen finishes the payment (STPPaymentHandler.swift:1415-1449).
    static func pollingScreen(_ screen: ConfirmationMetadata.NextAction.PollingScreen) -> Self {
        return .init(presenter: .pollingScreen(screen, overWebView: false), urlPath: nil, fallbackURLPath: nil, returnURL: .none, appToApp: .none, whileRequiresAction: .succeed)
    }

    /// PayNow, PromptPay and Pix: hosted instructions in a web view, with the polling screen behind it.
    static func qrCodeWithPollingScreen(_ screen: ConfirmationMetadata.NextAction.PollingScreen, returnURL: ReturnURLSource, whileRequiresAction: ConfirmationMetadata.Outcome?) -> Self {
        return .init(presenter: .pollingScreen(screen, overWebView: true), urlPath: "hosted_instructions_url", fallbackURLPath: nil, returnURL: returnURL, appToApp: .universalLinksOnly, whileRequiresAction: whileRequiresAction)
    }
}

// MARK: - Server spec

extension ConfirmationMetadata {
    /// The whole policy for a server-driven payment method. Every field comes from the spec or, where the contract has
    /// no field, from the contract's documented default. Nothing comes from the native table.
    init(serverSpec spec: ServerDrivenConfirmSpec, paymentMethodDataType: String) {
        let processing: Outcome
        switch spec.processing {
        case .succeed: processing = .succeed
        case .fail: processing = .fail
        case .poll: processing = .poll(seconds: spec.pollSeconds, onTimeout: .fail)
        }
        let requiresAction: Outcome
        switch spec.requiresAction {
        case .cancel: requiresAction = .cancel
        case .poll: requiresAction = .poll(seconds: spec.pollSeconds, onTimeout: .cancel)
        case .succeed: requiresAction = .succeed
        }
        var nextActions: [String: NextAction] = [:]
        for nextAction in spec.nextActions {
            switch nextAction {
            case .redirectToURL:
                nextActions["redirect_to_url"] = .redirectToURL
            }
        }
        self.init(
            params: Params(
                paymentMethodDataType: paymentMethodDataType,
                returnURL: .sentIfSet,
                // `ServerDrivenPaymentMethod` drops a PM whose spec asks for mandate_data or setup_future_usage.
                mandateData: .none,
                setupFutureUsage: .unsupported,
                paymentMethodOptions: []
            ),
            nextActions: nextActions,
            paymentIntent: IntentRules(
                afterConfirm: StatusRules(processing: processing, requiresAction: .performNextAction),
                afterNextAction: StatusRules(processing: processing, requiresAction: requiresAction),
                afterWebViewDismissed: nil
            ),
            setupIntent: nil,
            retrieval: spec.retrieval == .refresh ? .refresh : .retrieve,
            beforeFetch: nil,
            onCancel: .none
        )
    }
}
