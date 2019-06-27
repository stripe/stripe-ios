//
//  STPPaymentHandler.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentHandler.h"

#import <SafariServices/SafariServices.h>
#import <Stripe3DS2/Stripe3DS2.h>

#import "NSError+Stripe.h"
#import "STP3DS2AuthenticateResponse.h"
#import "STPAPIClient+Private.h"
#import "STPAuthenticationContext.h"
#import "STPPaymentIntent.h"
#import "STPIntentAction+Private.h"
#import "STPIntentActionRedirectToURL.h"
#import "STPIntentActionUseStripeSDK.h"
#import "STPThreeDSCustomizationSettings.h"
#import "STPThreeDSCustomization+Private.h"
#import "STPURLCallbackHandler.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const STPPaymentHandlerErrorDomain = @"STPPaymentHandlerErrorDomain";

@interface STPPaymentHandlerActionParams: NSObject

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                       completion:(STPPaymentHandlerActionCompletionBlock)completion;

@property (nonatomic, nullable, readonly) STDSThreeDS2Service *threeDS2Service;

@property (nonatomic, nullable, readonly, strong) id<STPAuthenticationContext> authenticationContext;
@property (nonatomic, readonly, strong) STPAPIClient *apiClient;
@property (nonatomic, readonly, strong) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;
@property (nonatomic, readonly, copy) STPPaymentHandlerActionCompletionBlock completion;

@property (nonatomic, nullable) STPPaymentIntent *paymentIntent;

@end

@implementation STPPaymentHandlerActionParams
{
    BOOL _serviceInitialized;
}

@synthesize threeDS2Service = _threeDS2Service;

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                       completion:(STPPaymentHandlerActionCompletionBlock)completion {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _authenticationContext = authenticationContext;
        _threeDSCustomizationSettings = threeDSCustomizationSettings;
        _completion = [completion copy];
    }

    return self;
}

- (nullable STDSThreeDS2Service *)threeDS2Service {
    if (!_serviceInitialized) {
        _serviceInitialized = YES;
        _threeDS2Service = [[STDSThreeDS2Service alloc] init];
        @try {
            STDSConfigParameters *configParams = [[STDSConfigParameters alloc] initWithStandardParameters];
            [configParams addParameterNamed:@"kInternalStripeTestingConfigParam" withValue:@"Y"];
            [_threeDS2Service initializeWithConfig:configParams
                                                  locale:[NSLocale autoupdatingCurrentLocale]
                                              uiSettings:_threeDSCustomizationSettings.uiCustomization.uiCustomization];
        } @catch (NSException *e) {
            _threeDS2Service = nil;
        }
    }

    return _threeDS2Service;
}


@end

@interface STPPaymentHandler () <SFSafariViewControllerDelegate, STPURLCallbackListener, STDSChallengeStatusReceiver>
{
    STPPaymentHandlerActionParams *_currentAction;
}

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
withAuthenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
            completion:(STPPaymentHandlerActionCompletionBlock)completion {
    if (_currentAction != nil) {
        completion(STPPaymentHandlerActionStatusFailed, nil, [self _errorForCode:STPPaymentHandlerNoConcurrentActionsErrorCode userInfo:nil]);
        return;
    }

    __weak __typeof(self) weakSelf = self;
    _currentAction = [[STPPaymentHandlerActionParams alloc] initWithAPIClient:self.apiClient
                                                        authenticationContext:authenticationContext
                                                 threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                   completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                                                       __typeof(self) strongSelf = weakSelf;
                                                                       if (strongSelf != nil) {
                                                                           strongSelf->_currentAction = nil;
                                                                       }
                                                                       completion(status, paymentIntent, error);
                                                                   }];

    [self.apiClient confirmPaymentIntentWithParams:paymentParams
                                        completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                            if (error) {
                                                self->_currentAction.completion(STPPaymentHandlerActionStatusFailed, paymentIntent, error);
                                            } else {
                                                self->_currentAction.paymentIntent = paymentIntent;
                                                [self _handleNextActionIfNeededAttemptAuthentication:YES];
                                            }
                                        }];
}

