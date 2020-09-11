//
//  STPPaymentMethodSofortParams.h
//  Stripe
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An object representing parameters used to create a Sofort Payment Method
*/
@interface STPPaymentMethodSofortParams : NSObject <STPFormEncodable>

/**
 Two-letter ISO code representing the country the bank account is located in. Required.
 */
@property (nonatomic, nullable, copy) NSString *country;

@end

NS_ASSUME_NONNULL_END
