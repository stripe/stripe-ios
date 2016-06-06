//
//  STPPaymentResult.h
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@class STPAddress;

@interface STPPaymentResult : NSObject

@property(nonatomic, readonly)id<STPSource> source;

- (nonnull instancetype)initWithSource:(id<STPSource>)source;

@end

NS_ASSUME_NONNULL_END
