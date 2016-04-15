//
//  STPPaymentMethodCell.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol STPSource;

@interface STPPaymentMethodCell : UITableViewCell

- (void)configureWithSource:(id<STPSource>)source;

@end
