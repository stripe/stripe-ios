//
//  STPPaymentMethodGiropayParams.h
//  Stripe
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An object representing parameters used to create a giropay Payment Method
*/
@interface STPPaymentMethodGiropayParams : NSObject <STPFormEncodable>

@end

NS_ASSUME_NONNULL_END
