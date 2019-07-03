//
//  STPSetupIntentEnums.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

/**
 Status types for an STPSetupIntent
 */
typedef NS_ENUM(NSInteger, STPSetupIntentStatus) {
    
    /**
     Unknown status
     */
    STPSetupIntentStatusUnknown,

    /**
     This SetupIntent requires a PaymentMethod
     */
    STPSetupIntentStatusRequiresPaymentMethod,
    
    /**
     This SetupIntent needs to be confirmed
     */
    STPSetupIntentStatusRequiresConfirmation,
    
    /**
     The selected PaymentMethod requires additional authentication steps.
     Additional actions found via the `nextAction` property of `STPSetupIntent`
     */
    STPSetupIntentStatusRequiresAction,
    
    /**
     Stripe is processing this SetupIntent
     */
    STPSetupIntentStatusProcessing,
    
    /**
     The SetupIntent has succeeded
     */
    STPSetupIntentStatusSucceeded,
    
    /**
     This SetupIntent was canceled and cannot be changed.
     */
    STPSetupIntentStatusCanceled,
};

/**
 Indicates how the payment method is intended to be used in the future.
 
 @see https://stripe.com/docs/api/setup_intents/create#create_setup_intent-usage
 */
typedef NS_ENUM(NSInteger, STPSetupIntentUsage) {
    
    /**
     Unknown value.  Update your SDK, or use `allResponseFields` for custom handling.
     */
    STPSetupIntentUsageUnknown,
    
    /**
     No value was provided.
     */
    STPSetupIntentUsageNone,
    
    /**
     Indicates you intend to only reuse the payment method when the customer is in your checkout flow.
     */
    STPSetupIntentUsageOnSession,
    
    /**
     Indicates you intend to reuse the payment method when the customer may or may not be in your checkout flow.
     */
    STPSetupIntentUsageOffSession,
};
