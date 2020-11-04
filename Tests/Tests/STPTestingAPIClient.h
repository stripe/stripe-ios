//
//  STPTestingAPIClient.h
//  StripeiOS
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPEphemeralKey;

NS_ASSUME_NONNULL_BEGIN

/**
 Test account info:
 Account: acct_1G6m1pFY0qyl6XeW
 Dashboard login/pw: mobile-payments-sdk-ci in go/vault
 Heroku login/pw: mobile-payments-sdk-ci-heroku in go/vault
 */
static NSString * const STPTestingDefaultPublishableKey = @"pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6";
// Test account in Australia
static NSString * const STPTestingAUPublishableKey = @"pk_test_GNmlCJ6AFgWXm4mJYiyWSOWN00KIIiri7F";
// Test account in Mexico
static NSString * const STPTestingMEXPublishableKey = @"pk_test_51GvAY5HNG4o8pO5lDEegY72rkF1TMiMyuTxSFJsmsH7U0KjTwmEf2VuXHVHecil64QA8za8Um2uSsFsfrG0BkzFo00sb1uhblF";
// Test account in SG
static NSString * const STPTestingSGPublishableKey = @"pk_test_51H7oXMAOnZToJom1hqiSvNGsUVTrG1SaXRSBon9xcEp0yDFAxEh5biA4n0ty6paEsD5Mo5ps1b7Taj9WAHQzjup800m8A8Nc3u";

static const NSTimeInterval STPTestingNetworkRequestTimeout = 8;

@interface STPTestingAPIClient : NSObject

+ (instancetype)sharedClient;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                              account:(nullable NSString *)account // nil for default or "au" for Australia test account or "mex" for Mexico test account
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                            account:(nullable NSString *)account // nil for default or "au" for Australia test account or "mex" for Mexico test account
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

- (void)createEphemeralKeyWithCompletion:(void (^)(STPEphemeralKey *_Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
