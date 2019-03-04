//
//  STPPaymentOptionsInternalViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCoreTableViewController.h"
#import "STPBlocks.h"

@class STPAddress, STPCustomerContext, STPPaymentConfiguration, STPPaymentOptionTuple, STPToken, STPUserInformation;

@protocol STPPaymentOption;

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentOptionsInternalViewControllerDelegate

- (void)internalViewControllerDidSelectPaymentMethod:(id<STPPaymentOption>)paymentMethod;
- (void)internalViewControllerDidDeletePaymentMethod:(id<STPPaymentOption>)paymentMethod;
- (void)internalViewControllerDidCreateSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion;
- (void)internalViewControllerDidCancel;

@end

@interface STPPaymentOptionsInternalViewController : STPCoreTableViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                      customerContext:(nullable STPCustomerContext *)customerContext
                                theme:(STPTheme *)theme
                 prefilledInformation:(nullable STPUserInformation *)prefilledInformation
                      shippingAddress:(nullable STPAddress *)shippingAddress
                   paymentMethodTuple:(STPPaymentOptionTuple *)tuple
                             delegate:(id<STPPaymentOptionsInternalViewControllerDelegate>)delegate;

- (void)updateWithPaymentMethodTuple:(STPPaymentOptionTuple *)tuple;

@property (nonatomic, strong, nullable) UIView *customFooterView;
@property (nonatomic, assign) BOOL createsCardSources;


@end

NS_ASSUME_NONNULL_END
