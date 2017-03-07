//
//  STPSectionHeaderView.h
//  Stripe
//
//  Created by Ben Guo on 1/3/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPSource.h"
#import "STPTheme.h"

NS_ASSUME_NONNULL_BEGIN

@class STPAddressViewModel, STPPaymentConfiguration;

@interface STPSectionHeaderView : UIView

@property(nonatomic, nonnull)STPTheme *theme;
@property(nonatomic, copy, nullable)NSString *title;
@property(nonatomic, nullable, weak)UIButton *button;
@property(nonatomic)BOOL buttonHidden;

+ (instancetype)addressHeaderWithConfiguration:(STPPaymentConfiguration *)config
                                    sourceType:(STPSourceType)sourceType
                              addressViewModel:(STPAddressViewModel *)addressViewModel
                               shippingAddress:(STPAddress *)shippingAddress;

@end

NS_ASSUME_NONNULL_END
