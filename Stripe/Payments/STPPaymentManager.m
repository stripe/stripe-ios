//
//  STPPaymentManager.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentManager.h"

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
#import "STPURLCallbackHandler.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const STPPaymentManagerErrorDomain = @"STPPaymentManagerErrorDomain";

const NSInteger STPPaymentManagerUnsupportedAuthenticationErrorCode = 0;
const NSInteger STPPaymentManagerRequiresPaymentMethodErrorCode = 1;
const NSInteger STPPaymentManagerTimedOutErrorCode = 2;
const NSInteger STPPaymentManagerStripe3DS2ErrorCode = 3;
const NSInteger STPPaymentManagerThreeDomainSecureErrorCode = 4;
const NSInteger STPPaymentManagerInternalErrorCode = 5;
const NSInteger STPPaymentManagerNoConcurrentActionsErrorCode = 6;
const NSInteger STPPaymentManagerPaymentIntentStatusErrorCode = 7;
const NSInteger STPPaymentManagerRequiresAuthenticationContext = 8;

@interface STPPaymentManagerActionParams: NSObject

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                       completion:(STPPaymentManagerActionCompletionBlock)completion;

@property (nonatomic, nullable, readonly) STDSThreeDS2Service *threeDS2Service;

@property (nonatomic, nullable, readonly, strong) id<STPAuthenticationContext> authenticationContext;
@property (nonatomic, readonly, strong) STPAPIClient *apiClient;
@property (nonatomic, readonly, strong) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;
@property (nonatomic, readonly, copy) STPPaymentManagerActionCompletionBlock completion;

@property (nonatomic, nullable) STPPaymentIntent *paymentIntent;

@end

@implementation STPPaymentManagerActionParams
{
    dispatch_once_t _threeDS2ServiceOnceToken;
}

@synthesize threeDS2Service = _threeDS2Service;

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
            authenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
     threeDSCustomizationSettings:(STPThreeDSCustomizationSettings *)threeDSCustomizationSettings
                       completion:(STPPaymentManagerActionCompletionBlock)completion {
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
    dispatch_once(&_threeDS2ServiceOnceToken, ^{
        self->_threeDS2Service = [[STDSThreeDS2Service alloc] init];
        @try {
            STDSConfigParameters *configParams = [[STDSConfigParameters alloc] initWithStandardParameters];
            [configParams addParameterNamed:@"kInternalStripeTestingConfigParam" withValue:@"Y"];
            [self->_threeDS2Service initializeWithConfig:configParams
                                                  locale:[NSLocale autoupdatingCurrentLocale]
                                              uiSettings:self->_threeDSCustomizationSettings.uiCustomization];
        } @catch (NSException *e) {
            self->_threeDS2Service = nil;
        }

    });

    return _threeDS2Service;
}


@end

@interface STPPaymentManager () <SFSafariViewControllerDelegate, STPURLCallbackListener, STDSChallengeStatusReceiver>
{
     STPPaymentManagerActionParams *_currentAction;
}

@end

@implementation STPPaymentManager

+ (instancetype)sharedManager {
    static STPPaymentManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[STPPaymentManager alloc] init];
        sharedManager->_apiClient = [STPAPIClient sharedClient];
    });

    return sharedManager;
}

- (void)confirmPayment:(STPPaymentIntentParams *)paymentParams
withAuthenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
            completion:(STPPaymentManagerActionCompletionBlock)completion {
    if (_currentAction != nil) {
        completion(STPPaymentManagerActionStatusFailed, nil, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                 code:STPPaymentManagerNoConcurrentActionsErrorCode
                                                                             userInfo:nil]);
        return;
    }

    __weak __typeof(self) weakSelf = self;
    _currentAction = [[STPPaymentManagerActionParams alloc] initWithAPIClient:self.apiClient
                                                        authenticationContext:authenticationContext
                                                 threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                   completion:^(STPPaymentManagerActionStatus status, STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                                                       __typeof(self) strongSelf = weakSelf;
                                                                       if (strongSelf != nil) {
                                                                           strongSelf->_currentAction = nil;
                                                                       }
                                                                       completion(status, paymentIntent, error);
                                                                   }];

    [self.apiClient confirmPaymentIntentWithParams:paymentParams
                                        completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                            if (error) {
                                                self->_currentAction.completion(STPPaymentManagerActionStatusFailed, paymentIntent, error);
                                            } else {
                                                self->_currentAction.paymentIntent = paymentIntent;
                                                [self _handleNextActionIfNeededAttemptAuthentication:YES];
                                            }
                                        }];
}

