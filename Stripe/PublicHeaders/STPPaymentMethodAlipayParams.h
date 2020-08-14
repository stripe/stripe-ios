//
//  STPPaymentMethodAlipayParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An object representing parameters used to create an Alipay Payment Method.

There are currently no parameters to pass.

@see https://site-admin.stripe.com/docs/api/payment_methods/create#create_payment_method-alipay
*/
@interface STPPaymentMethodAlipayParams : NSObject <STPFormEncodable>

@end

NS_ASSUME_NONNULL_END
