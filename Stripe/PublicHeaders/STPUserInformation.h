//
//  STPUserInformation.h
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAddress.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  You can use this class to specify information that you've already collected
 *  from your user. You can then set the `prefilledInformation` property on
 *  `STPPaymentContext`, `STPAddSourceViewController`, etc and it will pre-fill
 *  this information whenever possible.
 */
@interface STPUserInformation : NSObject<NSCopying>

/**
 *  The user's email address.
 */
@property(nonatomic, copy, nullable)NSString *email;

/**
 *  The user's phone number. When set, this property will automatically strip
 *  any non-numeric characters from the string you specify.
 */
@property(nonatomic, copy, nullable)NSString *phone;

/**
 *  The user's billing address. If set, address fields will be prefilled with 
 *  this information when your customer adds a new source.
 */
@property(nonatomic, copy, nullable)STPAddress *billingAddress;

/**
 *  The bank your customer uses for iDEAL payments. 
 *  https://stripe.com/docs/sources/ideal#optional-specifying-the-customers-bank
 */
@property(nonatomic, copy, nullable)NSString *idealBank;

@end

NS_ASSUME_NONNULL_END
