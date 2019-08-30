//
//  STPPaymentHandler.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentHandler.h"

#import <SafariServices/SafariServices.h>
#import <Stripe/Stripe3DS2.h>

#import "NSError+Stripe.h"
#import "STP3DS2AuthenticateResponse.h"
#import "STPAnalyticsClient.h"
#import "STPAPIClient+Private.h"
#import "STPAuthenticationContext.h"
#import "STPPaymentIntent.h"
#import "STPPaymentIntentLastPaymentError.h"
#import "STPPaymentIntentParams.h"
#import "STPPaymentHandlerActionParams.h"
#import "STPIntentAction+Private.h"
#import "STPIntentActionRedirectToURL.h"
#import "STPIntentActionUseStripeSDK.h"
#import "STPSetupIntent.h"
#import "STPSetupIntentConfirmParams.h"
#import "STPSetupIntentLastSetupError.h"
#import "STPThreeDSCustomizationSettings.h"
#import "STPThreeDSCustomization+Private.h"
#import "STPURLCallbackHandler.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const STPPaymentHandlerErrorDomain = @"STPPaymentHandlerErrorDomain";

@interface STPPaymentHandler () <SFSafariViewControllerDelegate, STPURLCallbackListener, STDSChallengeStatusReceiver>
{
    NSObject<STPPaymentHandlerActionParams> *_currentAction;
}
/// YES from when a public method is first called until its associated completion handler is called.
@property (nonatomic, getter=isInProgress) BOOL inProgress;
@property (nonatomic, nullable) SFSafariViewController *safariViewController;

@end

@implementation STPPaymentHandler

+ (instancetype)sharedHandler {
    static STPPaymentHandler *sharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHandler = [self new];
        sharedHandler->_apiClient = [STPAPIClient sharedClient];
        sharedHandler.threeDSCustomizationSettings = [STPThreeDSCustomizationSettings defaultSettings];
    });

    return sharedHandler;
}

- (void)confirmPayment:(STPPaymentIntentParams *)paymentParams
withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
            completion:(STPPaymentHandlerActionPaymentIntentCompletionBlock)completion {
    if (self.isInProgress) {
        completion(STPPaymentHandlerActionStatusFailed, nil, [self _errorForCode:STPPaymentHandlerNoConcurrentActionsErrorCode userInfo:nil]);
        return;
    }
    self.inProgress = YES;
    __weak __typeof(self) weakSelf = self;
    // wrappedCompletion ensures we perform some final logic before calling the completion block.
    STPPaymentHandlerActionPaymentIntentCompletionBlock wrappedCompletion = ^(STPPaymentHandlerActionStatus status, STPPaymentIntent *paymentIntent, NSError *error) {
        __typeof(self) strongSelf = weakSelf;
        // Reset our internal state
        strongSelf.inProgress = NO;
        // Ensure the .succeeded case returns a PaymentIntent in the expected state.
        if (status == STPPaymentHandlerActionStatusSucceeded) {
            if (error == nil && paymentIntent != nil && (paymentIntent.status == STPPaymentIntentStatusSucceeded || paymentIntent.status == STPPaymentIntentStatusRequiresCapture)) {
                completion(STPPaymentHandlerActionStatusSucceeded, paymentIntent, nil);
            } else {
                NSAssert(NO, @"Calling completion with invalid state");
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, error ?: [strongSelf _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:nil]);
            }
            return;
        }
        completion(status, paymentIntent, error);
    };
    STPPaymentIntentCompletionBlock confirmCompletionBlock = ^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
        __typeof(self) strongSelf = weakSelf;
        if (error) {
            wrappedCompletion(STPPaymentHandlerActionStatusFailed, paymentIntent, error);
        } else {
            [strongSelf _handleNextActionForPayment:paymentIntent
                          withAuthenticationContext:authenticationContext
                                          returnURL:paymentParams.returnURL
                                         completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent *completedPaymentIntent, NSError *completedError) {
                                             wrappedCompletion(status, completedPaymentIntent, completedError);
                                         }];
        }
    };
    STPPaymentIntentParams *params = paymentParams;
    // We always set useStripeSDK = @YES in STPPaymentHandler
    if (!params.useStripeSDK.boolValue) {
        params = [paymentParams copy];
        params.useStripeSDK = @YES;
    }
    [self.apiClient confirmPaymentIntentWithParams:params
                                        completion:confirmCompletionBlock];
}