- (void)handleNextActionForPayment:(STPPaymentIntent *)paymentIntent
         withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                        completion:(STPPaymentManagerActionCompletionBlock)completion {
    if (_currentAction != nil) {
        completion(STPPaymentManagerActionStatusFailed, nil, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                 code:STPPaymentManagerNoConcurrentActionsErrorCode
                                                                             userInfo:nil]);
        return;
    }

    __weak __typeof(self) weakSelf = self;
    _currentAction = [[STPPaymentManagerActionParams alloc] initWithAPIClient:self.apiClient
                                                        authenticationContext:authenticationContext
                                                 threeDSCustomizationSettings:self.threeDSCustomizationSettings
                                                                   completion:^(STPPaymentManagerActionStatus status, STPPaymentIntent * _Nullable resultPaymentIntent, NSError * _Nullable error) {
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
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }

    if (paymentIntent != nil) {
        switch (paymentIntent.status) {

            case STPPaymentIntentStatusUnknown:
                completion(STPPaymentManagerActionStatusCanceled, paymentIntent, nil);
                break;

            case STPPaymentIntentStatusRequiresPaymentMethod:
                completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                 code:STPPaymentManagerRequiresPaymentMethodErrorCode
                                                                             userInfo:nil]);
                break;
            case STPPaymentIntentStatusRequiresConfirmation:
                completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                                   code:STPPaymentManagerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
                break;
            case STPPaymentIntentStatusRequiresAction:
                if (attemptAuthentication) {
                    [self _handleAuthenticationForCurrentAction];
                } else {
                    // If we get here, the user exited from the redirect before the
                    // payment intent was updated. Consider it a cancel
                    completion(STPPaymentManagerActionStatusCanceled, paymentIntent, nil);
                }
                break;
            case STPPaymentIntentStatusProcessing:
                completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                                   code:STPPaymentManagerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
                break;
            case STPPaymentIntentStatusSucceeded:
                completion(STPPaymentManagerActionStatusSucceeded, paymentIntent, nil);
                break;
            case STPPaymentIntentStatusRequiresCapture:
                completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                                   code:STPPaymentManagerPaymentIntentStatusErrorCode
                                                                                               userInfo:nil]);
                break;
            case STPPaymentIntentStatusCanceled:
                completion(STPPaymentManagerActionStatusCanceled, paymentIntent, nil);
                break;
        }
    } else {
        completion(STPPaymentManagerActionStatusFailed, nil, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                              code:STPPaymentManagerInternalErrorCode
                                                                          userInfo:nil]);
    }
}

