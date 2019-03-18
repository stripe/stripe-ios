//
//  STPPaymentContext+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "STPPaymentOptionTuple.h"
#import "STPPromise.h"
#import "STPShippingAddressViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentContext (Private)<STPPaymentOptionsViewControllerDelegate, STPShippingAddressViewControllerDelegate>

@property (nonatomic, readonly) STPPromise<STPPaymentOptionTuple *> *currentValuePromise;

- (void)removePaymentOption:(id<STPPaymentOption>)paymentOptionToRemove;

@end

NS_ASSUME_NONNULL_END
