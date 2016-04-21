//
//  STPCardPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPSource;

@interface STPCardPaymentMethod : NSObject <STPPaymentMethod>

@property (nonatomic, readonly) id<STPSource> source;

- (instancetype)initWithSource:(id<STPSource>)source;

@end

NS_ASSUME_NONNULL_END