- (void)handleNextActionForPayment:(STPPaymentIntent *)paymentIntent
         withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                        completion:(STPPaymentHandlerActionCompletionBlock)completion {
    NSAssert(_currentAction == nil, @"Should not handle multiple payments at once.");
    if (_currentAction != nil) {
        completion(STPPaymentHandlerActionStatusFailed, nil, [self _errorForCode:STPPaymentHandlerNoConcurrentActionsErrorCode userInfo:nil]);
        return;
    }
    if (paymentIntent.status == STPPaymentIntentStatusRequiresPaymentMethod) {
        // The caller forgot to attach a paymentMethod.
        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerRequiresPaymentMethodErrorCode userInfo:nil]);
        return;
    }

    __weak __typeof(self) weakSelf = self;
    _currentAction = [[STPPaymentHandlerActionParams alloc] initWithAPIClient:self.apiClient
                                                        authenticationContext:authenticationContext
                                                 threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                   completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * _Nullable resultPaymentIntent, NSError * _Nullable error) {
                                                                       __typeof(self) strongSelf = weakSelf;
                                                                       if (strongSelf != nil) {
                                                                           strongSelf->_currentAction = nil;
                                                                       }
                                                                       completion(status, resultPaymentIntent, error);
                                                                   }];
    _currentAction.paymentIntent = paymentIntent;
    [self _handleNextActionIfNeededAttemptAuthentication:YES];
}

- (void)_handleNextActionIfNeededAttemptAuthentication:(BOOL)attemptAuthentication {
    STPPaymentIntent *paymentIntent = _currentAction.paymentIntent;
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    if (paymentIntent == nil) {
        NSAssert(paymentIntent != nil, @"paymentIntent should never be nil here.");
        completion(STPPaymentHandlerActionStatusFailed, nil, [NSError stp_genericFailedToParseResponseError]);
        return;
    }
    switch (paymentIntent.status) {

        case STPPaymentIntentStatusUnknown:
            completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerPaymentIntentStatusErrorCode userInfo:@{@"STPPaymentIntent": paymentIntent.description}]);
            break;

        case STPPaymentIntentStatusRequiresPaymentMethod:
            // If the user forgot to attach a PaymentMethod, they get an error before this point.
            // If authentication fails, the PaymentIntent transitions to this state.
            completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerNotAuthenticatedErrorCode userInfo:nil]);
            break;
        case STPPaymentIntentStatusRequiresConfirmation:
            completion(STPPaymentHandlerActionStatusSucceeded, paymentIntent, nil);
            break;
        case STPPaymentIntentStatusRequiresAction:
            if (attemptAuthentication) {
                [self _handleAuthenticationForCurrentAction];
            } else {
                // If we get here, the user exited from the redirect before the
                // payment intent was updated. Consider it a cancel
                completion(STPPaymentHandlerActionStatusCanceled, paymentIntent, nil);
            }
            break;
        case STPPaymentIntentStatusProcessing:
            completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerPaymentIntentStatusErrorCode userInfo:nil]);
            break;
        case STPPaymentIntentStatusSucceeded:
            completion(STPPaymentHandlerActionStatusSucceeded, paymentIntent, nil);
            break;
        case STPPaymentIntentStatusRequiresCapture:
            completion(STPPaymentHandlerActionStatusSucceeded, paymentIntent, nil);
            break;
        case STPPaymentIntentStatusCanceled:
            completion(STPPaymentHandlerActionStatusCanceled, paymentIntent, nil);
            break;
        }
}

