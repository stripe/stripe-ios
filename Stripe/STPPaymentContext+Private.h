//
//  STPPaymentContext+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "STPPaymentMethodTuple.h"
#import "STPPromise.h"
#import "STPShippingAddressViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentContext (Private)<STPPaymentMethodsViewControllerDelegate, STPShippingAddressViewControllerDelegate>

@property(nonatomic, readonly)STPPromise<STPPaymentMethodTuple *> *currentValuePromise;

@end

NS_ASSUME_NONNULL_END
