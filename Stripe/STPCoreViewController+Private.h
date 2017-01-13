//
//  STPCoreViewController+Private.h
//  Stripe
//
//  Created by Brian Dorfman on 1/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 This class extension contains properties and methods that are intended to 
 be for private Stripe usage only, and are here to be hidden from the public
 api in STPCoreViewController.h
 
 All Stripe view controllers which inherit from STPCoreViewController should 
 also import this file.
 */
@interface STPCoreViewController ()

@property (nonatomic) STPTheme *theme;
@property(nonatomic) UIBarButtonItem *cancelItem;
@property(nonatomic) UIBarButtonItem *backItem;

/**
 All designated initializers funnel through this method to do their setup

 @param theme Initial theme for this view controller
 */
- (void)commonInitWithTheme:(STPTheme *)theme NS_REQUIRES_SUPER;

/**
 Called by the automatically-managed back/cancel button

 By default pops the top item off the navigation stack, or if we are the
 root of the navigation controller, dimisses presentation

 @param sender Sender of the target action, if applicable.
 */
- (void)handleBackOrCancelTapped:(nullable id)sender;


/**
 Called in viewDidLoad after doing base implementation, before
 calling updateAppearance
 */
- (void)createAndSetupViews NS_REQUIRES_SUPER;


/**
 Update views based on current STPTheme
 */
- (void)updateAppearance NS_REQUIRES_SUPER;


// These methods have significant code done in the base class and super must
// be called if they are overidden
- (void)viewDidLoad NS_REQUIRES_SUPER;
- (void)viewWillAppear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewWillDisappear:(BOOL)animated NS_REQUIRES_SUPER;
@end

NS_ASSUME_NONNULL_END
