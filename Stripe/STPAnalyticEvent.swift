//
//  STPAnalyticEvent.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Enumeration of all the analytic events logged by our SDK
enum STPAnalyticEvent: String {
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
}
