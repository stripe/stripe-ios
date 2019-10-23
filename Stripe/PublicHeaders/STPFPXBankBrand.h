//
//  STPFPXBankBrand.h
//  StripeiOS
//
//  Created by David Estes on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The various bank brands available for FPX payments.
 */
typedef NS_ENUM(NSInteger, STPFPXBankBrand) {

    /**
     Affin Bank
     */
    STPFPXBankBrandAffinBank,

    /**
     Alliance Bank
     */
    STPFPXBankBrandAllianceBank,

    /**
     AmBank
     */
    STPFPXBankBrandAmbank,

    /**
     Bank Islam
     */
    STPFPXBankBrandBankIslam,

    /**
     Bank Muamalat
     */
    STPFPXBankBrandBankMuamalat,

    /**
     Bank Rakyat
     */
    STPFPXBankBrandBankRakyat,

    /**
     BSN
     */
    STPFPXBankBrandBSN,

    /**
     CIMB Clicks
     */
    STPFPXBankBrandCIMB,
    
    /**
     Hong Leong Bank
     */
    STPFPXBankBrandHongLeongBank,
    
    /**
     HSBC BANK
     */
    STPFPXBankBrandHSBC,
    
    /**
     KFH
     */
    STPFPXBankBrandKFH,
    
    /**
     Maybank2E
     */
    STPFPXBankBrandMaybank2E,
    
    /**
     Maybank2U
     */
    STPFPXBankBrandMaybank2U,
    
    /**
     OCBC Bank
     */
    STPFPXBankBrandOcbc,
    
    /**
     Public Bank
     */
    STPFPXBankBrandPublicBank,
    
    /**
     RHB Bank
     */
    STPFPXBankBrandRHB,
    
    /**
     Standard Chartered
     */
    STPFPXBankBrandStandardChartered,
    
    /**
     UOB Bank
     */
    STPFPXBankBrandUOB,
    
    /**
     An unknown bank
     */
    STPFPXBankBrandUnknown,
};

/**
 Returns a string representation for the provided bank brand;
 i.e. `[NSString stringFromBrand:STPCardBrandUob] ==  @"UOB Bank"`.
 
 @param brand The brand you want to convert to a string
 
 @return A string representing the brand, suitable for displaying to a user.
 */
NSString * STPStringFromFPXBankBrand(STPFPXBankBrand brand);

/**
 Returns a bank brand provided a string representation identifying a bank brand;
 i.e. `STPFPXBankBrandFromIdentifier(@"uob") == STPCardBrandUob`.
 
 @param identifier The identifier for the brand
 
 @return The STPFPXBankBrand enum value
 */
STPFPXBankBrand STPFPXBankBrandFromIdentifier(NSString *identifier);

/**
 Returns a string representation identifying the provided bank brand;
 i.e. `STPIdentifierFromFPXBankBrand(STPCardBrandUob) ==  @"uob"`.
 
 @param brand The brand you want to convert to a string
 
 @return A string representing the brand, suitable for using with the Stripe API.
 */
NSString * STPIdentifierFromFPXBankBrand(STPFPXBankBrand brand);

/**
 Returns the code identifying the provided bank brand in the FPX status API;
 i.e. `STPIdentifierFromFPXBankBrand(STPCardBrandUob) ==  @"UOB0226"`.
 
 @param brand The brand you want to convert to an FPX bank code
 @param isBusiness Requests the code for the business version of this bank brand, which may be different from the code used for individual accounts
 
 @return A string representing the brand, suitable for checking against the FPX status API.
 */
NSString * STPBankCodeFromFPXBankBrand(STPFPXBankBrand brand, BOOL isBusiness);
