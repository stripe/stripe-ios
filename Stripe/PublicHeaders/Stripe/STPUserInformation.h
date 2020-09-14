//
//  STPUserInformation.h
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAddress.h"

@class STPPaymentMethodBillingDetails;

NS_ASSUME_NONNULL_BEGIN

/**
 You can use this class to specify information that you've already collected 
 from your user. You can then set the `prefilledInformation` property on 
 `STPPaymentContext`, `STPAddCardViewController`, etc and it will pre-fill 
 this information whenever possible.
 */
@interface STPUserInformation : NSObject<NSCopying>

/**
 The user's billing address. When set, the add card form will be filled with 
 this address. The user will also have the option to fill their shipping address 
 using this address.
 
 @note Set this using `setBillingAddressWithBillingDetails:` to use the billing
 details from an `STPPaymentMethod` or `STPPaymentMethodParams` instance.
 */
@property (nonatomic, strong, nullable) STPAddress *billingAddress;

/**
 The user's shipping address. When set, the shipping address form will be filled
 with this address. The user will also have the option to fill their billing
 address using this address.
 */
@property (nonatomic, strong, nullable) STPAddress *shippingAddress;

/**
 A convenience method to populate `billingAddress` with a PaymentMethod's billing details.
 
 @note Calling this overwrites the value of `billingAddress`.
 */
- (void)setBillingAddressWithBillingDetails:(STPPaymentMethodBillingDetails *)billingDetails
NS_SWIFT_NAME(setBillingAddress(with:));

@end

NS_ASSUME_NONNULL_END
