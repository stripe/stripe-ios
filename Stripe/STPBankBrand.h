//
//  STPBankBrand.h
//  StripeiOS
//
//  Created by David Estes on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The supported bank types.
 */
typedef NS_ENUM(NSInteger, STPBankType) {
    
    /**
     FPX (Malaysia)
     */
    STPBankTypeFpx,
    
    /**
     An unknown bank type
     */
    STPBankTypeUnknown,
};


/**
 The various bank brands available for payments, currently only used for FPX.
 */
typedef NS_ENUM(NSInteger, STPBankBrand) {

    /**
     Affin Bank
     */
    STPBankBrandAffinBank,

    /**
     Alliance Bank
     */
    STPBankBrandAllianceBank,

    /**
     AmBank
     */
    STPBankBrandAmbank,

    /**
     Bank Islam
     */
    STPBankBrandBankIslam,

    /**
     Bank Muamalat
     */
    STPBankBrandBankMuamalat,

    /**
     Bank Rakyat
     */
    STPBankBrandBankRakyat,

    /**
     BSN
     */
    STPBankBrandBsn,

    /**
     CIMB Clicks
     */
    STPBankBrandCimb,
    
    /**
     Hong Leong Bank
     */
    STPBankBrandHongLeongBank,
    
    /**
     HSBC BANK
     */
    STPBankBrandHsbc,
    
    /**
     KFH
     */
    STPBankBrandKfh,
    
    /**
     Maybank2E
     */
    STPBankBrandMaybank2E,
    
    /**
     Maybank2U
     */
    STPBankBrandMaybank2U,
    
    /**
     OCBC Bank
     */
    STPBankBrandOcbc,
    
    /**
     Public Bank
     */
    STPBankBrandPublicBank,
    
    /**
     RHB Bank
     */
    STPBankBrandRhb,
    
    /**
     Standard Chartered
     */
    STPBankBrandStandardChartered,
    
    /**
     UOB Bank
     */
    STPBankBrandUob,
    
    /**
     An unknown bank type
     */
    STPBankBrandUnknown,
};

/**
 Returns a string representation for the provided bank brand;
 i.e. `[NSString stringFromBrand:STPCardBrandUob] ==  @"UOB Bank"`.
 
 @param brand the brand you want to convert to a string
 
 @return A string representing the brand, suitable for displaying to a user.
 */
NSString * STPStringFromBankBrand(STPBankBrand brand);

/**
 Returns a bank brand provided a string representation identifying a bank brand;
 i.e. `STPBankBrandFromIdentifier(@"uob") == STPCardBrandUob`.
 
 @param identifier The identifier for the brand
 
 @return The STPBankBrand enum value
 */
STPBankBrand STPBankBrandFromIdentifier(NSString *identifier);

/**
 Returns a string representation identifying the provided bank brand;
 i.e. `STPIdentifierFromBankBrand(STPCardBrandUob) ==  @"uob"`.
 
 @param brand the brand you want to convert to a string
 
 @return A string representing the brand, suitable for using with the service.
 */
NSString * STPIdentifierFromBankBrand(STPBankBrand brand);
