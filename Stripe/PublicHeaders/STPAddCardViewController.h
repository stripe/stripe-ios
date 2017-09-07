//
//  STPAddCardViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPAPIClient.h"
#import "STPAddress.h"
#import "STPBlocks.h"
#import "STPCardParams.h"
#import "STPCoreTableViewController.h"
#import "STPFooterViewSupporting.h"
#import "STPPaymentConfiguration.h"
#import "STPTheme.h"
#import "STPUserInformation.h"

NS_ASSUME_NONNULL_BEGIN

@class STPAddCardViewController;
@protocol STPAddCardViewControllerDelegate;

/** This view controller contains a credit card entry form that the user can fill out. On submission, it will use the Stripe API to convert the user's card details to a Stripe token. It renders a right bar button item that submits the form, so it must be shown inside a `UINavigationController`.
 */
@interface STPAddCardViewController : STPCoreTableViewController <STPFooterViewSupporting>

/**
 A convenience initializer; equivalent to calling `initWithConfiguration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]`.
 */
- (instancetype)init;

/**
 Initializes a new `STPAddCardViewController` with the provided configuration and theme. Don't forget to set the `delegate` property after initialization.

 @param configuration The configuration to use (this determines the Stripe publishable key to use, the required billing address fields, whether or not to use SMS autofill, etc). @see STPPaymentConfiguration
 @param theme         The theme to use to inform the view controller's visual appearance. @see STPTheme
 */
- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme;

/**
 The view controller's delegate. This must be set before showing the view controller in order for it to work properly. @see STPAddCardViewControllerDelegate
 */
@property (nonatomic, weak, nullable) id<STPAddCardViewControllerDelegate>delegate;

/**
 You can set this property to pre-fill any information you've already collected from your user. @see STPUserInformation.h
 */
@property (nonatomic, strong, nullable) STPUserInformation *prefilledInformation;

/**
 If you're using the token generated from STPAddCardViewController to make a Managed Account, you should set this property to the currency that account will use. Otherwise, you should leave it empty. For more information, see https://stripe.com/docs/api#create_card_token-card-currency
 */
@property (nonatomic, copy, nullable) NSString *managedAccountCurrency;


@end

/**
 An `STPAddCardViewControllerDelegate` is notified when an `STPAddCardViewController` successfully creates a card token or is cancelled. It has internal error-handling logic, so there's no error case to deal with.
 */
@protocol STPAddCardViewControllerDelegate <NSObject>

/**
 Called when the user cancels adding a card. You should dismiss (or pop) the view controller at this point.

 @param addCardViewController the view controller that has been cancelled
 */
- (void)addCardViewControllerDidCancel:(STPAddCardViewController *)addCardViewController;

/**
 This is called when the user successfully adds a card and tokenizes it with Stripe. You should send the token to your backend to store it on a customer, and then call the provided `completion` block when that call is finished. If an error occurred while talking to your backend, call `completion(error)`, otherwise, dismiss (or pop) the view controller.

 @param addCardViewController the view controller that successfully created a token
 @param token                 the Stripe token that was created. @see STPToken
 @param completion            call this callback when you're done sending the token to your backend
 */
- (void)addCardViewController:(STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
