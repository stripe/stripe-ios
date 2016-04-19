//
//  STPSourceCell.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBackendAPIAdapter.h"

@interface STPSourceCell : UITableViewCell

- (void)configureWithSource:(id<STPSource>)source selected:(BOOL)selected;

@end
