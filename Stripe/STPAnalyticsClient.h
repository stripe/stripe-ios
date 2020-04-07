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

+ (NSString *)tokenTypeFromParameters:(NSDictionary *)parameters;

- (void)addClassToProductUsageIfNecessary:(Class)klass;

- (void)addAdditionalInfo:(NSString *)info;

- (void)clearAdditionalInfo;

#pragma mark - Creation
- (void)logTokenCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       tokenType:(NSString *)tokenType;

- (void)logSourceCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       sourceType:(NSString *)sourceType;

- (void)logPaymentMethodCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       paymentMethodType:(NSString *)paymentMethodType;

#pragma mark - Confirmation

- (void)logPaymentIntentConfirmationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                           paymentMethodType:(NSString *)paymentMethodType;

- (void)logSetupIntentConfirmationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                         paymentMethodType:(NSString *)paymentMethodType;

#pragma mark - 3DS2 Flow

- (void)log3DS2AuthenticateAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                           intentID:(NSString *)intentID;

- (void)log3DS2FrictionlessFlowWithConfiguration:(STPPaymentConfiguration *)configuration
                                        intentID:(NSString *)intentID;

- (void)logURLRedirectNextActionWithConfiguration:(STPPaymentConfiguration *)configuration
                                         intentID:(NSString *)intentID;

- (void)log3DS2ChallengeFlowPresentedWithConfiguration:(STPPaymentConfiguration *)configuration
                                              intentID:(NSString *)intentID
                                                uiType:(NSString *)uiType;

- (void)log3DS2ChallengeFlowTimedOutWithConfiguration:(STPPaymentConfiguration *)configuration
                                             intentID:(NSString *)intentID
                                               uiType:(NSString *)uiType;

- (void)log3DS2ChallengeFlowUserCanceledWithConfiguration:(STPPaymentConfiguration *)configuration
                                                 intentID:(NSString *)intentID
                                                   uiType:(NSString *)uiType;

- (void)log3DS2ChallengeFlowCompletedWithConfiguration:(STPPaymentConfiguration *)configuration
                                              intentID:(NSString *)intentID
                                                uiType:(NSString *)uiType;

- (void)log3DS2ChallengeFlowErroredWithConfiguration:(STPPaymentConfiguration *)configuration
                                            intentID:(NSString *)intentID
                                     errorDictionary:(NSDictionary *)errorDictionary;

@end
