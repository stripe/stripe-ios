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
     An FPX payment method.
     */
    STPPaymentMethodTypeFPX,
    
    /**
     A card present payment method.
     */
    STPPaymentMethodTypeCardPresent,

    /**
     A SEPA Debit payment method.
     */
    STPPaymentMethodTypeSEPADebit,

    /**
     An AU BECS Debit payment method.
     */
    STPPaymentMethodTypeAUBECSDebit,
    
    /**
     A Bacs Debit payment method.
     */
    STPPaymentMethodTypeBacsDebit,

    /**
     A giropay payment method.
     */
    STPPaymentMethodTypeGiropay,

    /**
     A Przelewy24 Debit payment method.
     */
    STPPaymentMethodTypePrzelewy24,

    /**
    A Bancontact payment method.
    */
    STPPaymentMethodTypeBancontact,

    /**
     An unknown type.
     */
    STPPaymentMethodTypeUnknown,
};
