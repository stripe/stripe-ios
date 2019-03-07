//
//  STPPaymentMethodBillingDetailsAddress.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodBillingDetailsAddress : NSObject <STPAPIResponseDecodable>

/**
 City/District/Suburb/Town/Village.
*/
@property (nonatomic, nullable) NSString *city;

/**
 2-letter country code.
 */
@property (nonatomic, nullable) NSString *country;

/**
 Address line 1 (Street address/PO Box/Company name).
 */
@property (nonatomic, nullable) NSString *line1;

/**
 Address line 2 (Apartment/Suite/Unit/Building).
 */
@property (nonatomic, nullable) NSString *line2;

/**
 ZIP or postal code.
 */
@property (nonatomic, nullable) NSString *postalCode;

/**
 State/County/Province/Region.
 */
@property (nonatomic, nullable) NSString *state;

@end

NS_ASSUME_NONNULL_END