- (void)_handleAuthenticationForCurrentAction {
    STPPaymentIntent *paymentIntent = _currentAction.paymentIntent;
    STPIntentAction *authenticationAction = paymentIntent.nextAction;
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }

    // Checking for authenticationPresentingViewController instead of just authenticationContext == nil
    // also allows us to catch contexts that are not behaving correctly (i.e. returning nil vc when they shouldn't)
    UIViewController *presentingViewController = [_currentAction.authenticationContext authenticationPresentingViewController];
    if (presentingViewController == nil || presentingViewController.view.window == nil) {
        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerRequiresAuthenticationContextErrorCode userInfo:nil]);
        return;
    }

    switch (authenticationAction.type) {

        case STPIntentActionTypeUnknown:
            completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerUnsupportedAuthenticationErrorCode userInfo:@{@"STPIntentAction": authenticationAction.description}]);
            break;
        case STPIntentActionTypeRedirectToURL: {
            NSURL *url = authenticationAction.redirectToURL.url;

            [[STPURLCallbackHandler shared] registerListener:self forURL:authenticationAction.redirectToURL.returnURL];

            [[UIApplication sharedApplication] openURL:url
                                               options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @(YES)}
                                     completionHandler:^(BOOL success){
                                         if(!success) {
                                             // no app installed, launch safari view controller
                                             SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:authenticationAction.redirectToURL.url];
                                             safariViewController.delegate = self;
                                             [[self->_currentAction.authenticationContext authenticationPresentingViewController] presentViewController:safariViewController animated:YES completion:nil];
                                         } else {
                                             [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                      selector:@selector(_handleWillForegroundNotification)
                                                                                          name:UIApplicationWillEnterForegroundNotification
                                                                                        object:nil];
                                         }
                                     }];

        }
            break;

        case STPIntentActionTypeUseStripeSDK:

            switch (authenticationAction.useStripeSDK.type) {
                case STPIntentActionUseStripeSDKTypeUnknown:
                    completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerUnsupportedAuthenticationErrorCode userInfo:@{@"STPIntentActionUseStripeSDK": authenticationAction.useStripeSDK.description}]);
                    break;
                case STPIntentActionUseStripeSDKType3DS2Fingerprint: {
                    STDSThreeDS2Service *threeDSService = _currentAction.threeDS2Service;
                    if (threeDSService == nil) {
                        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerStripe3DS2ErrorCode userInfo:@{@"description": @"Failed to initialize STDSThreeDS2Service."}]);
                        return;
                    }

                    STDSTransaction *transaction = nil;
                    STDSAuthenticationRequestParameters *authRequestParams = nil;
                    @try {
                        transaction = [threeDSService createTransactionForDirectoryServer:authenticationAction.useStripeSDK.directoryServer
                                                                      withProtocolVersion:@"2.1.0"];

                        authRequestParams = [transaction createAuthenticationRequestParameters];

                    } @catch (NSException *exception) {
                        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [self _errorForCode:STPPaymentHandlerStripe3DS2ErrorCode userInfo:@{@"exception": exception.description}]);
                    }

                    [_apiClient authenticate3DS2:authRequestParams
                                sourceIdentifier:authenticationAction.useStripeSDK.threeDS2SourceID
                                      maxTimeout:_currentAction.threeDSCustomizationSettings.authenticationTimeout
                                      completion:^(STP3DS2AuthenticateResponse * _Nullable authenticateResponse, NSError * _Nullable error) {
                                          if (authenticateResponse == nil) {
                                              completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, error);
                                          } else {
                                              STDSChallengeParameters *challengeParameters = [[STDSChallengeParameters alloc] initWithAuthenticationResponse:authenticateResponse.authenticationResponse];
                                              @try {
                                                  [transaction doChallengeWithViewController:[self->_currentAction.authenticationContext authenticationPresentingViewController]
                                                                         challengeParameters:challengeParameters
                                                                     challengeStatusReceiver:self
                                                                                     timeout:self->_currentAction.threeDSCustomizationSettings.authenticationTimeout];
                                              } @catch (NSException *exception) {
                                                  self->_currentAction.completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [self _errorForCode:STPPaymentHandlerStripe3DS2ErrorCode  userInfo:@{@"exception": exception}]);
                                              }

                                          }
                                      }];
                }
                    break;
            }
            break;
    }
}

- (void)_retrieveAndCheckPaymentIntentForCurrentAction {
    [_currentAction.apiClient retrievePaymentIntentWithClientSecret:_currentAction.paymentIntent.clientSecret
                                                         completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                                             if (error != nil) {
                                                                 self->_currentAction.completion(STPPaymentHandlerActionStatusFailed, paymentIntent, error);
                                                             } else {
                                                                 self->_currentAction.paymentIntent = paymentIntent;
                                                                 [self _handleNextActionIfNeededAttemptAuthentication:NO];
                                                             }
                                                         }];
}

- (void)_handleWillForegroundNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self _retrieveAndCheckPaymentIntentForCurrentAction];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController * __unused)controller {
    [[STPURLCallbackHandler shared] unregisterListener:self];
    [self _retrieveAndCheckPaymentIntentForCurrentAction];
}

#pragma mark - STPURLCallbackListener

- (BOOL)handleURLCallback:(NSURL * __unused)url {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[STPURLCallbackHandler shared] unregisterListener:self];
    [[_currentAction.authenticationContext authenticationPresentingViewController] dismissViewControllerAnimated:YES completion:nil];
    [self _retrieveAndCheckPaymentIntentForCurrentAction];
    return YES;
}

#pragma mark - STPChallengeStatusReceiver

- (void)transaction:(__unused STDSTransaction *)transaction didCompleteChallengeWithCompletionEvent:(STDSCompletionEvent *)completionEvent {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    NSAssert(completion != nil, @"Shouldn't have a nil completion block at this point.");
    if (completion == nil) {
        return;
    }
    NSString *transactionStatus = completionEvent.transactionStatus;
    if ([transactionStatus isEqualToString:@"Y"]) {
        [self _markChallengeCompletedWithCompletion:^(BOOL markedCompleted, NSError * _Nullable error) {
            completion(markedCompleted ? STPPaymentHandlerActionStatusSucceeded : STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, error);
        }];

    } else {
        // going to ignore the rest of the status types because they provide more detail than we require
        [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
            completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [self _errorForCode:STPPaymentHandlerNotAuthenticatedErrorCode userInfo:@{@"transaction_status": transactionStatus}]);
        }];
    }
}

- (void)transactionDidCancel:(__unused STDSTransaction *)transaction {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    NSAssert(completion != nil, @"Shouldn't have a nil completion block at this point.");
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        completion(STPPaymentHandlerActionStatusCanceled, self->_currentAction.paymentIntent, nil);
    }];
}

