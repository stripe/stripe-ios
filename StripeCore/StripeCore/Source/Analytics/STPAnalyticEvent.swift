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
    case paymentMethodUpdate = "stripeios.payment_method_update"
    case confirmationTokenCreation = "stripeios.confirmation_token_creation"
    case paymentMethodIntentCreation = "stripeios.payment_intent_confirmation"
    case setupIntentConfirmationAttempt = "stripeios.setup_intent_confirmation"

    // MARK: - Payment Confirmation
    case _3DS2AuthenticationRequestParamsFailed =
            "stripeios.3ds2_authentication_request_params_failed"
    case _3DS2AuthenticationAttempt = "stripeios.3ds2_authenticate"
    case _3DS2FrictionlessFlow = "stripeios.3ds2_frictionless_flow"
    case urlRedirectNextAction = "stripeios.url_redirect_next_action"
    case urlRedirectNextActionCompleted = "stripeios.url_redirect_next_action_completed"
    case _3DS2ChallengeFlowPresented = "stripeios.3ds2_challenge_flow_presented"
    case _3DS2ChallengeFlowTimedOut = "stripeios.3ds2_challenge_flow_timed_out"
    case _3DS2ChallengeFlowUserCanceled = "stripeios.3ds2_challenge_flow_canceled"
    case _3DS2ChallengeFlowCompleted = "stripeios.3ds2_challenge_flow_completed"
    case _3DS2ChallengeFlowErrored = "stripeios.3ds2_challenge_flow_errored"
    case _3DS2RedirectUserCanceled = "stripeios.3ds2_redirect_canceled"
    case paymentHandlerConfirmStarted = "stripeios.paymenthandler.confirm.started"
    case paymentHandlerConfirmFinished = "stripeios.paymenthandler.confirm.finished"
    case paymentHandlerHandleNextActionStarted = "stripeios.paymenthandler.handle_next_action.started"
    case paymentHandlerHandleNextActionFinished = "stripeios.paymenthandler.handle_next_action.finished"

    // MARK: - Card Metadata
    case cardMetadataLoadedTooSlow = "stripeios.card_metadata_loaded_too_slow"
    case cardMetadataResponseFailure = "stripeios.card_metadata_load_failure"
    case cardMetadataMissingRange = "stripeios.card_metadata_missing_range"
    case cardMetadataExpectedExtraDigitsButUserEntered16ThenSwitchedFields = "stripeios.card_metadata.expected_extra_digits_but_user_entered_16_then_switched_fields"

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
    case financialConnectionsSheetFlowDetermined = "stripeios.financialconnections.sheet.flow_determined"
    case financialConnectionsSheetInitialSynchronizeStarted = "stripeios.financialconnections.sheet.initial_synchronize.started"
    case financialConnectionsSheetInitialSynchronizeCompleted = "stripeios.financialconnections.sheet.initial_synchronize.completed"
    case instantDebitsCompletionFailed = "stripeios.financialconnections.instant_debits_completion.failed"

    // MARK: - PaymentSheet Init
    case mcInitCustomCustomer = "mc_custom_init_customer"
    case mcInitCompleteCustomer = "mc_complete_init_customer"
    case mcInitCustomApplePay = "mc_custom_init_applepay"
    case mcInitCompleteApplePay = "mc_complete_init_applepay"
    case mcInitCustomCustomerApplePay = "mc_custom_init_customer_applepay"
    case mcInitCompleteCustomerApplePay = "mc_complete_init_customer_applepay"
    case mcInitCustomDefault = "mc_custom_init_default"
    case mcInitCompleteDefault = "mc_complete_init_default"

    // MARK: - Embedded Payment Element init
    case mcInitEmbedded = "mc_embedded_init"

    // MARK: - Embedded Payment Element confirm
    case mcConfirmEmbedded = "mc_embedded_confirm"

    // MARK: - Embedded Payment Element update
    case mcUpdateStartedEmbedded = "mc_embedded_update_started"
    case mcUpdateFinishedEmbedded = "mc_embedded_update_finished"

    // MARK: - PaymentSheet Show
    case mcShowCustomNewPM = "mc_custom_sheet_newpm_show"
    case mcShowCustomSavedPM = "mc_custom_sheet_savedpm_show"
    case mcShowCompleteNewPM = "mc_complete_sheet_newpm_show"
    case mcShowCompleteSavedPM = "mc_complete_sheet_savedpm_show"

    // MARK: - PaymentSheet Render
    case mcRenderLPMs = "mc_lpms_render"

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

    case mcPaymentEmbeddedSuccess = "mc_embedded_payment_success"
    case mcPaymentEmbeddedFailure = "mc_embedded_payment_failure"

    // MARK: - PaymentSheet Option Selected
    case mcOptionSelectCustomNewPM = "mc_custom_paymentoption_newpm_select"
    case mcOptionSelectCustomSavedPM = "mc_custom_paymentoption_savedpm_select"
    case mcOptionSelectCustomApplePay = "mc_custom_paymentoption_applepay_select"
    case mcOptionSelectCustomLink = "mc_custom_paymentoption_link_select"
    case mcOptionSelectCompleteNewPM = "mc_complete_paymentoption_newpm_select"
    case mcOptionSelectCompleteSavedPM = "mc_complete_paymentoption_savedpm_select"
    case mcOptionSelectCompleteApplePay = "mc_complete_paymentoption_applepay_select"
    case mcOptionSelectCompleteLink = "mc_complete_paymentoption_link_select"
    case mcOptionSelectEmbeddedSavedPM = "mc_embedded_paymentoption_savedpm_select"

    // MARK: - PaymentSheet Wallet Button Tap
    case mcWalletButtonTapped = "mc_wallet_button_tapped"

    // MARK: - PaymentSheet Saved Payment Method Removed
    case mcOptionRemoveCustomSavedPM = "mc_custom_paymentoption_removed"
    case mcOptionRemoveCompleteSavedPM = "mc_complete_paymentoption_removed"
    case mcOptionRemoveEmbeddedSavedPM = "mc_embedded_paymentoption_removed"

    // MARK: - Link Signup
    case linkSignupCheckboxChecked = "link.signup.checkbox_checked"
    case linkSignupFlowPresented = "link.signup.flow_presented"
    case linkSignupStart = "link.signup.start"
    case linkSignupComplete = "link.signup.complete"
    case linkSignupFailure = "link.signup.failure"
    case linkCreatePaymentDetailsFailure = "link.payment.failure.create"
    case linkSharePaymentDetailsFailure = "link.payment.failure.share"
    case linkSignupFailureInvalidSessionState = "link.signup.failure.invalidSessionState"
    case linkSignupFailureAccountExists = "link.signup.failure.account_exists"
    case linkInlineSignupShown = "link.inline_signup.shown"

    // MARK: - Link Popup
    case linkPopupShow = "link.popup.show"
    case linkPopupSuccess = "link.popup.success"
    case linkPopupCancel = "link.popup.cancel"
    case linkPopupSkipped = "link.popup.skipped"
    case linkPopupError = "link.popup.error"
    case linkPopupLogout = "link.popup.logout"

    // MARK: - Link 2FA
    case link2FAStart = "link.2fa.start"
    case link2FAStartFailure = "link.2fa.start_failure"
    case link2FAComplete = "link.2fa.complete"
    case link2FACancel = "link.2fa.cancel"
    case link2FAFailure = "link.2fa.failure"
    case link2FAResendCode = "link.2fa.resend_code"
    case linkNativeBailed = "link.native.bailed"

    // MARK: - Link Misc
    case linkAccountLookupComplete = "link.account_lookup.complete"
    case linkAccountLookupFailure = "link.account_lookup.failure"
    case linkEmailSuggestionAccepted = "link.email_suggestion.accepted"

    // MARK: - LUXE
    case luxeSerializeFailure = "luxe_serialize_failure"
    case luxeSpecSerializeFailure = "luxe_spec_serialize_failure"

    case luxeImageSelectorIconDownloaded = "luxe_image_selector_icon_downloaded"
    case luxeImageSelectorIconFromBundle = "luxe_image_selector_icon_from_bundle"
    case luxeImageSelectorIconNotFound = "luxe_image_selector_icon_not_found"

    // MARK: - CustomerSheet initialization
    case customerSheetInitWithCustomerAdapter = "cs_init_with_customer_adapter"
    case customerSheetInitWithCustomerSession = "cs_init_with_customer_session"
    case customerSheetLoadStarted = "cs_load_started"
    case customerSheetLoadSucceeded = "cs_load_succeeded"
    case customerSheetLoadFailed = "cs_load_failed"

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
    case paymentSheetFormShown = "mc_form_shown"
    case paymentSheetFormInteracted = "mc_form_interacted"
    case paymentSheetFormCompleted = "mc_form_completed"
    case paymentSheetCardNumberCompleted = "mc_card_number_completed"
    case paymentSheetDeferredIntentPaymentMethodMismatch = "mc_deferred_intent_payment_method_mismatch"

    // MARK: - v1/elements/session
    case paymentSheetElementsSessionLoadFailed = "mc_elements_session_load_failed"
    case paymentSheetElementsSessionCustomerDeserializeFailed = "mc_elements_session_customer_deserialize_failed"
    case paymentSheetElementsSessionEPMLoadFailed = "mc_elements_session_epms_load_failed"
    case paymentSheetElementsSessionCPMLoadFailed = "mc_elements_session_cpms_load_failed"

    // MARK: - PaymentSheet card brand choice
    case paymentSheetDisplayCardBrandDropdownIndicator = "mc_display_cbc_dropdown"
    case paymentSheetCardBrandSelected = "mc_cbc_selected"
    case paymentSheetOpenEditScreen = "mc_open_edit_screen"
    case paymentSheetUpdateCard = "mc_update_card"
    case paymentSheetUpdateCardFailed = "mc_update_card_failed"
    case paymentSheetClosesEditScreen = "mc_cancel_edit_screen"
    case paymentSheetDisallowedCardBrand = "mc_disallowed_card_brand"

    // MARK: - CustomerSheet card brand choice
    case customerSheetDisplayCardBrandDropdownIndicator = "cs_display_cbc_dropdown"
    case customerSheetCardBrandSelected = "cs_cbc_selected"
    case customerSheetOpenEditScreen = "cs_open_edit_screen"
    case customerSheetUpdateCard = "cs_update_card"
    case customerSheetUpdateCardFailed = "cs_update_card_failed"
    case customerSheetClosesEditScreen = "cs_cancel_edit_screen"

    // MARK: - PaymentSheet set default
    case paymentSheetSetDefaultPaymentMethod = "mc_set_default_payment_method"
    case paymentSheetSetDefaultPaymentMethodFailed = "mc_set_default_payment_method_failed"

    // MARK: - Payment Method Messaging Element (PMME)
    case paymentMethodMessagingElementInit = "payment_method_messaging_element_init"
    case paymentMethodMessagingElementLoadStarted = "payment_method_messaging_element_load_started"
    case paymentMethodMessagingElementLoadSucceeded = "payment_method_messaging_element_load_succeeded"
    case paymentMethodMessagingElementLoadFailed = "payment_method_messaging_element_load_failed"
    case paymentMethodMessagingElementDisplayed = "payment_method_messaging_element_displayed"
    case paymentMethodMessagingElementTapped = "payment_method_messaging_element_tapped"

    // MARK: - STPBankAccountCollector
    case bankAccountCollectorStarted = "stripeios.bankaccountcollector.started"
    case bankAccountCollectorFinished = "stripeios.bankaccountcollector.finished"

    // MARK: - Unexpected errors
    // ⚠️ Errors with the "unexpected_error" prefix should **never happen** and indicate a problem with the SDK or the Stripe backend and will trigger an assertion + cerberus alert.
    case unexpectedPaymentSheetFormFactoryError = "unexpected_error.paymentsheet.formfactory"
    case unexpectedStripeUICoreAddressSpecProvider = "unexpected_error.stripeuicore.addressspecprovider"
    case unexpectedStripeUICoreBSBNumberProvider = "unexpected_error.stripeuicore.bsbnumberprovider"
    case unexpectedPaymentSheetError = "unexpected_error.paymentsheet"
    case unexpectedCustomerSheetError = "unexpected_error.customersheet"
    case unexpectedPMMEError = "unexpected_error.paymentmethodmessagingelement"
    case unexpectedPaymentSheetConfirmationError = "unexpected_error.paymentsheet.confirmation"
    case unexpectedPaymentSheetViewControllerError = "unexpected_error.paymentsheet.paymentsheetviewcontroller"
    case unexpectedFlowControllerViewControllerError = "unexpected_error.paymentsheet.flowcontrollerviewcontroller"
    case unexpectedPaymentHandlerError = "unexpected_error.paymenthandler"

    // MARK: - Misc. errors
    case stripePaymentSheetDownloadManagerError = "stripepaymentsheet.downloadmanager.error"

    // MARK: - Refresh Endpoint
    case refreshPaymentIntentStarted = "stripeios.refresh_payment_intent_started"
    case refreshSetupIntentStarted = "stripeios.refresh_setup_intent_started"
    case refreshPaymentIntentSuccess = "stripeios.refresh_payment_intent_success"
    case refreshSetupIntentSuccess = "stripeios.refresh_setup_intent_success"
    case refreshPaymentIntentFailed = "stripeios.refresh_payment_intent_failed"
    case refreshSetupIntentFailed = "stripeios.refresh_setup_intent_failed"

    // MARK: - Telemetry Client
    case fraudDetectionApiFailure = "fraud_detection_data_repository.api_failure"
    case savedPaymentMethodRadarSessionFailure = "stripeios.saved_payment_method_radar_session_failure"

    // MARK: - Attestation
    case attestationFailed = "stripeios.attest.attestation.failed"
    case attestationSucceeded = "stripeios.attest.attestation.succeeded"
    case assertionFailed = "stripeios.attest.assertion.failed"
    case assertionSucceeded = "stripeios.attest.assertion.succeeded"
    case resetKeyForAssertionError = "stripeios.attest.reset_key_for_assertion_error"
    case resetKeyForAttestationError = "stripeios.attest.reset_key_for_attestation_error"
    case stateMismatchNotAttestedLocally = "stripeios.attest.state_mismatch.not_attested_locally"
    case stateMismatchNotAttestedRemotely = "stripeios.attest.state_mismatch.not_attested_remotely"

    // MARK: - Custom Payment Methods
    case paymentSheetInvalidCPM = "mc_invalid_cpm"

    // MARK: - Shop Pay Webview
    case shopPayWebviewLoadAttempt = "mc_shoppay_webview_load_attempt"
    case shopPayWebviewConfirmSuccess = "mc_shoppay_webview_confirm_success"
    case shopPayWebviewCancelled = "mc_shoppay_webview_cancelled"

    // MARK: - Captcha
    case passiveCaptchaInit = "elements.captcha.passive.init"
    case passiveCaptchaExecute = "elements.captcha.passive.execute"
    case passiveCaptchaSuccess = "elements.captcha.passive.success"
    case passiveCaptchaError = "elements.captcha.passive.error"
    case passiveCaptchaAttach = "elements.captcha.passive.attach"

    // MARK: - Attestation on Confirmation
    case attestationConfirmationPrepare = "elements.attestation.confirmation.prepare"
    case attestationConfirmationPrepareSucceeded = "elements.attestation.confirmation.prepare_succeeded"
    case attestationConfirmationPrepareFailed = "elements.attestation.confirmation.prepare_failed"
    case attestationConfirmationRequestToken = "elements.attestation.confirmation.request_token"
    case attestationConfirmationRequestTokenSucceeded = "elements.attestation.confirmation.request_token_succeeded"
    case attestationConfirmationRequestTokenFailed = "elements.attestation.confirmation.request_token_failed"
    case attestationConfirmationError = "elements.attestation.confirmation.error"

    // MARK: - Intent Confirmation Challenge
    case intentConfirmationChallengeStart = "elements.intent_confirmation_challenge.start"
    case intentConfirmationChallengeSuccess = "elements.intent_confirmation_challenge.success"
    case intentConfirmationChallengeError = "elements.intent_confirmation_challenge.error"
    case intentConfirmationChallengeWebViewLoaded = "elements.intent_confirmation_challenge.web_view_loaded"

    // MARK: - STPApplePayContext
    case applePayContextStarted = "stripeios.applepaycontext.confirm.started"
    case applePayContextFinished = "stripeios.applepaycontext.confirm.finished"
}
