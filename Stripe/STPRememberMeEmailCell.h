//
//  STPRememberMeEmailCell.h
//  Stripe
//
//  Created by Jack Flintermann on 5/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldTableViewCell.h"
#import "STPActivityIndicatorView.h"

@interface STPRememberMeEmailCell : STPAddressFieldTableViewCell

@property(nonatomic, weak, readonly)STPActivityIndicatorView *activityIndicator;

- (instancetype)initWithDelegate:(id<STPAddressFieldTableViewCellDelegate>)delegate;

@end
