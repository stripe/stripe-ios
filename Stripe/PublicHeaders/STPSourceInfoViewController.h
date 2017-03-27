//
//  STPSourceInfoViewController.h
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPCoreTableViewController.h"
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPSourceInfoViewControllerDelegate;
@class STPSourceParams, STPPaymentConfiguration, STPUserInformation;

typedef void (^STPSourceInfoCompletionBlock)(STPSourceParams * _Nullable sourceParams);

/** 
 *  You can use this view controller to collect information for payment sources
 *  that require additional information upon creation (e.g. iDEAL, which requires 
 *  your customer's name and bank.) Note that this view controller renders a right 
 *  bar button item that submits the form, so it must be shown inside a
 *  `UINavigationController`.
 */
@interface STPSourceInfoViewController : STPCoreTableViewController

/**
 *  Initializes a new `STPSourceInfoViewController` with the provided parameters. 
 *  When the user submits the form, the completion block will be called with an
 *  STPSourceParams object, populated with information entered by the user.
 *  If the user cancels, the completion block will be called with nil.
 *  If the given source type is unsupported, this initializer will return nil.
 *
 *  @param type                   The type of the source.
 *  @param amount                 The amount of the source.
 *  @param configuration          The configuration to use. This determines the source's returnURL.
 *  @param prefilledInformation   Use this to provide any information you've already collected from your user.
 *  @param theme                  The theme to use to inform the view controller's visual appearance. @see STPTheme
 *  @param completion             The completion block called when the user submits the forms or cancels.
 */
- (nullable instancetype)initWithSourceType:(STPSourceType)type
                                     amount:(NSInteger)amount
                              configuration:(STPPaymentConfiguration *)configuration
                       prefilledInformation:(STPUserInformation *)prefilledInformation
                                      theme:(STPTheme *)theme
                                 completion:(STPSourceInfoCompletionBlock)completion;

/**
 *  You should check this property after initializing `STPSourceInfoViewController`.
 *  If this property contains an STPSourceParams object, you already have sufficient
 *  information about the source, and can immediately use this object to create
 *  a source. Otherwise, if this property is nil, you must present the view controller
 *  to gather additional info about the source from your user. When the user submits
 *  the form, you can use the STPSourceParams object returned to your delegate to
 *  create a source.
 */
@property(nullable, nonatomic, readonly) STPSourceParams *completeSourceParams;

/**
 *  The view controller's delegate. This must be set before showing the view 
 *  controller in order for it to work properly. @see STPSourceInfoViewControllerDelegate
 */
@property(nonatomic, weak) id<STPSourceInfoViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
