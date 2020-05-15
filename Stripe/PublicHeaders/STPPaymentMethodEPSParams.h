//
//  STPPaymentMethodEPSParams.h
//  StripeiOS
//
//  Created by Shengwei Wu on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An object representing parameters used to create a EPS Payment Method
*/
@interface STPPaymentMethodEPSParams : NSObject <STPFormEncodable>

@end

NS_ASSUME_NONNULL_END
