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
    case sourceCreation = "stripeios.source_creationn"
    case paymentMethodCreation = "stripeios.payment_method_creation"
    case paymentMethodIntentCreation = "stripeios.payment_intent_confirmation"
    case setupIntentConfirmationAttempt = "stripeios.setup_intent_confirmation"

    // MARK: - Payment Confirmation
    case _3DS2AuthenticationAttempt = "stripeios.3ds2_authenticate"
    case _3DS2FrictionlessFlow = "stripeios.3ds2_frictionless_flow"
    case urlRedirectNextAction = "stripeios.url_redirect_next_action"
    case _3DS2ChallengeFlowPresented = "stripeios.3ds2_challenge_flow_presented"
    case _3DS2ChallengeFlowTimedOut = "stripeios.3ds2_challenge_flow_timed_out"
    case _3DS2ChallengeFlowUserCanceled = "stripeios.3ds2_challenge_flow_canceled"
    case _3DS2ChallengeFlowCompleted = "stripeios.3ds2_challenge_flow_completed"
    case _3DS2ChallengeFlowErrored = "stripeios.3ds2_challenge_flow_errored"

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
    case mcShowCompleteNewPM = "mc_complete_sheet_newpm_show"
    case mcShowCompleteSavedPM = "mc_complete_sheet_savedpm_show"
    case mcShowCompleteApplePay = "mc_complete_sheet_applepay_show"
    
    // MARK: - PaymentSheet Payment
    case mcPaymentCustomNewPMSuccess = "mc_custom_payment_newpm_success"
    case mcPaymentCustomSavedPMSuccess = "mc_custom_payment_savedpm_success"
    case mcPaymentCustomApplePaySuccess = "mc_custom_payment_applepay_success"
    
    case mcPaymentCompleteNewPMSuccess = "mc_complete_payment_newpm_success"
    case mcPaymentCompleteSavedPMSuccess = "mc_complete_payment_savedpm_success"
    case mcPaymentCompleteApplePaySuccess = "mc_complete_payment_applepay_success"
    
    case mcPaymentCustomNewPMFailure = "mc_custom_payment_newpm_failure"
    case mcPaymentCustomSavedPMFailure = "mc_custom_payment_savedpm_failure"
    case mcPaymentCustomApplePayFailure = "mc_custom_payment_applepay_failure"
    
    case mcPaymentCompleteNewPMFailure = "mc_complete_payment_newpm_failure"
    case mcPaymentCompleteSavedPMFailure = "mc_complete_payment_savedpm_failure"
    case mcPaymentCompleteApplePayFailure = "mc_complete_payment_applepay_failure"
    
    // MARK: - PaymentSheet Option Selected
    case mcOptionSelectCustomNewPM = "mc_custom_paymentoption_newpm_select"
    case mcOptionSelectCustomSavedPM = "mc_custom_paymentoption_savedpm_select"
    case mcOptionSelectCustomApplePay = "mc_custom_paymentoption_applepay_select"
    case mcOptionSelectCompleteNewPM = "mc_complete_paymentoption_newpm_select"
    case mcOptionSelectCompleteSavedPM = "mc_complete_paymentoption_savedpm_select"
    case mcOptionSelectCompleteApplePay = "mc_complete_paymentoption_applepay_select"
}
