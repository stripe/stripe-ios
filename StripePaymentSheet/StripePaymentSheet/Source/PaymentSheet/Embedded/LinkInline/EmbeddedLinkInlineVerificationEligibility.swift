//
//  EmbeddedLinkInlineVerificationEligibility.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Decides whether a returning Link customer can verify inline in the Embedded Payment Element.
///
/// This is evaluated once per Link account. Once the code is sent the account no longer looks eligible (verification has started),
/// so later updates should only recheck the conditions that can actually change.
enum EmbeddedLinkInlineVerificationEligibility {
    enum IneligibleReason: String, Error {
        case disabledByServer = "disabled_by_server"
        /// Also how Checkout Elements opts out for now.
        case disabledByMerchant = "disabled_by_merchant"
        case linkNotDisplayed = "link_not_displayed"
        case notReturningLinkUser = "not_returning_link_user"
        case alreadyVerified = "already_verified"
        case nativeLinkUnavailable = "native_link_unavailable"
        case webViewRequired = "web_view_required"
        case verificationAlreadyStarted = "verification_already_started"
        case hasSavedPaymentMethods = "has_saved_payment_methods"
        /// Verification wouldn't start with an SMS code, e.g. it needs an email phone match first.
        case unsupportedVerification = "unsupported_verification"
        /// The customer closed the card earlier in this app session.
        case dismissedThisSession = "dismissed_this_session"
        /// Another Embedded instance is already showing the card.
        case shownElsewhere = "shown_elsewhere"
        /// A code was sent automatically a moment ago, e.g. before the merchant recreated the element.
        case codeRecentlySent = "code_recently_sent"
    }

    struct Eligible {
        let linkAccount: PaymentSheetLinkAccount
        /// Prepared without sending anything, on an SMS code challenge.
        let coordinator: LinkAuthFlowCoordinator
    }

    @MainActor
    static func evaluate(
        elementsSession: STPElementsSession,
        configuration: EmbeddedPaymentElement.Configuration,
        linkAccount: PaymentSheetLinkAccount?,
        savedPaymentMethods: [STPPaymentMethod],
        analyticsHelper: LinkAnalyticsHelper
    ) -> Result<Eligible, IneligibleReason> {
        guard elementsSession.linkEmbeddedInlineVerificationEnabled else {
            return .failure(.disabledByServer)
        }
        guard configuration.allowsLinkInlineVerification else {
            return .failure(.disabledByMerchant)
        }
        guard PaymentSheet.shouldShowLinkButton(elementsSession: elementsSession, configuration: configuration) else {
            return .failure(.linkNotDisplayed)
        }
        guard let linkAccount, linkAccount.isRegistered else {
            return .failure(.notReturningLinkUser)
        }
        guard linkAccount.sessionState == .requiresVerification else {
            return .failure(.alreadyVerified)
        }
        // Link credentials can only be handled natively in attested apps.
        guard linkAccount.useMobileEndpoints, deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) else {
            return .failure(.nativeLinkUnavailable)
        }
        guard linkAccount.currentSession?.mobileFallbackWebviewParams?.webviewRequirementType != .required else {
            return .failure(.webViewRequired)
        }
        guard linkAccount.currentSession?.hasStartedOTPVerification != true else {
            return .failure(.verificationAlreadyStarted)
        }
        // Saved payment methods are a better first choice than Link, same as PaymentSheet.
        guard savedPaymentMethods.isEmpty else {
            return .failure(.hasSavedPaymentMethods)
        }
        if let reason = EmbeddedLinkInlineAuthRegistry.ineligibleReason(email: linkAccount.email) {
            return .failure(reason)
        }
        let coordinator = LinkAuthFlowCoordinator(account: linkAccount, analyticsHelper: analyticsHelper)
        coordinator.prepare()
        guard coordinator.screen == .otp, coordinator.challenge?.type == .sms else {
            return .failure(.unsupportedVerification)
        }
        return .success(Eligible(linkAccount: linkAccount, coordinator: coordinator))
    }
}
