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

@interface STPPaymentHandlerActionParams: NSObject

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                    paymentIntent:(STPPaymentIntent *)paymentIntent
                       completion:(STPPaymentHandlerActionPaymentIntentCompletionBlock)completion;

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                    setupIntent:(STPSetupIntent *)setupIntent
                       completion:(STPPaymentHandlerActionSetupIntentCompletionBlock)completion;

@property (nonatomic, nullable, readonly) STDSThreeDS2Service *threeDS2Service;

@property (nonatomic, nullable, readonly, strong) id<STPAuthenticationContext> authenticationContext;
@property (nonatomic, readonly, strong) STPAPIClient *apiClient;
@property (nonatomic, readonly, strong) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;
@property (nonatomic, readonly, copy) STPPaymentHandlerActionPaymentIntentCompletionBlock paymentIntentCompletion;
@property (nonatomic, readonly, copy) STPPaymentHandlerActionSetupIntentCompletionBlock setupIntentCompletion;

// ActionParams can contain either a paymentIntent or a setupIntent
@property (nonatomic, nullable) STPPaymentIntent *paymentIntent;
@property (nonatomic, nullable) STPSetupIntent *setupIntent;

/// Returns the payment or setup intent's next action
- (STPIntentAction *)nextAction;
- (void)completeWithStatus:(STPPaymentHandlerActionStatus)status error:(nullable NSError *)error;
@end

NS_ASSUME_NONNULL_END
