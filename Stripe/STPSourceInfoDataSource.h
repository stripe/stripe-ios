//
//  STPSourceInfoDataSource.h
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

@protocol STPSelectorDataSource;
@class STPTextFieldTableViewCell, STPPaymentMethodType;

@interface STPSourceInfoDataSource : NSObject

@property (nonatomic) STPPaymentMethodType *paymentMethodType;
@property (nonatomic) STPSourceParams *sourceParams;
@property (nonatomic, copy) NSArray<STPTextFieldTableViewCell *>*cells;
@property (nonatomic) id<STPSelectorDataSource>selectorDataSource;

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams;
- (STPSourceParams *)completeSourceParams;

@end
