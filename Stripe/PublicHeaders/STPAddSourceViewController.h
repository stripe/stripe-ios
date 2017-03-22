//
//  STPAddSourceViewController.h
//  Stripe
//
//  Created by Ben Guo on 2/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPAddSourceViewControllerDelegate;

/** You can use this view controller to collect information for reusable payment sources. It currently supports two source types, `STPSourceTypeCard` and `STPSourceTypeSEPADebit`. On submission, it will use the Stripe API to convert the information entered by the user into a Source object. It renders a right bar button item that submits the form, so it must be shown inside a `UINavigationController`.
 */
@interface STPAddSourceViewController : STPCoreTableViewController

/**
 *  Initializes a new `STPAddSourceViewController` for collecting information for the given source type. If the given source type is unsupported, this initializer will return nil. Don't forget to set the `delegate` property after initialization.
 *
 *  @param sourceType    The type of the source to collect information for. @see STPSourceType
 *  @param configuration The configuration to use. @see STPPaymentConfiguration
 *  @param theme         The theme to use to inform the view controller's visual appearance. @see STPTheme
 */
- (nullable instancetype)initWithSourceType:(STPSourceType)sourceType
                              configuration:(STPPaymentConfiguration *)configuration
                                      theme:(STPTheme *)theme;

/**
 *  The view controller's delegate. This must be set before showing the view controller in order for it to work properly. @see STPAddSourceViewControllerDelegate
 */
@property(nonatomic, weak)id<STPAddSourceViewControllerDelegate>delegate;

/**
 *  You can set this property to pre-fill any information you've already collected from your user. @see STPUserInformation.h
 */
@property(nonatomic)STPUserInformation *prefilledInformation;

@end

/**
 *  An `STPAddSourceViewControllerDelegate` is notified when an `STPAddSourceViewController` successfully creates a source or is cancelled. It has internal error-handling logic, so there's no error case to deal with.
 */
@protocol STPAddSourceViewControllerDelegate <NSObject>

/**
 *  Called when the user cancels adding a source. You should dismiss (or pop) the view controller at this point.
 *
 *  @param addSourceViewController the view controller that has been cancelled
 */
- (void)addSourceViewControllerDidCancel:(STPAddSourceViewController *)addSourceViewController;

/**
 *  This is called when the user successfully creates a source. You should send the source to your backend to store it on a customer, and then call the provided `completion` block when that call is finished. If an error occurred while talking to your backend, call `completion(error)`, otherwise, dismiss (or pop) the view controller.
 *
 *  @param addSourceViewController the view controller that successfully created a source
 *  @param source                  the source that was created. @see STPSource
 *  @param completion              call this callback when you're done sending the source to your backend
 */
- (void)addSourceViewController:(STPAddSourceViewController *)addSourceViewController
                didCreateSource:(STPSource *)source
                     completion:(STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
