//
//  STPPaymentManager.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STPAPIClient;
@class STPPaymentIntent;
@class STPPaymentIntentParams;
@class STPThreeDSCustomizationSettings;
@protocol STPAuthenticationContext;

/**
 `STPPaymentManagerActionStatus` represents the possible outcomes of requesting an action by STPPaymentManager
 such as confirming and/or handling the next action for a PaymentIntent.
 */
typedef NS_ENUM(NSInteger, STPPaymentManagerActionStatus) {
    /**
     The action succeeded.
     */
    STPPaymentManagerActionStatusSucceeded,

    /**
     The action was cancelled by the cardholder/user.
     */
    STPPaymentManagerActionStatusCanceled,

    /**
     The action failed. See the error code for more details.
     */
    STPPaymentManagerActionStatusFailed,
};

/**
 The error domain for errors in STPPaymentManager.
 */
FOUNDATION_EXPORT NSString * const STPPaymentManagerErrorDomain;

/**
 Indicates that the action requires an authentication method not recognized or supported by the SDK.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerUnsupportedAuthenticationErrorCode;

/**
 The PaymentIntent could not be confirmed because it is missing an associated payment method.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerRequiresPaymentMethodErrorCode;

/**
 The PaymentIntent status cannot be resolved by `STPPaymentManager`.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerPaymentIntentStatusErrorCode;

/**
 The action timed out.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerTimedOutErrorCode;

/**
 There was an error in the Stripe3DS2 SDK.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerStripe3DS2ErrorCode;

/**
 There was an error in the Three Domain Secure process.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerThreeDomainSecureErrorCode;

/**
 There was an internal error processing the action.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerInternalErrorCode;

/**
 `STPPaymentManager` does not support concurrent actions.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerNoConcurrentActionsErrorCode;

/**
 Payment requires an `STPAuthenticationContext`.
 */
FOUNDATION_EXPORT const NSInteger STPPaymentManagerRequiresAuthenticationContext;

typedef void (^STPPaymentManagerActionCompletionBlock)(STPPaymentManagerActionStatus, STPPaymentIntent * _Nullable, NSError * _Nullable);

/**
 `STPPaymentManager` is a utility class to handle confirming PaymentIntents and executing
 any additional required actions to authenticate.
 */
NS_EXTENSION_UNAVAILABLE("STPPaymentManager is not available in extensions")
@interface STPPaymentManager : NSObject

/**
 The globally shared instance of `STPPaymentManageer`.
 */
+ (instancetype)sharedManager;

/**
 By default `sharedManager` initializes with [STPAPIClient sharedClient].
 */
@property (nonatomic) STPAPIClient *apiClient;

/**
 Customizable settings to use when performing 3DS2 authentication. Defaults to `[STPThreeDSCustomizationSettings defaultSettings]`.
 */
@property (nonatomic) STPThreeDSCustomizationSettings *threeDSCustomizationSettings;

/**
 Confirms the PaymentIntent with the provided parameters and handles any `nextAction` required
 to authenticate the PaymentIntent.
 */
- (void)confirmPayment:(STPPaymentIntentParams *)paymentParams
withAuthenticationContext:(nullable id<STPAuthenticationContext>)authenticationContext
            completion:(STPPaymentManagerActionCompletionBlock)completion;

/**
 Handles any `nextAction` required to authenticate the PaymentIntent.
 */
- (void)handleNextActionForPayment:(STPPaymentIntent *)paymentIntent
  withAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext
                 completion:(STPPaymentManagerActionCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