- (void)handleNextActionForPayment:(NSString *)paymentIntentClientSecret
         withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                         returnURL:(nullable NSString *)returnURL
                        completion:(STPPaymentHandlerActionPaymentIntentCompletionBlock)completion{
    if (self.isInProgress) {
        NSAssert(NO, @"Should not handle multiple payments at once.");
        completion(STPPaymentHandlerActionStatusFailed, nil, [self _errorForCode:STPPaymentHandlerNoConcurrentActionsErrorCode userInfo:nil]);
        return;
    }
    self.inProgress = YES;
    __weak __typeof(self) weakSelf = self;
    // wrappedCompletion ensures we perform some final logic before calling the completion block.
    STPPaymentHandlerActionPaymentIntentCompletionBlock wrappedCompletion = ^(STPPaymentHandlerActionStatus status, STPPaymentIntent *paymentIntent, NSError *error) {
        __typeof(self) strongSelf = weakSelf;
        // Reset our internal state
        strongSelf.inProgress = NO;
        // Ensure the .succeeded case returns a PaymentIntent in the expected state.
        if (status == STPPaymentHandlerActionStatusSucceeded) {
            if (error == nil && paymentIntent != nil && (paymentIntent.status == STPPaymentIntentStatusSucceeded || paymentIntent.status == STPPaymentIntentStatusRequiresCapture || paymentIntent.status == STPPaymentIntentStatusRequiresConfirmation)) {
                completion(STPPaymentHandlerActionStatusSucceeded, paymentIntent, nil);
            } else {
                NSAssert(NO, @"Calling completion with invalid state");
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, error ?: [strongSelf _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:nil]);
            }
            return;
        }
        completion(status, paymentIntent, error);
    };

    STPPaymentIntentCompletionBlock retrieveCompletionBlock = ^(STPPaymentIntent *paymentIntent, NSError *error) {
        __typeof(self) strongSelf = weakSelf;
        if (error) {
            wrappedCompletion(STPPaymentHandlerActionStatusFailed, paymentIntent, error);
        } else {
            if (paymentIntent.status == STPPaymentIntentStatusRequiresConfirmation) {
                // The caller forgot to confirm the paymentIntent on the backend before calling this method
                wrappedCompletion(STPPaymentHandlerActionStatusFailed, paymentIntent, [strongSelf _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:@{STPErrorMessageKey: @"Confirm the PaymentIntent on the backend before calling handleNextActionForPayment:withAuthenticationContext:completion."}]);
            }
            [strongSelf _handleNextActionForPayment:paymentIntent
                          withAuthenticationContext:authenticationContext
                                          returnURL:returnURL
                                         completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent *completedPaymentIntent, NSError *completedError) {
                                             wrappedCompletion(status, completedPaymentIntent, completedError);
                                         }];
        }
    };
    
    [self.apiClient retrievePaymentIntentWithClientSecret:paymentIntentClientSecret completion:retrieveCompletionBlock];
}

- (void)confirmSetupIntent:(STPSetupIntentConfirmParams *)setupIntentConfirmParams
 withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                completion:(STPPaymentHandlerActionSetupIntentCompletionBlock)completion {
    if (self.isInProgress) {
        NSAssert(NO, @"Should not handle multiple payments at once.");
        completion(STPPaymentHandlerActionStatusFailed, nil, [self _errorForCode:STPPaymentHandlerNoConcurrentActionsErrorCode userInfo:nil]);
        return;
    }
    self.inProgress = YES;
    __weak __typeof(self) weakSelf = self;
    // wrappedCompletion ensures we perform some final logic before calling the completion block.
    STPPaymentHandlerActionSetupIntentCompletionBlock wrappedCompletion = ^(STPPaymentHandlerActionStatus status, STPSetupIntent *setupIntent, NSError *error) {
        __typeof(self) strongSelf = weakSelf;
        // Reset our internal state
        weakSelf.inProgress = NO;
        // Ensure the .succeeded case returns a PaymentIntent in the expected state.
        if (status == STPPaymentHandlerActionStatusSucceeded) {
            if (error == nil && setupIntent != nil && setupIntent.status == STPSetupIntentStatusSucceeded) {
                completion(STPPaymentHandlerActionStatusSucceeded, setupIntent, nil);
            } else {
                NSAssert(NO, @"Calling completion with invalid state");
                completion(STPPaymentHandlerActionStatusFailed, setupIntent, error ?: [strongSelf _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:nil]);
            }
            return;
        }
        completion(status, setupIntent, error);
    };

    STPSetupIntentCompletionBlock confirmCompletionBlock = ^(STPSetupIntent * _Nullable setupIntent, NSError * _Nullable error) {
        if (error) {
            wrappedCompletion(STPPaymentHandlerActionStatusFailed, setupIntent, error);
        } else {
            STPPaymentHandlerSetupIntentActionParams *action = [[STPPaymentHandlerSetupIntentActionParams alloc] initWithAPIClient:self.apiClient
                                                                                                             authenticationContext:authenticationContext
                                                                                                      threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                                                                       setupIntent:setupIntent
                                                                                                                         returnURL:setupIntentConfirmParams.returnURL
                                                                                                                        completion:^(STPPaymentHandlerActionStatus status, STPSetupIntent * _Nullable resultSetupIntent, NSError * _Nullable resultError) {
                                                                                                                            __typeof(self) strongSelf = weakSelf;
                                                                                                                            if (strongSelf != nil) {
                                                                                                                                strongSelf->_currentAction = nil;
                                                                                                                            }
                                                                                                                            wrappedCompletion(status, resultSetupIntent, resultError);
                                                                                                                        }];
            self->_currentAction = action;
            BOOL requiresAction = [self _handleSetupIntentStatusForAction:action];
            if (requiresAction) {
                [self _handleAuthenticationForCurrentAction];
            }
        }
    };
    STPSetupIntentConfirmParams *params = setupIntentConfirmParams;
    if (!params.useStripeSDK.boolValue) {
        params = [setupIntentConfirmParams copy];
        params.useStripeSDK = @YES;
    }
    [self.apiClient confirmSetupIntentWithParams:params completion:confirmCompletionBlock];
}

