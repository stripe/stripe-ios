//
//  STPSetupIntent+Private.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSetupIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSetupIntent ()

/**
 Helper function for extracting SetupIntent id from the Client Secret.
 This avoids having to pass around both the id and the secret.
 
 @param clientSecret The `client_secret` from the SetupIntent
 */
+ (nullable NSString *)idFromClientSecret:(NSString *)clientSecret;

@end

NS_ASSUME_NONNULL_END
