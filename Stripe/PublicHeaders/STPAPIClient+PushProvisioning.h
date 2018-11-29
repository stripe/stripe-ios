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
                                    completion:(STPPushProvisioningDetailsCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