- (void)handleNextActionForSetupIntent:(NSString *)setupIntentClientSecret
             withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                             returnURL:(nullable NSString *)returnURL
                            completion:(STPPaymentHandlerActionSetupIntentCompletionBlock)completion {
    if (self.isInProgress) {
        NSAssert(NO, @"Should not handle multiple payments at once.");
        completion(STPPaymentHandlerActionStatusFailed, nil, [self _errorForCode:STPPaymentHandlerNoConcurrentActionsErrorCode userInfo:nil]);
        return;
    }
    self.inProgress = YES;
    __weak __typeof(self) weakSelf = self;
    // wrappedCompletion ensures we perform some final logic before calling the completion block.
    STPPaymentHandlerActionSetupIntentCompletionBlock wrappedCompletion = ^(STPPaymentHandlerActionStatus status, STPSetupIntent *setupIntent, NSError *error) {
        __typeof(self) strongSelf = weakSelf;
        // Reset our internal state
        weakSelf.inProgress = NO;
        // Ensure the .succeeded case returns a SetupIntent in the expected state.
        if (status == STPPaymentHandlerActionStatusSucceeded) {
            if (error == nil && setupIntent != nil && setupIntent.status == STPSetupIntentStatusSucceeded) {
                completion(STPPaymentHandlerActionStatusSucceeded, setupIntent, nil);
            } else {
                NSAssert(NO, @"Calling completion with invalid state");
                completion(STPPaymentHandlerActionStatusFailed, setupIntent, error ?: [strongSelf _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:nil]);
            }
            return;
        }
        completion(status, setupIntent, error);
    };

    STPSetupIntentCompletionBlock retrieveCompletionBlock = ^(STPSetupIntent * _Nullable setupIntent, NSError * _Nullable error) {

        __typeof(self) strongSelf = weakSelf;
        if (error) {
            wrappedCompletion(STPPaymentHandlerActionStatusFailed, setupIntent, error);
        } else {
            if (setupIntent.status == STPSetupIntentStatusRequiresConfirmation) {
                // The caller forgot to confirm the setupIntent on the backend before calling this method
                wrappedCompletion(STPPaymentHandlerActionStatusFailed, setupIntent, [strongSelf _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:@{STPErrorMessageKey: @"Confirm the SetupIntent on the backend before calling handleNextActionForSetupIntent:withAuthenticationContext:completion."}]);
            }
            [strongSelf _handleNextActionForSetupIntent:setupIntent
                          withAuthenticationContext:authenticationContext
                                          returnURL:returnURL
                                         completion:^(STPPaymentHandlerActionStatus status, STPSetupIntent *completedSetupIntent, NSError *completedError) {
                                             wrappedCompletion(status, completedSetupIntent, completedError);
                                         }];
        }
    };

    [self.apiClient retrieveSetupIntentWithClientSecret:setupIntentClientSecret completion:retrieveCompletionBlock];
}


#pragma mark - Private Helpers

- (void)_handleNextActionForPayment:(STPPaymentIntent *)paymentIntent
          withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                          returnURL:(nullable NSString *)returnURLString
                         completion:(STPPaymentHandlerActionPaymentIntentCompletionBlock)completion {
    if (paymentIntent.status == STPPaymentIntentStatusRequiresPaymentMethod) {
        // The caller forgot to attach a paymentMethod.
        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerRequiresPaymentMethodErrorCode userInfo:nil]);
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    STPPaymentHandlerPaymentIntentActionParams *action = [[STPPaymentHandlerPaymentIntentActionParams alloc] initWithAPIClient:self.apiClient
                                                                                                         authenticationContext:authenticationContext
                                                                                                  threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                                                                 paymentIntent:paymentIntent
                                                                                                                     returnURL:returnURLString
                                                                                                                    completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * _Nullable resultPaymentIntent, NSError * _Nullable error) {
                                                                                                                        __typeof(self) strongSelf = weakSelf;
                                                                                                                        if (strongSelf != nil) {
                                                                                                                            strongSelf->_currentAction = nil;
                                                                                                                        }
                                                                                                                        completion(status, resultPaymentIntent, error);
                                                                                                                    }];
    _currentAction = action;
    BOOL requiresAction = [self _handlePaymentIntentStatusForAction:action];
    if (requiresAction) {
        [self _handleAuthenticationForCurrentAction];
    }
}

- (void)_handleNextActionForSetupIntent:(STPSetupIntent *)setupIntent
              withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                              returnURL:(nullable NSString *)returnURLString
                             completion:(STPPaymentHandlerActionSetupIntentCompletionBlock)completion {
    if (setupIntent.status == STPSetupIntentStatusRequiresPaymentMethod) {
        // The caller forgot to attach a paymentMethod.
        completion(STPPaymentHandlerActionStatusFailed, setupIntent, [self _errorForCode:STPPaymentHandlerRequiresPaymentMethodErrorCode userInfo:nil]);
        return;
    }

    __weak __typeof(self) weakSelf = self;
    STPPaymentHandlerSetupIntentActionParams *action = [[STPPaymentHandlerSetupIntentActionParams alloc] initWithAPIClient:self.apiClient
                                                                                                     authenticationContext:authenticationContext
                                                                                              threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                                                               setupIntent:setupIntent
                                                                                                                 returnURL:returnURLString
                                                                                                                completion:^(STPPaymentHandlerActionStatus status, STPSetupIntent * _Nullable resultSetupIntent, NSError * _Nullable resultError) {
                                                                                                                    __typeof(self) strongSelf = weakSelf;
                                                                                                                    if (strongSelf != nil) {
                                                                                                                        strongSelf->_currentAction = nil;
                                                                                                                    }
                                                                                                                    completion(status, resultSetupIntent, resultError);
                                                                                                                }];
    _currentAction = action;
    BOOL requiresAction = [self _handleSetupIntentStatusForAction:action];
    if (requiresAction) {
        [self _handleAuthenticationForCurrentAction];
    }
}

