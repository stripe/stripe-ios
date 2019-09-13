//
//  STPCardBrand.h
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The various card brands to which a payment card can belong.
 */
typedef NS_ENUM(NSInteger, STPCardBrand) {

    /**
     Visa card
     */
    STPCardBrandVisa,

    /**
     American Express card
     */
    STPCardBrandAmex,

    /**
     Mastercard card
     */
    STPCardBrandMasterCard,

    /**
     Discover card
     */
    STPCardBrandDiscover,

    /**
     JCB card
     */
    STPCardBrandJCB,

    /**
     Diners Club card
     */
    STPCardBrandDinersClub,

    /**
     UnionPay card
     */
    STPCardBrandUnionPay,

    /**
     An unknown card brand type
     */
    STPCardBrandUnknown,
};

/**
 Returns a string representation for the provided card brand;
 i.e. `[NSString stringFromBrand:STPCardBrandVisa] ==  @"Visa"`.
 
 @param brand the brand you want to convert to a string
 
 @return A string representing the brand, suitable for displaying to a user.
 */
NSString * STPStringFromCardBrand(STPCardBrand brand);
