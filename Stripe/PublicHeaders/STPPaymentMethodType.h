//
//  STPPaymentMethodType.h
//  Stripe
//
//  Created by Brian Dorfman on 3/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  This class provides opaque objects that represent the different types of
 *  payment methods that a user can use to pay from the pre-built UI screens
 *  provided by this SDK (Eg "Credit cards", "Apple Pay", or "iDEAL")
 *  
 *  @see `STPPaymentMethodsViewController`.
 *
 *  You should not instantiate new objects of this class manually, instead use
 *  one of the provided class methods to retrieve objects.
 */
@interface STPPaymentMethodType : NSObject <STPPaymentMethod>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)creditCard;
+ (instancetype)applePay;
+ (instancetype)bancontact;
+ (instancetype)giropay;
+ (instancetype)ideal;
+ (instancetype)sepaDebit;
+ (instancetype)sofort;

@end

NS_ASSUME_NONNULL_END
