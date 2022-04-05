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
 Dashboard login/pw: fetch mobile-payments-sdk-ci
 */
static NSString * const STPTestingDefaultPublishableKey = @"pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6";
// Test account in Australia
static NSString * const STPTestingAUPublishableKey = @"pk_test_GNmlCJ6AFgWXm4mJYiyWSOWN00KIIiri7F";
// Test account in Mexico
static NSString * const STPTestingMEXPublishableKey = @"pk_test_51GvAY5HNG4o8pO5lDEegY72rkF1TMiMyuTxSFJsmsH7U0KjTwmEf2VuXHVHecil64QA8za8Um2uSsFsfrG0BkzFo00sb1uhblF";
// Test account in SG
static NSString * const STPTestingSGPublishableKey = @"pk_test_51H7oXMAOnZToJom1hqiSvNGsUVTrG1SaXRSBon9xcEp0yDFAxEh5biA4n0ty6paEsD5Mo5ps1b7Taj9WAHQzjup800m8A8Nc3u";
// Test account in Belgium
static NSString * const STPTestingBEPublishableKey = @"pk_test_51HZi0VArGMi59tL4sIXUjwXbMiM5uSHVfsKjNXcepJ80C5niX4bCm5rJ3CeDI1vjZ5Mz55Phsmw9QqjoZTsBFoWh009RQaGx0R";
static NSString * const STPTestingINPublishableKey = @"pk_test_51H7wmsBte6TMTRd4gph9Wm7gnQOKJwdVTCj30AhtB8MhWtlYj6v9xDn1vdCtKYGAE7cybr6fQdbQQtgvzBihE9cl00tOnrTpL9";
// Test account in Brazil
static NSString * const STPTestingBRPublishableKey = @"pk_test_51JYFFjJQVROkWvqT6Hy9pW7uPb6UzxT3aACZ0W3olY8KunzDE9mm6OxE5W2EHcdZk7LxN6xk9zumFbZL8zvNwixR0056FVxQmt";

@interface STPTestingAPIClient : NSObject

+ (instancetype)sharedClient;

// Set this to the Stripe SDK session for SWHTTPRecorder recording to work correctly
@property (nonatomic, readwrite) NSURLSessionConfiguration *sessionConfig;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                              account:(nullable NSString *)account // nil for default or "au" for Australia test account or "mex" for Mexico test account
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                              account:(nullable NSString *)account // nil for default or "au" for Australia test account or "mex" for Mexico test account
                           apiVersion:(nullable NSString *)apiVersion // nil for default or pass with beta headers
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                            account:(nullable NSString *)account // nil for default or "au" for Australia test account or "mex" for Mexico test account
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                            account:(nullable NSString *)account // nil for default or "au" for Australia test account or "mex" for Mexico test account
                         apiVersion:(nullable NSString *)apiVersion // nil for default or pass with beta headers
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
