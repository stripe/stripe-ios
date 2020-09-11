//
//  STPPaymentMethodFPX.h
//  Stripe
//
//  Created by David Estes on 7/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An FPX Payment Method.
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-fpx
 */
@interface STPPaymentMethodFPX : NSObject <STPAPIResponseDecodable>

/**
 The customer’s bank identifier code.
 */
@property (nonatomic, nullable, readonly) NSString *bankIdentifierCode;

@end

NS_ASSUME_NONNULL_END