/// Calls the current action's completion handler for the SetupIntent status, or returns YES if the status is ...RequiresAction.
- (BOOL)_handleSetupIntentStatusForAction:(STPPaymentHandlerSetupIntentActionParams *)action {
    STPSetupIntent *setupIntent = action.setupIntent;
    if (setupIntent == nil) {
        NSAssert(setupIntent != nil, @"setupIntent should never be nil here.");
        [action completeWithStatus:STPPaymentHandlerActionStatusFailed error:[NSError stp_genericFailedToParseResponseError]];
        return NO;
    }
    switch (setupIntent.status) {
        case STPSetupIntentStatusUnknown:
           [action completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:@{@"STPSetupIntent": setupIntent.description}]];
        case STPSetupIntentStatusRequiresPaymentMethod:
            // If the user forgot to attach a PaymentMethod, they get an error before this point.
            // If confirmation fails (eg not authenticated, card declined) the SetupIntent transitions to this state.
            if ([setupIntent.lastSetupError.code isEqualToString:STPSetupIntentLastSetupErrorCodeAuthenticationFailure]) {
                [action completeWithStatus:STPPaymentHandlerActionStatusFailed
                                     error:[self _errorForCode:STPPaymentHandlerNotAuthenticatedErrorCode userInfo:nil]];
            } else if (setupIntent.lastSetupError.type == STPSetupIntentLastSetupErrorTypeCard) {
                [action completeWithStatus:STPPaymentHandlerActionStatusFailed
                                     error:[self _errorForCode:STPPaymentHandlerPaymentErrorCode userInfo:@{NSLocalizedDescriptionKey: setupIntent.lastSetupError.message}]];
            } else {
                [action completeWithStatus:STPPaymentHandlerActionStatusFailed
                                     error:[self _errorForCode:STPPaymentHandlerPaymentErrorCode userInfo:nil]];
            }
            break;
        case STPSetupIntentStatusRequiresConfirmation:
            [action completeWithStatus:STPPaymentHandlerActionStatusSucceeded error:nil];
            break;
        case STPSetupIntentStatusRequiresAction:
            return YES;
        case STPSetupIntentStatusProcessing:
            [action completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:nil]];
            break;
        case STPSetupIntentStatusSucceeded:
            [action completeWithStatus:STPPaymentHandlerActionStatusSucceeded error:nil];
            break;
        case STPSetupIntentStatusCanceled:
            [action completeWithStatus:STPPaymentHandlerActionStatusCanceled error:nil];
            break;
    }
    return NO;
}

/// Calls the current action's completion handler for the PaymentIntent status, or returns YES if the status is ...RequiresAction.
- (BOOL)_handlePaymentIntentStatusForAction:(STPPaymentHandlerPaymentIntentActionParams *)action {
    STPPaymentIntent *paymentIntent = action.paymentIntent;
    if (paymentIntent == nil) {
        NSAssert(paymentIntent != nil, @"paymentIntent should never be nil here.");
        [_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[NSError stp_genericFailedToParseResponseError]];
        return NO;
    }
    switch (paymentIntent.status) {

        case STPPaymentIntentStatusUnknown:
            [action completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:@{@"STPPaymentIntent": paymentIntent.description}]];
            break;

        case STPPaymentIntentStatusRequiresPaymentMethod:
            // If the user forgot to attach a PaymentMethod, they get an error before this point.
            // If confirmation fails (eg not authenticated, card declined) the PaymentIntent transitions to this state.
            if ([paymentIntent.lastPaymentError.code isEqualToString:STPPaymentIntentLastPaymentErrorCodeAuthenticationFailure]) {
                [action completeWithStatus:STPPaymentHandlerActionStatusFailed
                                     error:[self _errorForCode:STPPaymentHandlerNotAuthenticatedErrorCode userInfo:nil]];
            } else if (paymentIntent.lastPaymentError.type == STPPaymentIntentLastPaymentErrorTypeCard) {
                [action completeWithStatus:STPPaymentHandlerActionStatusFailed
                                     error:[self _errorForCode:STPPaymentHandlerPaymentErrorCode userInfo:@{NSLocalizedDescriptionKey: paymentIntent.lastPaymentError.message}]];
            } else {
                [action completeWithStatus:STPPaymentHandlerActionStatusFailed
                                     error:[self _errorForCode:STPPaymentHandlerPaymentErrorCode userInfo:nil]];
            }
            break;
        case STPPaymentIntentStatusRequiresConfirmation:
            [action completeWithStatus:STPPaymentHandlerActionStatusSucceeded error:nil];
            break;
        case STPPaymentIntentStatusRequiresAction:
            return YES;
        case STPPaymentIntentStatusProcessing:
            [action completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerIntentStatusErrorCode userInfo:nil]];
            break;
        case STPPaymentIntentStatusSucceeded:
            [action completeWithStatus:STPPaymentHandlerActionStatusSucceeded error:nil];
            break;
        case STPPaymentIntentStatusRequiresCapture:
            [action completeWithStatus:STPPaymentHandlerActionStatusSucceeded error:nil];
            break;
        case STPPaymentIntentStatusCanceled:
            [action completeWithStatus:STPPaymentHandlerActionStatusCanceled error:nil];
            break;
        }
    return NO;
}

