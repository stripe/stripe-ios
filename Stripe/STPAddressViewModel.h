//
//  STPAddressViewModel.h
//  Stripe
//
//  Created by Jack Flintermann on 4/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPAddress.h"
#import "STPAddressFieldTableViewCell.h"

@interface STPAddressViewModel : NSObject

@property(nonatomic, readonly)NSArray<STPAddressFieldTableViewCell *> *addressCells;
- (instancetype)initWithRequiredBillingFields:(STPBillingAddressField)requiredBillingAddressFields;
- (STPAddressFieldTableViewCell *)cellAtIndex:(NSInteger)index;

@end
