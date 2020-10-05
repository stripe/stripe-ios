//
//  STPPaymentMethodPaypalParams.h
//  StripeiOS
//
//  Created by Cameron Sabol on 10/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An object representing parameters used to create a Paypal Payment Method
*/
@interface STPPaymentMethodPaypalParams : NSObject <STPFormEncodable>

@end

NS_ASSUME_NONNULL_END
