//
//  STPAnalyticsClient.h
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPPaymentConfiguration, STPToken;
@protocol STPFormEncodable;

@interface STPAnalyticsClient : NSObject

+ (instancetype)sharedClient;

+ (void)initializeIfNeeded;

+ (NSString *)tokenTypeFromParameters:(NSDictionary *)parameters;

- (void)addAdditionalInfo:(NSString *)info;

- (void)clearAdditionalInfo;

- (void)logTokenCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       tokenType:(NSString *)tokenType;

- (void)logSourceCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       sourceType:(NSString *)sourceType;

- (void)logPaymentIntentConfirmationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                                  sourceType:(NSString *)sourceType;

- (void)logSetupIntentConfirmationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                         paymentMethodType:(NSString *)paymentMethodType;

- (void)log3DS2AuthenticateAttemptWithConfiguration:(STPPaymentConfiguration *)configuration;

- (void)log3DS2ChallengeFlowPresentedWithConfiguration:(STPPaymentConfiguration *)configuration;

- (void)log3DS2ChallengeFlowErroredWithConfiguration:(STPPaymentConfiguration *)configuration
                                            intentID:(NSString *)intentID
                                     errorDictionary:(NSDictionary *)errorDictionary ;

@end