- (void)_handleAuthenticationForCurrentAction {
    STPIntentAction *authenticationAction = _currentAction.nextAction;

    switch (authenticationAction.type) {

        case STPIntentActionTypeUnknown:
            [_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerUnsupportedAuthenticationErrorCode userInfo:@{@"STPIntentAction": authenticationAction.description}]];
            break;
        case STPIntentActionTypeRedirectToURL: {
            NSURL *url = authenticationAction.redirectToURL.url;
            NSURL *returnURL = authenticationAction.redirectToURL.returnURL;
            [self _handleRedirectToURL:url withReturnURL:returnURL];
            break;
        }
        case STPIntentActionTypeUseStripeSDK:
            switch (authenticationAction.useStripeSDK.type) {
                case STPIntentActionUseStripeSDKTypeUnknown:
                    [_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerUnsupportedAuthenticationErrorCode userInfo:@{@"STPIntentActionUseStripeSDK": authenticationAction.useStripeSDK.description}]];
                    break;

                case STPIntentActionUseStripeSDKType3DS2Fingerprint: {
                    STDSThreeDS2Service *threeDSService = _currentAction.threeDS2Service;
                    if (threeDSService == nil) {
                        [_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerStripe3DS2ErrorCode userInfo:@{@"description": @"Failed to initialize STDSThreeDS2Service."}]];
                        return;
                    }

                    STDSTransaction *transaction = nil;
                    STDSAuthenticationRequestParameters *authRequestParams = nil;
                    @try {
                        transaction = [threeDSService createTransactionForDirectoryServer:authenticationAction.useStripeSDK.directoryServerID
                                                                              serverKeyID:authenticationAction.useStripeSDK.directoryServerKeyID
                                                                        certificateString:authenticationAction.useStripeSDK.directoryServerCertificate
                                                                   rootCertificateStrings:authenticationAction.useStripeSDK.rootCertificateStrings
                                                                      withProtocolVersion:@"2.1.0"];

                        authRequestParams = [transaction createAuthenticationRequestParameters];

                    } @catch (NSException *exception) {
                        [_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerStripe3DS2ErrorCode userInfo:@{@"exception": exception.description}]];
                    }

                    [[STPAnalyticsClient sharedClient] log3DS2AuthenticateAttemptWithConfiguration:_currentAction.apiClient.configuration
                                                                                          intentID:_currentAction.intentStripeID];
                    
                    [_currentAction.apiClient authenticate3DS2:authRequestParams
                                              sourceIdentifier:authenticationAction.useStripeSDK.threeDS2SourceID
                                                     returnURL:_currentAction.returnURLString
                                                    maxTimeout:_currentAction.threeDSCustomizationSettings.authenticationTimeout
                                                    completion:^(STP3DS2AuthenticateResponse * _Nullable authenticateResponse, NSError * _Nullable error) {
                                                        if (authenticateResponse == nil) {
                                                            [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:error];
                                                        } else {
                                                            id<STDSAuthenticationResponse> aRes = authenticateResponse.authenticationResponse;
                                                            
                                                            if (aRes == nil && authenticateResponse.fallbackURL != nil) {
                                                                NSURL *returnURL = (self->_currentAction.returnURLString != nil) ? [NSURL URLWithString:self->_currentAction.returnURLString] : nil;
                                                                [self _handleRedirectToURL:authenticateResponse.fallbackURL withReturnURL:returnURL];
                                                                return;
                                                            }

                                                            if (!aRes.isChallengeMandated) {
                                                                // Challenge not required, finish the flow.
                                                                [transaction close];
                                                                [[STPAnalyticsClient sharedClient] log3DS2FrictionlessFlowWithConfiguration:self->_currentAction.apiClient.configuration
                                                                 intentID:self->_currentAction.intentStripeID];
                                                                [self _retrieveAndCheckIntentForCurrentAction];
                                                                return;
                                                            }
                                                            STDSChallengeParameters *challengeParameters = [[STDSChallengeParameters alloc] initWithAuthenticationResponse:aRes];
                                                            
                                                            STPVoidBlock doChallenge = ^{
                                                                NSError *presentationError;
                                                                if (![self _canPresentWithAuthenticationContext:self->_currentAction.authenticationContext error:&presentationError]) {
                                                                    [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:presentationError];
                                                                    return;
                                                                }

                                                                @try {
                                                                    [transaction doChallengeWithViewController:[self->_currentAction.authenticationContext authenticationPresentingViewController]
                                                                                           challengeParameters:challengeParameters
                                                                                       challengeStatusReceiver:self
                                                                                                       timeout:self->_currentAction.threeDSCustomizationSettings.authenticationTimeout*60];
                                                                    
                                                                } @catch (NSException *exception) {
                                                                    [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerStripe3DS2ErrorCode  userInfo:@{@"exception": exception}]];
                                                                }
                                                            };
                                                            if ([self->_currentAction.authenticationContext respondsToSelector:@selector(prepareAuthenticationContextForPresentation:)]) {
                                                                [self->_currentAction.authenticationContext prepareAuthenticationContextForPresentation:doChallenge];
                                                            } else {
                                                                doChallenge();
                                                            }
                                                        }
                                                    }];
                }
                    break;
                case STPIntentActionUseStripeSDKType3DS2Redirect: {
                    NSURL *url = authenticationAction.useStripeSDK.redirectURL;
                    NSURL *returnURL = nil;
                    NSString *returnURLString = _currentAction.returnURLString;
                    if (returnURLString != nil) {
                        returnURL = [NSURL URLWithString:returnURLString];
                    }
                    [self _handleRedirectToURL:url withReturnURL:returnURL];
                }
                    break;
            }
            break;
    }
}

