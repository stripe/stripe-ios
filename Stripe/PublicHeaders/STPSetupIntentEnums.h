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
