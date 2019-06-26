//
//  STPPaymentIntentActionUseStripeSDK.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STPPaymentIntentActionUseStripeSDKType) {
    STPPaymentIntentActionUseStripeSDKTypeUnknown = 0,
    STPPaymentIntentActionUseStripeSDKType3DS2Fingerprint,
};

@interface STPPaymentIntentActionUseStripeSDK : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentIntentActionUseStripeSDK`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentActionRedirectToURL.")));

@property (nonatomic, readonly) STPPaymentIntentActionUseStripeSDKType type;

#pragma mark - 3DS2 Fingerprint
@property (nonatomic, nullable, copy, readonly) NSString *directoryServerName;
@property (nonatomic, copy, readonly) NSString *directoryServerID;
/// PEM encoded DS certificate
@property (nonatomic, copy, readonly) NSString *directoryServerCertificate;
/// A Visa-specific field
@property (nonatomic, nullable, copy, readonly) NSString *directoryServerKeyID;

@property (nonatomic, nullable, copy, readonly) NSString *serverTransactionID;
@property (nonatomic, nullable, copy, readonly) NSString *threeDS2SourceID;

@end

NS_ASSUME_NONNULL_END
