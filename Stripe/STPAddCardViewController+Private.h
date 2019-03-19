//
//  STPAddCardViewController+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 6/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddCardViewController.h"
#import "STPAddress.h"

@class STPPaymentConfiguration, STPTheme;

@interface STPAddCardViewController (Private)

@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) BOOL alwaysShowScanCardButton;
@property (nonatomic) BOOL alwaysEnableDoneButton;

- (void)commonInitWithConfiguration:(STPPaymentConfiguration *)configuration;

@end
