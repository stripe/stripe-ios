//
//  STPAutomaticPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"

@interface STPAutomaticPaymentMethod : NSObject <STPPaymentMethod>

- (instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods;

@end
