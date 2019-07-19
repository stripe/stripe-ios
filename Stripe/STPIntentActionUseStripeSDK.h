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
    STPIntentActionUseStripeSDKType3DS2Redirect,
};

@interface STPIntentActionUseStripeSDK : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPIntentActionUseStripeSDK`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPIntentActionUseStripeSDK.")));

@property (nonatomic, readonly) STPIntentActionUseStripeSDKType type;

#pragma mark - 3DS2 Fingerprint
@property (nonatomic, nullable, copy, readonly) NSString *directoryServerName;
@property (nonatomic, copy, readonly) NSString *directoryServerID;
/// PEM encoded DS certificate
@property (nonatomic, copy, readonly) NSString *directoryServerCertificate;
@property (nonatomic, readonly) NSArray<NSString *> *rootCertificateStrings;
/// A Visa-specific field
@property (nonatomic, nullable, copy, readonly) NSString *directoryServerKeyID;

@property (nonatomic, nullable, copy, readonly) NSString *serverTransactionID;
@property (nonatomic, nullable, copy, readonly) NSString *threeDS2SourceID;

#pragma mark - 3DS2 Redirect
@property (nonatomic, nullable, readonly) NSURL *redirectURL;

@end

NS_ASSUME_NONNULL_END
