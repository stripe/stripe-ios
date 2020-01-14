//
//  STPPaymentOptionsInternalViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCoreTableViewController.h"
#import "STPBlocks.h"

@class STPAddress, STPCustomerContext, STPPaymentConfiguration, STPPaymentOptionTuple, STPPaymentMethod, STPUserInformation, STPAPIClient;

@protocol STPPaymentOption;

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentOptionsInternalViewControllerDelegate

- (void)internalViewControllerDidSelectPaymentOption:(id<STPPaymentOption>)paymentOption;
- (void)internalViewControllerDidDeletePaymentOption:(id<STPPaymentOption>)paymentOption;
- (void)internalViewControllerDidCreatePaymentOption:(id<STPPaymentOption>)paymentOption completion:(STPErrorBlock)completion;
- (void)internalViewControllerDidCancel;

@end

@interface STPPaymentOptionsInternalViewController : STPCoreTableViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                      customerContext:(nullable STPCustomerContext *)customerContext
                            apiClient:(STPAPIClient *)apiClient
                                theme:(STPTheme *)theme
                 prefilledInformation:(nullable STPUserInformation *)prefilledInformation
                      shippingAddress:(nullable STPAddress *)shippingAddress
                   paymentOptionTuple:(STPPaymentOptionTuple *)tuple
                             delegate:(id<STPPaymentOptionsInternalViewControllerDelegate>)delegate;

- (void)updateWithPaymentOptionTuple:(STPPaymentOptionTuple *)tuple;

@property (nonatomic, strong, nullable) UIView *customFooterView;
@property (nonatomic, strong, nullable) UIView *addCardViewControllerCustomFooterView;


@end

NS_ASSUME_NONNULL_END
