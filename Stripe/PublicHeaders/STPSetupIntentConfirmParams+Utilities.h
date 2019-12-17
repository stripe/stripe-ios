//
//  STPSetupIntentConfirmParams+Utilities.h
//  Stripe
//
//  Created by Cameron Sabol on 12/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSetupIntentConfirmParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSetupIntentConfirmParams (Utilities)

/**
 Verifies whether the provided client secret matches the expected format.
 Does NOT validate that the client secret represents an actual object in an account.
 */
+ (BOOL)isClientSecretValid:(NSString *)clientSecret;

@end

NS_ASSUME_NONNULL_END
