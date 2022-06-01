//
//  STPAnalyticEvent.swift
//  StripeCore
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Enumeration of all the analytic events logged by our SDK
@_spi(STP) public enum STPAnalyticEvent: String {
    // MARK: - Payment Creation
    case tokenCreation = "stripeios.token_creation"
    
    // This was "stripeios.source_creation" in earlier SDKs, but we need to support both the old and new values forever.
    case sourceCreation = "stripeios.source_creationn"
    
    case paymentMethodCreation = "stripeios.payment_method_creation"
    case paymentMethodIntentCreation = "stripeios.payment_intent_confirmation"
    case setupIntentConfirmationAttempt = "stripeios.setup_intent_confirmation"

    // MARK: - Payment Confirmation
    case _3DS2AuthenticationRequestParamsFailed = "stripeios.3ds2_authentication_request_params_failed"
    case _3DS2AuthenticationAttempt = "stripeios.3ds2_authenticate"
    case _3DS2FrictionlessFlow = "stripeios.3ds2_frictionless_flow"
    case urlRedirectNextAction = "stripeios.url_redirect_next_action"
    case _3DS2ChallengeFlowPresented = "stripeios.3ds2_challenge_flow_presented"
    case _3DS2ChallengeFlowTimedOut = "stripeios.3ds2_challenge_flow_timed_out"
    case _3DS2ChallengeFlowUserCanceled = "stripeios.3ds2_challenge_flow_canceled"
    case _3DS2ChallengeFlowCompleted = "stripeios.3ds2_challenge_flow_completed"
    case _3DS2ChallengeFlowErrored = "stripeios.3ds2_challenge_flow_errored"
    case _3DS2RedirectUserCanceled = "stripeios.3ds2_redirect_canceled"

    // MARK: - Card Metadata
    case cardMetadataLoadedTooSlow = "stripeios.card_metadata_loaded_too_slow"
    case cardMetadataResponseFailure = "stripeios.card_metadata_load_failure"
    case cardMetadataMissingRange = "stripeios.card_metadata_missing_range"

    // MARK: - Card Scanning
    case cardScanSucceeded = "stripeios.cardscan_success"
    case cardScanCancelled = "stripeios.cardscan_cancel"

    // MARK: - Identity Verification Flow
    case verificationSheetPresented = "stripeios.idprod.verification_sheet.presented"
    case verificationSheetClosed = "stripeios.idprod.verification_sheet.closed"
    case verificationSheetFailed = "stripeios.idprod.verification_sheet.failed"

    // MARK: - FinancialConnections
    case financialConnectionsSheetPresented = "stripeios.financialconnections.sheet.presented"
    case financialConnectionsSheetClosed = "stripeios.financialconnections.sheet.closed"
    case financialConnectionsSheetFailed = "stripeios.financialconnections.sheet.failed"

    // MARK: - PaymentSheet Init
    case mcInitCustomCustomer = "mc_custom_init_customer"
    case mcInitCompleteCustomer = "mc_complete_init_customer"
    case mcInitCustomApplePay = "mc_custom_init_applepay"
    case mcInitCompleteApplePay = "mc_complete_init_applepay"
    case mcInitCustomCustomerApplePay = "mc_custom_init_customer_applepay"
    case mcInitCompleteCustomerApplePay = "mc_complete_init_customer_applepay"
    case mcInitCustomDefault = "mc_custom_init_default"
    case mcInitCompleteDefault = "mc_complete_init_default"
    
    // MARK: - PaymentSheet Show
    case mcShowCustomNewPM = "mc_custom_sheet_newpm_show"
    case mcShowCustomSavedPM = "mc_custom_sheet_savedpm_show"
    case mcShowCustomApplePay = "mc_custom_sheet_applepay_show"
    case mcShowCustomLink = "mc_custom_sheet_link_show"
    case mcShowCompleteNewPM = "mc_complete_sheet_newpm_show"
    case mcShowCompleteSavedPM = "mc_complete_sheet_savedpm_show"
    case mcShowCompleteApplePay = "mc_complete_sheet_applepay_show"
    case mcShowCompleteLink = "mc_complete_sheet_link_show"
    
    // MARK: - PaymentSheet Payment
    case mcPaymentCustomNewPMSuccess = "mc_custom_payment_newpm_success"
    case mcPaymentCustomSavedPMSuccess = "mc_custom_payment_savedpm_success"
    case mcPaymentCustomApplePaySuccess = "mc_custom_payment_applepay_success"
    case mcPaymentCustomLinkSuccess = "mc_custom_payment_link_success"
    
    case mcPaymentCompleteNewPMSuccess = "mc_complete_payment_newpm_success"
    case mcPaymentCompleteSavedPMSuccess = "mc_complete_payment_savedpm_success"
    case mcPaymentCompleteApplePaySuccess = "mc_complete_payment_applepay_success"
    case mcPaymentCompleteLinkSuccess = "mc_complete_payment_link_success"
    
    case mcPaymentCustomNewPMFailure = "mc_custom_payment_newpm_failure"
    case mcPaymentCustomSavedPMFailure = "mc_custom_payment_savedpm_failure"
    case mcPaymentCustomApplePayFailure = "mc_custom_payment_applepay_failure"
    case mcPaymentCustomLinkFailure = "mc_custom_payment_link_failure"
    
    case mcPaymentCompleteNewPMFailure = "mc_complete_payment_newpm_failure"
    case mcPaymentCompleteSavedPMFailure = "mc_complete_payment_savedpm_failure"
    case mcPaymentCompleteApplePayFailure = "mc_complete_payment_applepay_failure"
    case mcPaymentCompleteLinkFailure = "mc_complete_payment_link_failure"
    
    // MARK: - PaymentSheet Option Selected
    case mcOptionSelectCustomNewPM = "mc_custom_paymentoption_newpm_select"
    case mcOptionSelectCustomSavedPM = "mc_custom_paymentoption_savedpm_select"
    case mcOptionSelectCustomApplePay = "mc_custom_paymentoption_applepay_select"
    case mcOptionSelectCustomLink = "mc_custom_paymentoption_link_select"
    case mcOptionSelectCompleteNewPM = "mc_complete_paymentoption_newpm_select"
    case mcOptionSelectCompleteSavedPM = "mc_complete_paymentoption_savedpm_select"
    case mcOptionSelectCompleteApplePay = "mc_complete_paymentoption_applepay_select"
    case mcOptionSelectCompleteLink = "mc_complete_paymentoption_link_select"

    // MARK: - Link Signup
    case linkSignupCheckboxChecked = "link.signup.checkbox_checked"
    case linkSignupFlowPresented = "link.signup.flow_presented"
    case linkSignupStart = "link.signup.start"
    case linkSignupComplete = "link.signup.complete"
    case linkSignupFailure = "link.signup.failure"

    // MARK: - Link 2FA
    case link2FAStart = "link.2fa.start"
    case link2FAStartFailure = "link.2fa.start_failure"
    case link2FAComplete = "link.2fa.complete"
    case link2FACancel = "link.2fa.cancel"
    case link2FAFailure = "link.2fa.failure"

    // MARK: - Link Misc
    case linkAccountLookupFailure = "link.account_lookup.failure"
}
