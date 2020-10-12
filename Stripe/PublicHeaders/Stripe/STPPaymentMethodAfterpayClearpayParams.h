//
//  STPPaymentMethodAfterpayClearpayParams.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing parameters used to create an iDEAL Payment Method
 */
@interface STPPaymentMethodAfterpayClearpayParams : NSObject <STPFormEncodable>

@end

NS_ASSUME_NONNULL_END
