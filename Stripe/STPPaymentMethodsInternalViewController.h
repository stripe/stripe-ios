//
//  STPPaymentMethodsInternalViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddress.h"
#import "STPCoreTableViewController.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentMethodTuple.h"

@protocol STPPaymentMethodsInternalViewControllerDelegate

- (void)internalViewControllerDidSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod;
- (void)internalViewControllerDidCreateToken:(STPToken *)token
                                  completion:(STPErrorBlock)completion;
- (void)internalViewControllerDidCancel;

@end

@interface STPPaymentMethodsInternalViewController : STPCoreTableViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                 prefilledInformation:(STPUserInformation *)prefilledInformation
                      shippingAddress:(STPAddress *)shippingAddress
                   paymentMethodTuple:(STPPaymentMethodTuple *)tuple
                             delegate:(id<STPPaymentMethodsInternalViewControllerDelegate>)delegate;

- (void)updateWithPaymentMethodTuple:(STPPaymentMethodTuple *)tuple;

@end