- (void)_handleAuthenticationForCurrentAction {
    STPPaymentIntent *paymentIntent = _currentAction.paymentIntent;
    STPPaymentIntentAction *authenticationAction = paymentIntent.nextAction;
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }

    // Checking for authenticationPresentingViewController instead of just authenticationContext == nil
    // also allows us to catch contexts that are not behaving correctly (i.e. returning nil vc when they shouldn't)
    if ([_currentAction.authenticationContext authenticationPresentingViewController] == nil) {
        completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                           code:STPPaymentManagerRequiresAuthenticationContext
                                                                                       userInfo:nil]);
    }

    switch (authenticationAction.type) {

        case STPPaymentIntentActionTypeUnknown:
            completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                             code:STPPaymentManagerUnsupportedAuthenticationErrorCode
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
                    completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                     code:STPPaymentManagerUnsupportedAuthenticationErrorCode
                                                                                 userInfo:nil]);
                    break;
                case STPPaymentIntentActionUseStripeSDKType3DS2Fingerprint: {
                    STDSThreeDS2Service *threeDSService = _currentAction.threeDS2Service;
                    if (threeDSService == nil) {
                        completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                         code:STPPaymentManagerStripe3DS2ErrorCode
                                                                                     userInfo:@{@"description": @"Failed to initialize STDSThreeDS2Service."}]);
                        return;
                    }

                    STDSTransaction *transaction = nil;
                    STDSAuthenticationRequestParameters *authRequestParams = nil;
                    @try {
                        transaction = [threeDSService createTransactionForDirectoryServer:authenticationAction.useStripeSDK.directoryServer
                                                                      withProtocolVersion:@"2.1.0"]; // TODO : Hard-coded?

                        authRequestParams = [transaction createAuthenticationRequestParameters];

                    } @catch (NSException *exception) {
                        completion(STPPaymentManagerActionStatusFailed, paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                          code:STPPaymentManagerStripe3DS2ErrorCode
                                                                                      userInfo:@{@"exception": exception.description}]);
                    }

                    [_apiClient authenticate3DS2:authRequestParams
                                sourceIdentifier:authenticationAction.useStripeSDK.threeDS2SourceID
                                      completion:^(STP3DS2AuthenticateResponse * _Nullable authenticateResponse, NSError * _Nullable error) {
                                          if (authenticateResponse == nil) {
                                              completion(STPPaymentManagerActionStatusFailed, self->_currentAction.paymentIntent, error);
                                          } else {
                                              STDSChallengeParameters *challengeParameters = [[STDSChallengeParameters alloc] initWithAuthenticationResponse:authenticateResponse.authenticationResponse];

                                              [transaction doChallengeWithViewController:[self->_currentAction.authenticationContext authenticationPresentingViewController]
                                                                     challengeParameters:challengeParameters
                                                                 challengeStatusReceiver:self
                                                                                 timeout:self->_currentAction.threeDSCustomizationSettings.authenticationTimeout];
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
                                                   self->_currentAction.completion(STPPaymentManagerActionStatusFailed, paymentIntent, error);
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
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    NSString *transactionStatus = completionEvent.transactionStatus;
    if ([transactionStatus isEqualToString:@"Y"]) {
        completion(STPPaymentManagerActionStatusSucceeded, _currentAction.paymentIntent, nil);
    } else {
        // going to ignore the rest of the status types because they provide more detail than we require
        completion(STPPaymentManagerActionStatusFailed, _currentAction.paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                             code:STPPaymentManagerThreeDomainSecureErrorCode
                                                                                         userInfo:@{@"transaction_status": transactionStatus}]);
    }
}

- (void)transactionDidCancel:(__unused STDSTransaction *)transaction {
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    completion(STPPaymentManagerActionStatusCanceled, _currentAction.paymentIntent, nil);
}

- (void)transactionDidTimeOut:(__unused STDSTransaction *)transaction {
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    completion(STPPaymentManagerActionStatusFailed, _currentAction.paymentIntent, [NSError errorWithDomain:STPPaymentManagerErrorDomain
                                                                                         code:STPPaymentManagerTimedOutErrorCode
                                                                                     userInfo:nil]);
}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithProtocolErrorEvent:(STDSProtocolErrorEvent *)protocolErrorEvent {
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    completion(STPPaymentManagerActionStatusFailed, _currentAction.paymentIntent, [protocolErrorEvent.errorMessage NSErrorValue]);
}

- (void)transaction:(__unused STDSTransaction *)transaction didErrorWithRuntimeErrorEvent:(STDSRuntimeErrorEvent *)runtimeErrorEvent {
    STPPaymentManagerActionCompletionBlock completion = _currentAction.completion;
    if (completion == nil) {
        return;
    }
    completion(STPPaymentManagerActionStatusFailed, _currentAction.paymentIntent, [runtimeErrorEvent NSErrorValue]);
}


@end

NS_ASSUME_NONNULL_END
