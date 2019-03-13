//
//  STPPaymentMethodEnums.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/12/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

/**
 The type of the PaymentMethod.
 */
typedef NS_ENUM(NSUInteger, STPPaymentMethodType) {
    /**
     A card payment method.
     */
    STPPaymentMethodTypeCard,
    
    /**
     An iDEAL payment method.
     */
    STPPaymentMethodTypeiDEAL,
    
    /**
     A card present payment method.
     */
    STPPaymentMethodTypeCardPresent,
    
    /**
     An unknown type.
     */
    STPPaymentMethodTypeUnknown,
};
