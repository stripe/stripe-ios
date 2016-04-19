//
//  STPCardPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"

@protocol STPSource;

@interface STPCardPaymentMethod : NSObject <STPPaymentMethod>

@property (nonnull, nonatomic, readonly) id<STPSource> source;

- (nonnull instancetype)initWithSource:(nonnull id<STPSource>)source;

@end
