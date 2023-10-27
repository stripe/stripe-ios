//
//  STPAnalyticEvent.swift
//  StripeCore
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Enumeration of all the analytic events logged by our SDK.
@_spi(STP) public enum STPAnalyticEvent: String {
    // MARK: - Payment Creation
    case tokenCreation = "stripeios.token_creation"

    // This was "stripeios.source_creation" in earlier SDKs,
    // but we need to support both the old and new values forever.
    case sourceCreation = "stripeios.source_creationn"

    case paymentMethodCreation = "stripeios.payment_method_creation"
    case paymentMethodIntentCreation = "stripeios.payment_intent_confirmation"
    case setupIntentConfirmationAttempt = "stripeios.setup_intent_confirmation"

    // MARK: - Payment Confirmation
    case _3DS2AuthenticationRequestParamsFailed =
        "stripeios.3ds2_authentication_request_params_failed"
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

    // MARK: - Card Element Config
    case cardElementConfigLoadFailure = "stripeios.card_element_config_load_failure"

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

    // MARK: - Link Popup
    case linkPopupShow = "link.popup.show"
    case linkPopupSuccess = "link.popup.success"
    case linkPopupCancel = "link.popup.cancel"
    case linkPopupSkipped = "link.popup.skipped"
    case linkPopupError = "link.popup.error"
    case linkPopupLogout = "link.popup.logout"

    // MARK: - Link Misc
    case linkAccountLookupFailure = "link.account_lookup.failure"

    // MARK: - LUXE
    case luxeSerializeFailure = "luxe_serialize_failure"
    case luxeUnknownActionsFailure = "luxe_unknown_actions_failure"
    case luxeSpecSerializeFailure = "luxe_spec_serialize_failure"

    case luxeImageSelectorIconDownloaded = "luxe_image_selector_icon_downloaded"
    case luxeImageSelectorIconFromBundle = "luxe_image_selector_icon_from_bundle"
    case luxeImageSelectorIconNotFound = "luxe_image_selector_icon_not_found"

    // MARK: - Customer Sheet
    case cs_add_payment_method_screen_presented = "cs_add_payment_method_screen_presented"
    case cs_select_payment_method_screen_presented = "cs_select_payment_method_screen_presented"

    case cs_select_payment_method_screen_confirmed_savedpm_success = "cs_select_payment_method_screen_confirmed_savedpm_success"
    case cs_select_payment_method_screen_confirmed_savedpm_failure = "cs_select_payment_method_screen_confirmed_savedpm_failure"

    case cs_select_payment_method_screen_edit_tapped = "cs_select_payment_method_screen_edit_tapped"
    case cs_select_payment_method_screen_done_tapped = "cs_select_payment_method_screen_done_tapped"

    case cs_select_payment_method_screen_removepm_success = "cs_select_payment_method_screen_removepm_success"
    case cs_select_payment_method_screen_removepm_failure = "cs_select_payment_method_screen_removepm_failure"

    case cs_add_payment_method_via_setupintent_success = "cs_add_payment_method_via_setup_intent_success"
    case cs_add_payment_method_via_setupintent_canceled = "cs_add_payment_method_via_setupintent_canceled"
    case cs_add_payment_method_via_setupintent_failure = "cs_add_payment_method_via_setup_intent_failure"

    case cs_add_payment_method_via_createAttach_success = "cs_add_payment_method_via_createAttach_success"
    case cs_add_payment_method_via_createAttach_failure = "cs_add_payment_method_via_createAttach_failure"

    // MARK: - Address Element
    case addressShow = "mc_address_show"
    case addressCompleted = "mc_address_completed"

    // MARK: - PaymentMethodMessagingView
    case paymentMethodMessagingViewLoadSucceeded = "pmmv_load_succeeded"
    case paymentMethodMessagingViewLoadFailed = "pmmv_load_failed"
    case paymentMethodMessagingViewTapped = "pmmv_tapped"

    // MARK: - PaymentSheet Force Success
    case paymentSheetForceSuccess = "mc_force_success"

    // MARK: - PaymentSheet initialization
    case paymentSheetLoadStarted = "mc_load_started"
    case paymentSheetLoadSucceeded = "mc_load_succeeded"
    case paymentSheetLoadFailed = "mc_load_failed"

    // MARK: - PaymentSheet dismiss
    case paymentSheetDismissed = "mc_dismiss"

    // MARK: - PaymentSheet checkout
    case paymentSheetCarouselPaymentMethodTapped = "mc_carousel_payment_method_tapped"
    case paymentSheetConfirmButtonTapped = "mc_confirm_button_tapped"
}
