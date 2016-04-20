//
//  STPSourceListViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPPaymentMethod.h"

@class STPAPIClient, STPPaymentMethodsViewController, STPPaymentMethodsStore;

@protocol STPBackendAPIAdapter, STPSource, STPPaymentMethod;

@protocol STPPaymentMethodsViewControllerDelegate <NSObject>

- (void)paymentMethodsViewController:(nonnull STPPaymentMethodsViewController *)viewController
          didFinishWithPaymentMethod:(nullable id<STPPaymentMethod>)paymentMethod;

@end

@interface STPPaymentMethodsViewController : UIViewController

- (nonnull instancetype)initWithPaymentMethodsStore:(nonnull STPPaymentMethodsStore *)paymentMethodsStore
                                           delegate:(nonnull id<STPPaymentMethodsViewControllerDelegate>)delegate;

@end
