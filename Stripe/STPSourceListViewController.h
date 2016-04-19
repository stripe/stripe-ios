//
//  STPSourceListViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPAPIClient, STPSourceListViewController;

@protocol STPBackendAPIAdapter, STPSource;

@protocol STPSourceListViewControllerDelegate <NSObject>

- (void)sourceListViewControllerDidTapAddButton:(nonnull STPSourceListViewController *)viewController;
- (void)sourceListViewController:(nonnull STPSourceListViewController *)viewController
                 didSelectSource:(nonnull id<STPSource>)source;

@end

@interface STPSourceListViewController : UIViewController

- (nonnull instancetype)initWithapiAdapter:(nonnull id<STPBackendAPIAdapter>)apiAdapter
                                      delegate:(nonnull id<STPSourceListViewControllerDelegate>)delegate;
@property(nonatomic, readonly, nonnull)id<STPBackendAPIAdapter> apiAdapter;

- (void)reload;

@end
