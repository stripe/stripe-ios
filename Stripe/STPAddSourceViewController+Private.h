//
//  STPAddSourceViewController+Private.h
//  Stripe
//
//  Created by Ben Guo on 3/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPAddSourceViewController.h"
#import "STPAddress.h"

@class STPPaymentConfiguration, STPTheme;

@interface STPAddSourceViewController (Private)

@property(nonatomic)STPAddress *shippingAddress;

@end
