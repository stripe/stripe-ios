//
//  STPSourceListViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentMethod;
@class STPPaymentContext, STPPaymentMethodsViewController;

@protocol STPPaymentMethodsViewControllerDelegate <NSObject>

- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod;
- (void)paymentMethodsViewControllerDidCancel:(STPPaymentMethodsViewController *)paymentMethodsViewController;

@end

@interface STPPaymentMethodsViewController : UIViewController

@property(nonatomic, readonly)STPPaymentContext *paymentContext;

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext
                              delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate;
@property(nonatomic, weak, nullable, readonly)id<STPPaymentMethodsViewControllerDelegate>delegate;

@end

NS_ASSUME_NONNULL_END