- (void)_retrieveAndCheckIntentForCurrentAction {
    if ([_currentAction isKindOfClass:[STPPaymentHandlerPaymentIntentActionParams class]]) {
        STPPaymentHandlerPaymentIntentActionParams *currentAction = (STPPaymentHandlerPaymentIntentActionParams *)_currentAction;
        [_currentAction.apiClient retrievePaymentIntentWithClientSecret:currentAction.paymentIntent.clientSecret
                                                             completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                                                 if (error != nil) {
                                                                     [currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:error];
                                                                 } else {
                                                                     currentAction.paymentIntent = paymentIntent;
                                                                     BOOL requiresAction = [self _handlePaymentIntentStatusForAction:currentAction];
                                                                     if (requiresAction) {
                                                                         // If the status is still RequiresAction, the user exited from the redirect before the
                                                                         // payment intent was updated. Consider it a cancel
                                                                         [currentAction completeWithStatus:STPPaymentHandlerActionStatusCanceled error:nil];
                                                                     }
                                                                 }
                                                             }];
    } else if ([_currentAction isKindOfClass:[STPPaymentHandlerSetupIntentActionParams class]]) {
        STPPaymentHandlerSetupIntentActionParams *currentAction = (STPPaymentHandlerSetupIntentActionParams *)_currentAction;
        [_currentAction.apiClient retrieveSetupIntentWithClientSecret:currentAction.setupIntent.clientSecret
                                                           completion:^(STPSetupIntent * _Nullable setupIntent, NSError * _Nullable error) {
                                                               if (error != nil) {
                                                                   [currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:error];
                                                               } else {
                                                                   currentAction.setupIntent = setupIntent;
                                                                   BOOL requiresAction = [self _handleSetupIntentStatusForAction:currentAction];
                                                                   if (requiresAction) {
                                                                       // If the status is still RequiresAction, the user exited from the redirect before the
                                                                       // setup intent was updated. Consider it a cancel
                                                                       [currentAction completeWithStatus:STPPaymentHandlerActionStatusCanceled error:nil];
                                                                   }
                                                               }
                                                           }];
        
    } else {
        NSAssert(NO, @"currentAction is an unknown type or nil.");
    }
}

- (void)_handleWillForegroundNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self _retrieveAndCheckIntentForCurrentAction];
}

- (void)_handleRedirectToURL:(NSURL *)url withReturnURL:(nullable NSURL *)returnURL {
    if (returnURL != nil) {
        [[STPURLCallbackHandler shared] registerListener:self forURL:returnURL];
    }

    [[STPAnalyticsClient sharedClient] logURLRedirectNextActionWithConfiguration:_currentAction.apiClient.configuration
                                                                        intentID:_currentAction.intentStripeID];
    void (^presentSFViewControllerBlock)(void) = ^{
        id<STPAuthenticationContext> context = self->_currentAction.authenticationContext;
        UIViewController *presentingViewController = [context authenticationPresentingViewController];

        STPVoidBlock doChallenge = ^{
            NSError *presentationError;
            if (![self _canPresentWithAuthenticationContext:context error:&presentationError]) {
                [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:presentationError];
                return;
            }

            SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
            if (@available(iOS 11, *)) {
                safariViewController.dismissButtonStyle = SFSafariViewControllerDismissButtonStyleClose;
            }
            if ([context respondsToSelector:@selector(configureSafariViewController:)]) {
                [context configureSafariViewController:safariViewController];
            }
            safariViewController.delegate = self;
            self.safariViewController = safariViewController;
            [presentingViewController presentViewController:safariViewController animated:YES completion:nil];
        };
        if ([context respondsToSelector:@selector(prepareAuthenticationContextForPresentation:)]) {
            [context prepareAuthenticationContextForPresentation:doChallenge];
        } else {
            doChallenge();
        }
    };

    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:url
                                           options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @(YES)}
                                 completionHandler:^(BOOL success){
                                     if (!success) {
                                         // no app installed, launch safari view controller
                                         presentSFViewControllerBlock();
                                     } else {
                                         [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                  selector:@selector(_handleWillForegroundNotification)
                                                                                      name:UIApplicationWillEnterForegroundNotification
                                                                                    object:nil];
                                     }
                                 }];
    } else {
        presentSFViewControllerBlock();
    }
}

/**
 Checks if authenticationContext.authenticationPresentingViewController can be presented on.
 
 @note Call this method after `prepareAuthenticationContextForPresentation:`
 */
