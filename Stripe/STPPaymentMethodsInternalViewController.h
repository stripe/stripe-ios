//
//  STPPaymentMethodsInternalViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCoreTableViewController.h"
#import "STPBlocks.h"

@class STPAddress, STPCustomerContext, STPPaymentConfiguration, STPPaymentMethodTuple, STPToken, STPUserInformation;

@protocol STPPaymentMethod;

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentMethodsInternalViewControllerDelegate

- (void)internalViewControllerDidSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod;
- (void)internalViewControllerDidDeletePaymentMethod:(id<STPPaymentMethod>)paymentMethod;
- (void)internalViewControllerDidCreateToken:(STPToken *)token completion:(STPErrorBlock)completion;
- (void)internalViewControllerDidCancel;

@end

@interface STPPaymentMethodsInternalViewController : STPCoreTableViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                      customerContext:(nullable STPCustomerContext *)customerContext
                                theme:(STPTheme *)theme
                 prefilledInformation:(nullable STPUserInformation *)prefilledInformation
                      shippingAddress:(nullable STPAddress *)shippingAddress
                   paymentMethodTuple:(STPPaymentMethodTuple *)tuple
                             delegate:(id<STPPaymentMethodsInternalViewControllerDelegate>)delegate;

- (void)updateWithPaymentMethodTuple:(STPPaymentMethodTuple *)tuple;

@property (nonatomic, strong, nullable) UIView *customFooterView;


@end

NS_ASSUME_NONNULL_END