- (void)transactionDidTimeOut:(__unused STDSTransaction *)transaction {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    NSAssert(completion != nil, @"Shouldn't have a nil completion block at this point.");
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [self _errorForCode:STPPaymentHandlerTimedOutErrorCode userInfo:nil]);
    }];

}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithProtocolErrorEvent:(STDSProtocolErrorEvent *)protocolErrorEvent {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    NSAssert(completion != nil, @"Shouldn't have a nil completion block at this point.");
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        // Add localizedError to the 3DS2 SDK error
        NSError *threeDSError = [protocolErrorEvent.errorMessage NSErrorValue];
        NSMutableDictionary *userInfo = [threeDSError.userInfo mutableCopy];
        userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
        NSError *localizedError = [NSError errorWithDomain:threeDSError.domain code:threeDSError.code userInfo:userInfo];
        completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, localizedError);
    }];
}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithRuntimeErrorEvent:(STDSRuntimeErrorEvent *)runtimeErrorEvent {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    NSAssert(completion != nil, @"Shouldn't have a nil completion block at this point.");
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        // Add localizedError to the 3DS2 SDK error
        NSError *threeDSError = [runtimeErrorEvent NSErrorValue];
        NSMutableDictionary *userInfo = [threeDSError.userInfo mutableCopy];
        userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
        NSError *localizedError = [NSError errorWithDomain:threeDSError.domain code:threeDSError.code userInfo:userInfo];
        completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, localizedError);
    }];
}

- (void)_markChallengeCompletedWithCompletion:(STPBooleanSuccessBlock)completion {
    NSString *threeDSSourceID = _currentAction.paymentIntent.nextAction.useStripeSDK.threeDS2SourceID;
    if (threeDSSourceID == nil) {
        completion(NO, nil);
        return;
    }

    [_currentAction.apiClient complete3DS2AuthenticationForSource:threeDSSourceID completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self->_currentAction.apiClient retrievePaymentIntentWithClientSecret:self->_currentAction.paymentIntent.clientSecret
                                                                       completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable retrieveError) {
                                                                           self->_currentAction.paymentIntent = paymentIntent;
                                                                           completion(paymentIntent != nil, retrieveError);
                                                                       }];
        } else {
            completion(success, error);
        }
    }];

}

#pragma mark - Errors

- (NSError *)_errorForCode:(STPPaymentHandlerErrorCode)errorCode userInfo:(nullable NSDictionary *)additionalUserInfo {
    NSMutableDictionary *userInfo = additionalUserInfo ? [additionalUserInfo mutableCopy] : [NSMutableDictionary new];
    switch (errorCode) {
        // 3DS2 flow expected user errors
        case STPPaymentHandlerNotAuthenticatedErrorCode:
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"We are unable to authenticate your payment method. Please choose a different payment method and try again.", @"Error when 3DS2 authentication failed (e.g. customer entered the wrong code)");
            break;
        case STPPaymentHandlerTimedOutErrorCode:
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Timed out authenticating your payment method -- try again", @"Error when 3DS2 authentication timed out.");
            break;

        // PaymentIntent has an unexpected/unknown status
        case STPPaymentHandlerPaymentIntentStatusErrorCode:
            // The PI's status is processing or unknown
            userInfo[STPErrorMessageKey] = @"The PaymentIntent status cannot be handled. ";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        case STPPaymentHandlerUnsupportedAuthenticationErrorCode:
            userInfo[STPErrorMessageKey] = @"The SDK doesn't recognize the PaymentIntent action type.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;

        // Programming errors
        case STPPaymentHandlerRequiresPaymentMethodErrorCode:
            userInfo[STPErrorMessageKey] = @"The PaymentIntent requires a PaymentMethod or Source to be attached before using STPPaymentHandler.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        case STPPaymentHandlerNoConcurrentActionsErrorCode:
            userInfo[STPErrorMessageKey] = @"The current action is not yet completed. STPPaymentHandler does not support concurrent calls to its API.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
        case STPPaymentHandlerRequiresAuthenticationContextErrorCode:
            userInfo[STPErrorMessageKey] = @"The authenticationContext is invalid.  Make sure it's non-nil and in the window hierarchy.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
            
        // Exceptions thrown from the Stripe3DS2 SDK. Other errors are reported via STPChallengeStatusReceiver.
        case STPPaymentHandlerStripe3DS2ErrorCode:
            userInfo[STPErrorMessageKey] = @"There was an error in the Stripe3DS2 SDK.";
            userInfo[NSLocalizedDescriptionKey] = [NSError stp_unexpectedErrorMessage];
            break;
    }
    return [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
