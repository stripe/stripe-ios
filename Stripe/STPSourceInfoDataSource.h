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

/// If YES, the data source must be verified by the user even if
/// completedSourceParams is non-nil.
@property (nonatomic, assign) BOOL requiresUserVerification;

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                prefilledInformation:(STPUserInformation *)prefilledInfo;

/// If the data source contains incomplete info, this method will return nil.
- (STPSourceParams *)completeSourceParams;

@end