- (BOOL)_canPresentWithAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext error:(NSError **)error {
    UIViewController *presentingViewController = authenticationContext.authenticationPresentingViewController;
    BOOL canPresent = YES;
    NSString *errorMessage;
    
    // Is presentingViewController non-nil?
    if (presentingViewController == nil) {
        canPresent = NO;
        errorMessage = @"authenticationPresentingViewController is nil.";
    }

    // Is it in the window hierarchy?
    if (presentingViewController.viewIfLoaded.window == nil) {
        canPresent = NO;
        errorMessage = @"authenticationPresentingViewController is not in the window hierarchy. You should probably return the top-most view controller instead.";
    }
    
    // Is it the Apple Pay VC?
    if ([presentingViewController isKindOfClass:[PKPaymentAuthorizationViewController class]]) {
        // We can't present over Apple Pay, user must implement prepareAuthenticationContextForPresentation: to dismiss it.
        canPresent = NO;
        errorMessage = @"authenticationPresentingViewController is a PKPaymentAuthorizationViewController, which cannot be presented over. Dismiss it in `prepareAuthenticationContextForPresentation:`. You should probably return the UIViewController that presented the PKPaymentAuthorizationViewController in `authenticationPresentingViewController` instead.";
    }
    
    // Is it already presenting something?
    if (presentingViewController.presentedViewController != nil) {
        canPresent = NO;
        errorMessage = @"authenticationPresentingViewController is already presenting. You should probably dismiss the presented view controller in `prepareAuthenticationContextForPresentation`.";
    }
    
    if (!canPresent && error) {
        *error = [self _errorForCode:STPPaymentHandlerRequiresAuthenticationContextErrorCode userInfo:errorMessage ? @{STPErrorMessageKey: errorMessage} : nil];
    }
    return canPresent;
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController * __unused)controller {
    self.safariViewController = nil;
    [[STPURLCallbackHandler shared] unregisterListener:self];
    [self _retrieveAndCheckIntentForCurrentAction];
}

#pragma mark - STPURLCallbackListener

- (BOOL)handleURLCallback:(NSURL * __unused)url {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[STPURLCallbackHandler shared] unregisterListener:self];
    [self.safariViewController dismissViewControllerAnimated:YES completion:^{
        self.safariViewController = nil;
    }];
    [self _retrieveAndCheckIntentForCurrentAction];
    return YES;
}

#pragma mark - STPChallengeStatusReceiver

- (void)transaction:(STDSTransaction *)transaction didCompleteChallengeWithCompletionEvent:(STDSCompletionEvent *)completionEvent {
    NSString *transactionStatus = completionEvent.transactionStatus;
    [[STPAnalyticsClient sharedClient] log3DS2ChallengeFlowCompletedWithConfiguration:_currentAction.apiClient.configuration
                                                                             intentID:_currentAction.intentStripeID
                                                                               uiType:transaction.presentedChallengeUIType];
    if ([transactionStatus isEqualToString:@"Y"]) {
        [self _markChallengeCompletedWithCompletion:^(BOOL markedCompleted, NSError * _Nullable error) {
            [self->_currentAction completeWithStatus:markedCompleted ? STPPaymentHandlerActionStatusSucceeded : STPPaymentHandlerActionStatusFailed error:error];
        }];

    } else {
        // going to ignore the rest of the status types because they provide more detail than we require
        [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
            [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerNotAuthenticatedErrorCode userInfo:@{@"transaction_status": transactionStatus}]];
        }];
    }
}

- (void)transactionDidCancel:(STDSTransaction *)transaction {
    [[STPAnalyticsClient sharedClient] log3DS2ChallengeFlowUserCanceledWithConfiguration:_currentAction.apiClient.configuration
                                                                                intentID:_currentAction.intentStripeID
                                                                                  uiType:transaction.presentedChallengeUIType];
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusCanceled error:nil];
    }];
}

- (void)transactionDidTimeOut:(STDSTransaction *)transaction {
    [[STPAnalyticsClient sharedClient] log3DS2ChallengeFlowTimedOutWithConfiguration:_currentAction.apiClient.configuration
                                                                            intentID:_currentAction.intentStripeID
                                                                              uiType:transaction.presentedChallengeUIType];
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:[self _errorForCode:STPPaymentHandlerTimedOutErrorCode userInfo:nil]];
    }];

}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithProtocolErrorEvent:(STDSProtocolErrorEvent *)protocolErrorEvent {

    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        // Add localizedError to the 3DS2 SDK error
        NSError *threeDSError = [protocolErrorEvent.errorMessage NSErrorValue];
        NSMutableDictionary *userInfo = [threeDSError.userInfo mutableCopy];
        userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
        NSError *localizedError = [NSError errorWithDomain:threeDSError.domain code:threeDSError.code userInfo:userInfo];
        [[STPAnalyticsClient sharedClient] log3DS2ChallengeFlowErroredWithConfiguration:self->_currentAction.apiClient.configuration
                                                                               intentID:self->_currentAction.intentStripeID
                                                                        errorDictionary:@{
                                                                                          @"domain": threeDSError.domain,
                                                                                          @"code": @(threeDSError.code),
                                                                                          @"user_info": userInfo,
                                                                                          }];
        [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:localizedError];
    }];
}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithRuntimeErrorEvent:(STDSRuntimeErrorEvent *)runtimeErrorEvent {

    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        // Add localizedError to the 3DS2 SDK error
        NSError *threeDSError = [runtimeErrorEvent NSErrorValue];
        NSMutableDictionary *userInfo = [threeDSError.userInfo mutableCopy];
        userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
        NSError *localizedError = [NSError errorWithDomain:threeDSError.domain code:threeDSError.code userInfo:userInfo];
        [[STPAnalyticsClient sharedClient] log3DS2ChallengeFlowErroredWithConfiguration:self->_currentAction.apiClient.configuration
                                                                               intentID:self->_currentAction.intentStripeID
                                                                        errorDictionary:@{
                                                                                          @"domain": threeDSError.domain,
                                                                                          @"code": @(threeDSError.code),
                                                                                          @"user_info": userInfo,
                                                                                          }];
        [self->_currentAction completeWithStatus:STPPaymentHandlerActionStatusFailed error:localizedError];
    }];
}

