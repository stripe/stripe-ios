//
//  STPThreeDSecureContext.h
//  Stripe
//
//  Created by Brian Dorfman on 9/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPThreeDSecure.h"

@class STPCard, STPThreeDSecureConfiguration;
@protocol STPBackendAPIAdapter;

NS_ASSUME_NONNULL_BEGIN

/**
 The level of of 3D Secure support you want to enable.
 
 - STPThreeDSecureSupportLevelDisabled: Disable all 3D Secure support
 - STPThreeDSecureSupportLevelOptional: Always enable 3D Secure, even for cards marked "optional"
 - STPThreeDSecureSupportLevelRequired: Only enable 3D Secure for cards which require it.
 */
typedef NS_ENUM(NSInteger, STPThreeDSecureSupportLevel) {
    STPThreeDSecureSupportLevelDisabled,
    STPThreeDSecureSupportLevelOptional,
    STPThreeDSecureSupportLevelRequired,
};

typedef void (^STPThreeDSecureFlowCompletionBlock)(STPThreeDSecure * __nullable threeDSecure, BOOL succeeded, NSError * __nullable error);

@interface STPThreeDSecureContext : NSObject
@property (nonatomic, readonly) STPThreeDSecureConfiguration *configuration;
@property (nonatomic, readonly) id<STPBackendAPIAdapter> apiAdapter;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                     configuration:(STPThreeDSecureConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (void)startThreeDSecureFlowWithParams:(STPThreeDSecureParams *)params
               presentingViewController:(UIViewController *)viewController
                             completion:(STPThreeDSecureFlowCompletionBlock)completion;

- (void)cancelThreeDSecureFlow;

@end

@interface STPThreeDSecureConfiguration : NSObject
@property (nonatomic) STPThreeDSecureSupportLevel threeDSecureSupportLevel NS_EXTENSION_UNAVAILABLE("3D Secure support not available in extension");
@property (nonatomic, readonly) NSURL *threeDSecureReturnUrl;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithReturnUrl:(NSURL *)returnUrl NS_DESIGNATED_INITIALIZER;

- (BOOL)shouldRequestThreeDSecureForCard:(STPCard *)card;
@end



NS_ASSUME_NONNULL_END
