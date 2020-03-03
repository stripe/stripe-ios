//
//  STPTestingAPIClient.h
//  StripeiOS
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const STPTestingPublishableKey = @"pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6";
static const NSTimeInterval STPTestingNetworkRequestTimeout = 8;

@interface STPTestingAPIClient : NSObject

+ (instancetype)sharedClient;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
