//
//  STPTestingAPIClient.h
//  StripeiOS
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const STPTestingDefaultPublishableKey = @"pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6";
// Test account in Australia
static NSString * const STPTestingAUPublishableKey = @"pk_test_GNmlCJ6AFgWXm4mJYiyWSOWN00KIIiri7F";

static const NSTimeInterval STPTestingNetworkRequestTimeout = 8;

@interface STPTestingAPIClient : NSObject

+ (instancetype)sharedClient;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                              account:(nullable NSString *)account // nil for default or "au" for Australia test account
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                            account:(nullable NSString *)account // nil for default or "au" for Australia test account
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
