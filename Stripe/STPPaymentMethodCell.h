//
//  STPSourceCell.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBackendAPIAdapter.h"

@protocol STPPaymentMethod;

@interface STPPaymentMethodCell : UITableViewCell

- (void)configureWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod selected:(BOOL)selected;

@end
