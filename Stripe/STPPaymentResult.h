//
//  STPPaymentResult.h
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPSource.h"

@protocol STPSource;

@interface STPPaymentResult : NSObject

@property(nonatomic, readonly, nonnull) id<STPSource> source;
@property(nonatomic, readonly, nullable) NSString *customer;

- (nonnull instancetype)initWithSource:(nonnull id<STPSource>)source customer:(nullable NSString *)customer;

@end
