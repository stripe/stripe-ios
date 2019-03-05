//
//  STPPaymentMethodBillingDetailsAddress.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodBillingDetailsAddress : NSObject

/**
 You cannot directly instantiate an `STPPaymentMethodBillingDetailsAddress`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodBillingDetailsAddress.")));

/**
 City/District/Suburb/Town/Village.
*/
@property (nonatomic, nullable, readonly) NSString *city;

/**
 2-letter country code.
 */
@property (nonatomic, nullable, readonly) NSString *country;

/**
 Address line 1 (Street address/PO Box/Company name).
 */
@property (nonatomic, nullable, readonly) NSString *line1;

/**
 Address line 2 (Apartment/Suite/Unit/Building).
 */
@property (nonatomic, nullable, readonly) NSString *line2;

/**
 ZIP or postal code.
 */
@property (nonatomic, nullable, readonly) NSString *postalCode;

/**
 State/County/Province/Region.
 */
@property (nonatomic, nullable, readonly) NSString *state;

@end

NS_ASSUME_NONNULL_END
