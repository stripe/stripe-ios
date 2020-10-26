//
//  STPPaymentMethodCardWallet.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentMethodCardWalletVisaCheckout, STPPaymentMethodCardWalletMasterpass;

NS_ASSUME_NONNULL_BEGIN

/**
 The type of Card Wallet.
 */
typedef NS_ENUM(NSUInteger, STPPaymentMethodCardWalletType) {
    
    /**
     Amex Express Checkout
     */
    STPPaymentMethodCardWalletTypeAmexExpressCheckout,
    
    /**
     Apple Pay
     */
    STPPaymentMethodCardWalletTypeApplePay,
    
    /**
     Google Pay
     */
    STPPaymentMethodCardWalletTypeGooglePay,
    
    /**
     Masterpass
     */
    STPPaymentMethodCardWalletTypeMasterpass,
    
    /**
     Samsung Pay
     */
    STPPaymentMethodCardWalletTypeSamsungPay,
    
    /**
     Visa Checkout
     */
    STPPaymentMethodCardWalletTypeVisaCheckout,
    
    /**
     An unknown Card Wallet type.
     */
    STPPaymentMethodCardWalletTypeUnknown,
};

/**
 A Card Wallet.
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-wallet
 */
@interface STPPaymentMethodCardWallet : NSObject <STPAPIResponseDecodable>

/**
 The type of the Card Wallet. A matching property is populated if the type is `STPPaymentMethodCardWalletTypeMasterpass` or `STPPaymentMethodCardWalletTypeVisaCheckout` containing additional information specific to the Card Wallet type.
 */
@property (nonatomic, readonly) STPPaymentMethodCardWalletType type;

/**
 Contains additional Masterpass information, if the type of the Card Wallet is `STPPaymentMethodCardWalletTypeMasterpass`
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCardWalletMasterpass *masterpass;

/**
 Contains additional Visa Checkout information, if the type of the Card Wallet is `STPPaymentMethodCardWalletTypeVisaCheckout`
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCardWalletVisaCheckout *visaCheckout;

@end

NS_ASSUME_NONNULL_END
