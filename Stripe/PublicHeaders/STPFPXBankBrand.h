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
 
 @param brand the brand you want to convert to a string
 
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
 
 @param brand the brand you want to convert to a string
 
 @return A string representing the brand, suitable for using with the service.
 */
NSString * STPIdentifierFromFPXBankBrand(STPFPXBankBrand brand);
