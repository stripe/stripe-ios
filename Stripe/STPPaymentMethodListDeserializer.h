//
//  STPPaymentMethodListDeserializer.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/16/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentMethod;

/**
 Deserializes the response returned from https://stripe.com/docs/api/payment_methods/list
 */
@interface STPPaymentMethodListDeserializer : NSObject <STPAPIResponseDecodable>

@property (nonatomic, readonly) NSArray<STPPaymentMethod *> *paymentMethods;

@end
NS_ASSUME_NONNULL_END
