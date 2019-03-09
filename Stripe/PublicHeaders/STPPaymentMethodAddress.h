//
//  STPPaymentMethodAddress.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The billing address, a property on `STPPaymentMethodBillingDetails`
 */
@interface STPPaymentMethodAddress : NSObject <STPAPIResponseDecodable, STPFormEncodable>

/**
 City/District/Suburb/Town/Village.
*/
@property (nonatomic, copy, nullable, readwrite) NSString *city;

/**
 2-letter country code.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *country;

/**
 Address line 1 (Street address/PO Box/Company name).
 */
@property (nonatomic, copy, nullable, readwrite) NSString *line1;

/**
 Address line 2 (Apartment/Suite/Unit/Building).
 */
@property (nonatomic, copy, nullable, readwrite) NSString *line2;

/**
 ZIP or postal code.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *postalCode;

/**
 State/County/Province/Region.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *state;

@end

NS_ASSUME_NONNULL_END
