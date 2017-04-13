//
//  STPPaymentConfiguration+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentConfiguration ()

@property(nonatomic, readonly)BOOL applePayEnabled;
@property (nonatomic, copy) NSOrderedSet<STPPaymentMethodType *> *availablePaymentMethodTypesSet;

/**
 Optional block to get around app extension restrictions
 It is set by returnURL setter so should exist for anyone using redirect sources with payment context
 
 It handles opening the redirect url, subscribes for foreground notifications, 
 does some polling when the customer comes back, and then returns you the completed source object
 */
@property (nonatomic, copy, nullable) void (^sourceURLRedirectBlock)(STPAPIClient *apiClient, STPSource *source, UIViewController *presentingViewController, STPSourceCompletionBlock completion);


/**
 Cancels the current source url redirect, if any.
 
 Nullable block to get around app extension restrictions. Non-nil if there is a redirect in progress.
 */
@property (nonatomic, copy, nullable) STPVoidBlock cancelSourceURLRedirectBlock;


/**
 This gets around accessing the returnURL property with app extension restrictions
 
 returnURL is publicly only accessible in app extensions. For internal convenience,
 this block is always available non-nil. It just returns nil if there is no 
 returnURL set or else returns the returnURL

 */
@property (nonatomic, copy)  NSURL * _Nullable (^returnURLBlock)();

/**
 This gets around accessing the threeDSecureSupportType property with app extension restrictions

 Same logic as returnURLBlock.

 */
@property (nonatomic, copy)  STPThreeDSecureSupportType (^threeDSecureSupportTypeBlock)();

@end

NS_ASSUME_NONNULL_END
