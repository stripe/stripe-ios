//
//  STPPaymentHandlerActionParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentHandlerActionParams.h"

#import "STPAPIClient.h"
#import <Stripe/Stripe3DS2.h>
#import "STPPaymentIntent.h"
#import "STPSetupIntent.h"
#import "STPThreeDSCustomizationSettings.h"
#import "STPThreeDSCustomization+Private.h"

@implementation STPPaymentHandlerPaymentIntentActionParams
{
    BOOL _serviceInitialized;
}

@synthesize threeDS2Service = _threeDS2Service;
@synthesize returnURLString = _returnURLString;

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                    paymentIntent:(STPPaymentIntent *)paymentIntent
                        returnURL:(nullable NSString *)returnURLString
                       completion:(STPPaymentHandlerActionPaymentIntentCompletionBlock)completion {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _authenticationContext = authenticationContext;
        _threeDSCustomizationSettings = threeDSCustomizationSettings;
        _returnURLString = [returnURLString copy];
        _paymentIntent = paymentIntent;
        _paymentIntentCompletion = [completion copy];
    }
    
    return self;
}

- (nullable STDSThreeDS2Service *)threeDS2Service {
    if (!_serviceInitialized) {
        _serviceInitialized = YES;
        _threeDS2Service = [[STDSThreeDS2Service alloc] init];
        @try {
            STDSConfigParameters *configParams = [[STDSConfigParameters alloc] initWithStandardParameters];
            if (self.paymentIntent && !self.paymentIntent.livemode) {
                [configParams addParameterNamed:@"kInternalStripeTestingConfigParam" withValue:@"Y"];
            }
            [_threeDS2Service initializeWithConfig:configParams
                                            locale:[NSLocale autoupdatingCurrentLocale]
                                        uiSettings:_threeDSCustomizationSettings.uiCustomization.uiCustomization];
        } @catch (NSException *e) {
            _threeDS2Service = nil;
        }
    }
    
    return _threeDS2Service;
}

- (STPIntentAction *)nextAction {
    return self.paymentIntent.nextAction;
}

- (NSString *)intentStripeID {
    return self.paymentIntent.stripeId;
}

- (void)completeWithStatus:(STPPaymentHandlerActionStatus)status error:(NSError *)error {
    if (self.paymentIntent) {
        NSAssert(self.paymentIntentCompletion != nil, @"Shouldn't have a nil completion block at this point.");
        self.paymentIntentCompletion(status, self.paymentIntent, error);
    } else {
        NSAssert(NO, @"Missing paymentIntent!");
    }
}

@end

@interface STPPaymentHandlerSetupIntentActionParams()
@property (nonatomic) BOOL serviceInitialized;
@property (nonatomic, nullable) STDSThreeDS2Service *threeDS2Service;
@property (nonatomic, nullable, strong) id<STPAuthenticationContext> authenticationContext;
@property (nonatomic, strong) STPAPIClient *apiClient;
@property (nonatomic, strong) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;

@end

@implementation STPPaymentHandlerSetupIntentActionParams

@synthesize returnURLString = _returnURLString;

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                      setupIntent:(STPSetupIntent *)setupIntent
                        returnURL:(nullable NSString *)returnURLString
                       completion:(STPPaymentHandlerActionSetupIntentCompletionBlock)completion {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _authenticationContext = authenticationContext;
        _threeDSCustomizationSettings = threeDSCustomizationSettings;
        _returnURLString = [returnURLString copy];
        _setupIntent = setupIntent;
        _setupIntentCompletion = [completion copy];
    }
    
    return self;
}

- (nullable STDSThreeDS2Service *)threeDS2Service {
    if (!_serviceInitialized) {
        _serviceInitialized = YES;
        _threeDS2Service = [[STDSThreeDS2Service alloc] init];
        @try {
            STDSConfigParameters *configParams = [[STDSConfigParameters alloc] initWithStandardParameters];
            if (self.setupIntent && !self.setupIntent.livemode) {
                [configParams addParameterNamed:@"kInternalStripeTestingConfigParam" withValue:@"Y"];
            }
            [_threeDS2Service initializeWithConfig:configParams
                                            locale:[NSLocale autoupdatingCurrentLocale]
                                        uiSettings:_threeDSCustomizationSettings.uiCustomization.uiCustomization];
        } @catch (NSException *e) {
            _threeDS2Service = nil;
        }
    }
    
    return _threeDS2Service;
}

- (STPIntentAction *)nextAction {
    return self.setupIntent.nextAction;
}

- (NSString *)intentStripeID {
    return self.setupIntent.stripeID;
}

- (void)completeWithStatus:(STPPaymentHandlerActionStatus)status error:(NSError *)error {
    if (self.setupIntent) {
        NSAssert(self.setupIntentCompletion != nil, @"Shouldn't have a nil completion block at this point.");
        self.setupIntentCompletion(status, self.setupIntent, error);
    } else {
        NSAssert(NO, @"Missing setupIntent!");
    }
}

@end