- (void)transactionDidPresentChallengeScreen:(STDSTransaction *)transaction {

    [[STPAnalyticsClient sharedClient] log3DS2ChallengeFlowPresentedWithConfiguration:_currentAction.apiClient.configuration
                                                                             intentID:_currentAction.intentStripeID
                                                                               uiType:transaction.presentedChallengeUIType];
}

- (void)_markChallengeCompletedWithCompletion:(STPBooleanSuccessBlock)completion {
    NSString *threeDSSourceID = _currentAction.nextAction.useStripeSDK.threeDS2SourceID;
    if (threeDSSourceID == nil) {
        completion(NO, nil);
        return;
    }

    [_currentAction.apiClient complete3DS2AuthenticationForSource:threeDSSourceID completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            if ([self->_currentAction isKindOfClass:[STPPaymentHandlerPaymentIntentActionParams class]]) {
                STPPaymentHandlerPaymentIntentActionParams *currentAction = (STPPaymentHandlerPaymentIntentActionParams *)self->_currentAction;
                [currentAction.apiClient retrievePaymentIntentWithClientSecret:currentAction.paymentIntent.clientSecret
                                                                    completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable retrieveError) {
                                                                        currentAction.paymentIntent = paymentIntent;
                                                                        completion(paymentIntent != nil, retrieveError);
                                                                    }];
            } else if ([self->_currentAction isKindOfClass:[STPPaymentHandlerSetupIntentActionParams class]]) {
                STPPaymentHandlerSetupIntentActionParams *currentAction = (STPPaymentHandlerSetupIntentActionParams *)self->_currentAction;
                [currentAction.apiClient retrieveSetupIntentWithClientSecret:currentAction.setupIntent.clientSecret
                                                                  completion:^(STPSetupIntent * _Nullable setupIntent, NSError * _Nullable retrieveError) {
                                                                      currentAction.setupIntent = setupIntent;
                                                                      completion(setupIntent != nil, retrieveError);
                                                                  }];
            } else {
                NSAssert(NO, @"currentAction is an unknown type or nil.");
            }
        } else {
            completion(success, error);
        }
    }];

}

#pragma mark - Errors

- (NSError *)_errorForCode:(STPPaymentHandlerErrorCode)errorCode userInfo:(nullable NSDictionary *)additionalUserInfo {
    NSMutableDictionary *userInfo = additionalUserInfo ? [additionalUserInfo mutableCopy] : [NSMutableDictionary new];
    switch (errorCode) {
        // 3DS(2) flow expected user errors
        case STPPaymentHandlerNotAuthenticatedErrorCode:
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"We are unable to authenticate your payment method. Please choose a different payment method and try again.", @"Error when 3DS2 authentication failed (e.g. customer entered the wrong code)");
            break;
        case STPPaymentHandlerTimedOutErrorCode:
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Timed out authenticating your payment method -- try again", @"Error when 3DS2 authentication timed out.");
            break;

        // PaymentIntent has an unexpected/unknown status
        case STPPaymentHandlerIntentStatusErrorCode:
            // The PI's status is processing or unknown
            userInfo[STPErrorMessageKey] = userInfo[STPErrorMessageKey] ?: @"The PaymentIntent status cannot be handled.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        case STPPaymentHandlerUnsupportedAuthenticationErrorCode:
            userInfo[STPErrorMessageKey] = userInfo[STPErrorMessageKey] ?: @"The SDK doesn't recognize the PaymentIntent action type.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;

        // Programming errors
        case STPPaymentHandlerRequiresPaymentMethodErrorCode:
            userInfo[STPErrorMessageKey] = userInfo[STPErrorMessageKey] ?: @"The PaymentIntent requires a PaymentMethod or Source to be attached before using STPPaymentHandler.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        case STPPaymentHandlerNoConcurrentActionsErrorCode:
            userInfo[STPErrorMessageKey] = userInfo[STPErrorMessageKey] ?: @"The current action is not yet completed. STPPaymentHandler does not support concurrent calls to its API.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        case STPPaymentHandlerRequiresAuthenticationContextErrorCode:
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
            
        // Exceptions thrown from the Stripe3DS2 SDK. Other errors are reported via STPChallengeStatusReceiver.
        case STPPaymentHandlerStripe3DS2ErrorCode:
            userInfo[STPErrorMessageKey] = userInfo[STPErrorMessageKey] ?: @"There was an error in the Stripe3DS2 SDK.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        
        // Confirmation errors (eg card was declined)
        case STPPaymentHandlerPaymentErrorCode:
            userInfo[STPErrorMessageKey] = userInfo[STPErrorMessageKey] ?: @"There was an error confirming the Intent. Inspect the `paymentIntent.lastPaymentError` or `setupIntent.lastSetupError` property.";
                userInfo[NSLocalizedDescriptionKey] = userInfo[NSLocalizedDescriptionKey] ?: [NSError stp_unexpectedErrorMessage];
            break;
    }
    return [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
