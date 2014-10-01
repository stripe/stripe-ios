//
//  STPTestPaymentCardSelectionTableViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPTestCardStore;

@interface STPTestPaymentCardSelectionTableViewController : UITableViewController
- (instancetype)initWithCardStore:(STPTestCardStore *)store;
@end
