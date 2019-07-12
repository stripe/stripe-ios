//
//  STPPaymentHandlerActionParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPPaymentHandler.h"
#import "STPAuthenticationContext.h"

@class STPAPIClient, STPThreeDSCustomizationSettings, STDSThreeDS2Service, STPSetupIntent, STPIntentAction;

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentHandlerActionParams

@property (nonatomic, nullable, readonly) STDSThreeDS2Service *threeDS2Service;
@property (nonatomic, nullable, readonly, strong) id<STPAuthenticationContext> authenticationContext;
@property (nonatomic, readonly, strong) STPAPIClient *apiClient;
@property (nonatomic, readonly, strong) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;
@property (nonatomic, nullable, readonly) NSString *returnURLString;
@property (nonatomic, readonly) NSString *intentStripeID;
/// Returns the payment or setup intent's next action
- (nullable STPIntentAction *)nextAction;
- (void)completeWithStatus:(STPPaymentHandlerActionStatus)status error:(nullable NSError *)error;

@end

@interface STPPaymentHandlerPaymentIntentActionParams: NSObject <STPPaymentHandlerActionParams>

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                    paymentIntent:(STPPaymentIntent *)paymentIntent
                        returnURL:(nullable NSString *)returnURLString
                       completion:(STPPaymentHandlerActionPaymentIntentCompletionBlock)completion;

@property (nonatomic, nullable, readonly) STDSThreeDS2Service *threeDS2Service;
@property (nonatomic, nullable, readonly, strong) id<STPAuthenticationContext> authenticationContext;
@property (nonatomic, readonly, strong) STPAPIClient *apiClient;
@property (nonatomic, readonly, strong) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;
@property (nonatomic, readonly, copy) STPPaymentHandlerActionPaymentIntentCompletionBlock paymentIntentCompletion;
@property (nonatomic, strong) STPPaymentIntent *paymentIntent;

@end

@interface STPPaymentHandlerSetupIntentActionParams: NSObject <STPPaymentHandlerActionParams>

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                      setupIntent:(STPSetupIntent *)setupIntent
                        returnURL:(nullable NSString *)returnURLString
                       completion:(STPPaymentHandlerActionSetupIntentCompletionBlock)completion;

@property (nonatomic, readonly, copy) STPPaymentHandlerActionSetupIntentCompletionBlock setupIntentCompletion;
@property (nonatomic, strong) STPSetupIntent *setupIntent;
@end

NS_ASSUME_NONNULL_END
