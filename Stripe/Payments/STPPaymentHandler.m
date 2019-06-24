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

#import "STP3DS2AuthenticateResponse.h"
#import "STPAPIClient+Private.h"
#import "STPAuthenticationContext.h"
#import "STPPaymentIntent.h"
#import "STPPaymentIntentAction+Private.h"
#import "STPPaymentIntentActionRedirectToURL.h"
#import "STPPaymentIntentActionUseStripeSDK.h"
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
        sharedHandler = [[STPPaymentHandler alloc] init];
        sharedHandler->_apiClient = [STPAPIClient sharedClient];
        sharedHandler.threeDSCustomizationSettings = [STPThreeDSCustomizationSettings defaultSettings];
    });

    return sharedHandler;
}

- (void)confirmPayment:(STPPaymentIntentParams *)paymentParams
withAuthenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
            completion:(STPPaymentHandlerActionCompletionBlock)completion {
    if (_currentAction != nil) {
        completion(STPPaymentHandlerActionStatusFailed, nil, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                 code:STPPaymentHandlerNoConcurrentActionsErrorCode
                                                                             userInfo:nil]);
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
        completion(STPPaymentHandlerActionStatusFailed, nil, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                 code:STPPaymentHandlerNoConcurrentActionsErrorCode
                                                                             userInfo:nil]);
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

    if (paymentIntent != nil) {
        switch (paymentIntent.status) {

            case STPPaymentIntentStatusUnknown:
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                   code:STPPaymentHandlerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
                break;

            case STPPaymentIntentStatusRequiresPaymentMethod:
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                   code:STPPaymentHandlerRequiresPaymentMethodErrorCode
                                                                                               userInfo:nil]);
                break;
            case STPPaymentIntentStatusRequiresConfirmation:
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                   code:STPPaymentHandlerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
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
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                   code:STPPaymentHandlerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
                break;
            case STPPaymentIntentStatusSucceeded:
                completion(STPPaymentHandlerActionStatusSucceeded, paymentIntent, nil);
                break;
            case STPPaymentIntentStatusRequiresCapture:
                completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                   code:STPPaymentHandlerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
                break;
            case STPPaymentIntentStatusCanceled:
                completion(STPPaymentHandlerActionStatusCanceled, paymentIntent, nil);
                break;
        }
    } else {
        completion(STPPaymentHandlerActionStatusFailed, nil, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                 code:STPPaymentHandlerInternalErrorCode
                                                                             userInfo:nil]);
    }
}

- (void)_handleAuthenticationForCurrentAction {
    STPPaymentIntent *paymentIntent = _currentAction.paymentIntent;
    STPPaymentIntentAction *authenticationAction = paymentIntent.nextAction;
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }

    // Checking for authenticationPresentingViewController instead of just authenticationContext == nil
    // also allows us to catch contexts that are not behaving correctly (i.e. returning nil vc when they shouldn't)
    if ([_currentAction.authenticationContext authenticationPresentingViewController] == nil) {
        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                           code:STPPaymentHandlerRequiresAuthenticationContextErrorCode
                                                                                       userInfo:nil]);
    }

    switch (authenticationAction.type) {

        case STPPaymentIntentActionTypeUnknown:
            completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                               code:STPPaymentHandlerUnsupportedAuthenticationErrorCode
                                                                                           userInfo:nil]);
            break;
        case STPPaymentIntentActionTypeRedirectToURL: {
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

        case STPPaymentIntentActionTypeUseStripeSDK:

            switch (authenticationAction.useStripeSDK.type) {
                case STPPaymentIntentActionUseStripeSDKTypeUnknown:
                    completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                       code:STPPaymentHandlerUnsupportedAuthenticationErrorCode
                                                                                                   userInfo:nil]);
                    break;
                case STPPaymentIntentActionUseStripeSDKType3DS2Fingerprint: {
                    STDSThreeDS2Service *threeDSService = _currentAction.threeDS2Service;
                    if (threeDSService == nil) {
                        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                           code:STPPaymentHandlerStripe3DS2ErrorCode
                                                                                                       userInfo:@{@"description": @"Failed to initialize STDSThreeDS2Service."}]);
                        return;
                    }

                    STDSTransaction *transaction = nil;
                    STDSAuthenticationRequestParameters *authRequestParams = nil;
                    @try {
                        transaction = [threeDSService createTransactionForDirectoryServer:authenticationAction.useStripeSDK.directoryServer
                                                                      withProtocolVersion:@"2.1.0"];

                        authRequestParams = [transaction createAuthenticationRequestParameters];

                    } @catch (NSException *exception) {
                        completion(STPPaymentHandlerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                           code:STPPaymentHandlerStripe3DS2ErrorCode
                                                                                                       userInfo:@{@"exception": exception.description}]);
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
                                                  self->_currentAction.completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                                                                                               code:STPPaymentHandlerStripe3DS2ErrorCode userInfo:@{@"exception": exception}]);
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

- (void)transaction:(__unused STDSTransaction *)transaction didCompleteChallengeWithCompletionEvent:(__unused STDSCompletionEvent *)completionEvent {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    NSString *transactionStatus = completionEvent.transactionStatus;
    if ([transactionStatus isEqualToString:@"Y"]) {
        [self _markChallengeCompletedWithCompletion:^(BOOL markedCompleted, __unused NSError * _Nullable error) {
            completion(markedCompleted ? STPPaymentHandlerActionStatusSucceeded : STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, error);
        }];

    } else {
        // going to ignore the rest of the status types because they provide more detail than we require
        [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
            completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                              code:STPPaymentHandlerThreeDomainSecureErrorCode
                                                                                                          userInfo:@{@"transaction_status": transactionStatus}]);
        }];
    }
}

- (void)transactionDidCancel:(__unused STDSTransaction *)transaction {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        completion(STPPaymentHandlerActionStatusCanceled, self->_currentAction.paymentIntent, nil);
    }];
}

- (void)transactionDidTimeOut:(__unused STDSTransaction *)transaction {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [NSError errorWithDomain:STPPaymentHandlerErrorDomain
                                                                                                          code:STPPaymentHandlerTimedOutErrorCode
                                                                                                      userInfo:nil]);
    }];

}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithProtocolErrorEvent:(STDSProtocolErrorEvent *)protocolErrorEvent {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [protocolErrorEvent.errorMessage NSErrorValue]);
    }];
}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithRuntimeErrorEvent:(STDSRuntimeErrorEvent *)runtimeErrorEvent {
    STPPaymentHandlerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    [self _markChallengeCompletedWithCompletion:^(__unused BOOL markedCompleted, __unused NSError * _Nullable error) {
        completion(STPPaymentHandlerActionStatusFailed, self->_currentAction.paymentIntent, [runtimeErrorEvent NSErrorValue]);
    }];
}

- (void)_markChallengeCompletedWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
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


@end

NS_ASSUME_NONNULL_END
