//
//  STPPaymentMethodBancontact.h
//  StripeiOS
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A Bancontact Payment Method.
@see https://stripe.com/docs/payments/bancontact
*/
@interface STPPaymentMethodBancontact : NSObject<STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodBancontact.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodBancontact`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
