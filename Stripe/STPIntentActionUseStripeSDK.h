//
//  STPIntentActionUseStripeSDK.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STPIntentActionUseStripeSDKType) {
    STPIntentActionUseStripeSDKTypeUnknown = 0,
    STPIntentActionUseStripeSDKType3DS2Fingerprint,
};

@interface STPIntentActionUseStripeSDK : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPIntentActionUseStripeSDK`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPIntentActionUseStripeSDK.")));

@property (nonatomic, readonly) STPIntentActionUseStripeSDKType type;

#pragma mark - 3DS2 Fingerprint
@property (nonatomic, nullable, copy, readonly) NSString *directoryServer;
@property (nonatomic, nullable, copy, readonly) NSString *serverTransactionID;
@property (nonatomic, nullable, copy, readonly) NSString *threeDS2SourceID;

@end

NS_ASSUME_NONNULL_END
