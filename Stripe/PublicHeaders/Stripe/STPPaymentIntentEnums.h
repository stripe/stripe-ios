//
//  STPPaymentIntentEnums.h
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPIntentAction.h"

/**
 Status types for an STPPaymentIntent
 */
typedef NS_ENUM(NSInteger, STPPaymentIntentStatus) {
    /**
     Unknown status
     */
    STPPaymentIntentStatusUnknown,
    
    /**
     This PaymentIntent requires a PaymentMethod or Source
     */
    STPPaymentIntentStatusRequiresPaymentMethod,

    /**
     This PaymentIntent requires a Source
     @deprecated Use STPPaymentIntentStatusRequiresPaymentMethod instead.
     */
    STPPaymentIntentStatusRequiresSource __attribute__((deprecated("Use STPPaymentIntentStatusRequiresPaymentMethod", "STPPaymentIntentStatusRequiresPaymentMethod"))) = STPPaymentIntentStatusRequiresPaymentMethod,

    /**
     This PaymentIntent needs to be confirmed
     */
    STPPaymentIntentStatusRequiresConfirmation,
    
    /**
     The selected PaymentMethod or Source requires additional authentication steps.
     Additional actions found via `next_action`
     */
    STPPaymentIntentStatusRequiresAction,

    /**
     The selected Source requires additional authentication steps.
     Additional actions found via `next_source_action`
     @deprecated Use STPPaymentIntentStatusRequiresAction instead.
     */
    STPPaymentIntentStatusRequiresSourceAction __attribute__((deprecated("Use STPPaymentIntentStatusRequiresAction", "STPPaymentIntentStatusRequiresAction"))) = STPPaymentIntentStatusRequiresAction,

    /**
     Stripe is processing this PaymentIntent
     */
    STPPaymentIntentStatusProcessing,

    /**
     The payment has succeeded
     */
    STPPaymentIntentStatusSucceeded,

    /**
     Indicates the payment must be captured, for STPPaymentIntentCaptureMethodManual
     */
    STPPaymentIntentStatusRequiresCapture,

    /**
     This PaymentIntent was canceled and cannot be changed.
     */
    STPPaymentIntentStatusCanceled,
};

/**
 Capture methods for a STPPaymentIntent
 */
typedef NS_ENUM(NSInteger, STPPaymentIntentCaptureMethod) {
    /**
     Unknown capture method
     */
    STPPaymentIntentCaptureMethodUnknown,

    /**
     The PaymentIntent will be automatically captured
     */
    STPPaymentIntentCaptureMethodAutomatic,

    /**
     The PaymentIntent must be manually captured once it has the status
     `STPPaymentIntentStatusRequiresCapture`
     */
    STPPaymentIntentCaptureMethodManual,
};

/**
 Confirmation methods for a STPPaymentIntent
 */
typedef NS_ENUM(NSInteger, STPPaymentIntentConfirmationMethod) {
    /**
     Unknown confirmation method
     */
    STPPaymentIntentConfirmationMethodUnknown,

    /**
     Confirmed via publishable key
     */
    STPPaymentIntentConfirmationMethodManual,

    /**
     Confirmed via secret key
     */
    STPPaymentIntentConfirmationMethodAutomatic,
};

/**
 Indicates how you intend to use the payment method that your customer provides after the current payment completes.
 
 If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
 
 @see https://stripe.com/docs/api/payment_intents/object#payment_intent_object-setup_future_usage
 */
typedef NS_ENUM(NSInteger, STPPaymentIntentSetupFutureUsage) {
    
    /**
     Unknown value.  Update your SDK, or use `allResponseFields` for custom handling.
     */
    STPPaymentIntentSetupFutureUsageUnknown,
    
    /**
     No value was provided.
     */
    STPPaymentIntentSetupFutureUsageNone,
    
    /**
     Indicates you intend to only reuse the payment method when the customer is in your checkout flow.
     */
    STPPaymentIntentSetupFutureUsageOnSession,
    
    /**
     Indicates you intend to reuse the payment method when the customer may or may not be in your checkout flow.
     */
    STPPaymentIntentSetupFutureUsageOffSession,
};

#pragma mark - Deprecated

/**
 Types of Actions from a `STPPaymentIntent`, when the payment intent
 status is `STPPaymentIntentStatusRequiresAction`.
 */
__attribute__((deprecated("Use STPIntentActionType instead", "STPIntentActionType")))
typedef NS_ENUM(NSUInteger, STPPaymentIntentActionType)  {
    /**
     This is an unknown action, that's been added since the SDK
     was last updated.
     Update your SDK, or use the `nextAction.allResponseFields`
     for custom handling.
     */
    STPPaymentIntentActionTypeUnknown __attribute__((deprecated("Use STPIntentActionTypeUnknown instead", "STPIntentActionTypeUnknown"))) = STPIntentActionTypeUnknown,
    
    /**
     The payment intent needs to be authorized by the user. We provide
     `STPRedirectContext` to handle the url redirections necessary.
     */
    STPPaymentIntentActionTypeRedirectToURL __attribute__((deprecated("Use STPIntentActionTypeRedirectToURL instead", "STPIntentActionTypeRedirectToURL"))) = STPIntentActionTypeRedirectToURL,
};

/**
 Types of Source Actions from a `STPPaymentIntent`, when the payment intent
 status is `STPPaymentIntentStatusRequiresSourceAction`.
 
 @deprecated Use`STPPaymentIntentActionType` instead.
 */
__attribute__((deprecated("Use STPIntentActionType instead", "STPIntentActionType")))
typedef NS_ENUM(NSUInteger, STPPaymentIntentSourceActionType)  {
    /**
     This is an unknown source action, that's been added since the SDK
     was last updated.
     Update your SDK, or use the `nextSourceAction.allResponseFields`
     for custom handling.
     */
    STPPaymentIntentSourceActionTypeUnknown __attribute__((deprecated("Use STPIntentActionTypeUnknown instead", "STPIntentActionTypeUnknown"))) = STPIntentActionTypeUnknown,

    /**
     The payment intent needs to be authorized by the user. We provide
     `STPRedirectContext` to handle the url redirections necessary.
     */
    STPPaymentIntentSourceActionTypeAuthorizeWithURL __attribute__((deprecated("Use STPIntentActionTypeRedirectToURL instead", "STPIntentActionTypeRedirectToURL"))) = STPIntentActionTypeRedirectToURL,
};



