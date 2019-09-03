//
//  STPApplePayPaymentOption.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentOption.h"

/**
 An empty class representing that the user wishes to pay via Apple Pay. This can
 be checked on an `STPPaymentContext`, e.g:
 
 ```
 if ([paymentContext.selectedPaymentOption isKindOfClass:[STPApplePayPaymentOption class]]) {
    // Don't ask the user for their card number; they want to pay with apple pay.
 }
 ```
 */
@interface STPApplePayPaymentOption : NSObject <STPPaymentOption>

@end
