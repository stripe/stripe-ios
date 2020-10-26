//
//  STPPaymentMethodGrabPayParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 7/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing parameters used to create a GrabPay Payment Method
 */
@interface STPPaymentMethodGrabPayParams : NSObject  <STPFormEncodable>

@end

NS_ASSUME_NONNULL_END
