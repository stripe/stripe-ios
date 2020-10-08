//
//  STPPaymentMethodiDEALParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing parameters used to create an iDEAL Payment Method
 */
@interface STPPaymentMethodiDEALParams : NSObject <STPFormEncodable>

/**
 The customer’s bank.
 */
@property (nonatomic, nullable, copy) NSString *bankName;

@end

NS_ASSUME_NONNULL_END
