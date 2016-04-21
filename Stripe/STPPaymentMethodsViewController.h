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

typedef void (^STPPaymentMethodSelectionBlock)(id<STPPaymentMethod> __nullable selectedPaymentMethod);

@protocol STPPaymentMethod;
@class STPPaymentContext;

@interface STPPaymentMethodsViewController : UIViewController

@property(nonatomic, readonly)STPPaymentContext *paymentContext;

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext onSelection:(STPPaymentMethodSelectionBlock)onSelection;

@end

NS_ASSUME_NONNULL_END
