//
//  STPCoreViewController.h
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPTheme;

NS_ASSUME_NONNULL_BEGIN

@interface STPCoreViewController : UIViewController

@property (nonatomic) STPTheme *theme;

- (instancetype)init;
- (instancetype)initWithTheme:(STPTheme *)theme NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

// For overridding in subclasses
- (void)handleBackOrCancelTapped:(nullable id)sender;
- (void)createAndSetupViews NS_REQUIRES_SUPER;
- (void)updateAppearance NS_REQUIRES_SUPER;

- (void)viewWillAppear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewWillDisappear:(BOOL)animated NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END

