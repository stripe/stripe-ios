//
//  STPAPIClient+PushProvisioning.h
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPPushProvisioningDetails.h"
#import "STPPushProvisioningDetailsParams.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^STPPushProvisioningDetailsCompletionBlock)(STPPushProvisioningDetails * __nullable details, NSError * __nullable error);

@interface STPAPIClient (PushProvisioning)
    
- (void)retrievePushProvisioningDetailsWithParams:(STPPushProvisioningDetailsParams *)params
                                     ephemeralKey:(STPEphemeralKey *)ephemeralKey
                                       completion:(STPPushProvisioningDetailsCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END

/**
 This function should not be called directly.
 
 It is used by the SDK when it is built as a static library to force the
 compiler to link in category methods regardless of the integrating
 app's compiler flags.
 */
void linkSTPAPIClientPushProvisioningCategory(void);
