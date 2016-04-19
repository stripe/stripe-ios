//
//  STPSourceListViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPPaymentMethod.h"

@class STPAPIClient, STPPaymentMethodsViewController;

@protocol STPBackendAPIAdapter, STPSource, STPPaymentMethod;

@protocol STPPaymentMethodsViewControllerDelegate <NSObject>

- (void)sourceListViewController:(nonnull STPPaymentMethodsViewController *)viewController
      didFinishWithPaymentMethod:(nullable id<STPPaymentMethod>)paymentMethod;

@end

@interface STPPaymentMethodsViewController : UIViewController

@property(nonatomic, readonly, nonnull)id<STPBackendAPIAdapter> apiAdapter;

- (nonnull instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods
                                             apiAdapter:(nonnull id<STPBackendAPIAdapter>)apiAdapter
                                               delegate:(nonnull id<STPPaymentMethodsViewControllerDelegate>)delegate;

@end
