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
     MasterCard card
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

/**
 This parses a string representing a card's brand into the appropriate
 STPCardBrand enum value,
 i.e. `[STPCard brandFromString:@"American Express"] == STPCardBrandAmex`.
 
 The string values themselves are specific to Stripe as listed in the Stripe API
 documentation.
 
 @see https://stripe.com/docs/api#card_object-brand
 
 @param string a string representing the card's brand as returned from
 the Stripe API
 
 @return an enum value mapped to that string. If the string is unrecognized,
 returns STPCardBrandUnknown.
 */
STPCardBrand STPCardBrandFromString(NSString *string);
