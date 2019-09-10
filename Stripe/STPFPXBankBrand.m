//
//  STPFPXBankBrand.m
//  StripeiOS
//
//  Created by David Estes on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPFPXBankBrand.h"

NSString * STPStringFromFPXBankBrand(STPFPXBankBrand brand) {
    switch (brand) {
        case STPFPXBankBrandAffinBank:
            return @"Affin Bank";
        case STPFPXBankBrandAllianceBank:
            return @"Alliance Bank";
        case STPFPXBankBrandAmbank:
            return @"AmBank";
        case STPFPXBankBrandBankIslam:
            return @"Bank Islam";
        case STPFPXBankBrandBankMuamalat:
            return @"Bank Muamalat";
        case STPFPXBankBrandBankRakyat:
            return @"Bank Rakyat";
        case STPFPXBankBrandBSN:
            return @"BSN";
        case STPFPXBankBrandCIMB:
            return @"CIMB Clicks";
        case STPFPXBankBrandHongLeongBank:
            return @"Hong Leong Bank";
        case STPFPXBankBrandHSBC:
            return @"HSBC BANK";
        case STPFPXBankBrandKFH:
            return @"KFH";
        case STPFPXBankBrandMaybank2E:
            return @"Maybank2E";
        case STPFPXBankBrandMaybank2U:
            return @"Maybank2U";
        case STPFPXBankBrandOcbc:
            return @"OCBC Bank";
        case STPFPXBankBrandPublicBank:
            return @"Public Bank";
        case STPFPXBankBrandRHB:
            return @"RHB Bank";
        case STPFPXBankBrandStandardChartered:
            return @"Standard Chartered";
        case STPFPXBankBrandUOB:
            return @"UOB Bank";
        case STPFPXBankBrandUnknown:
            return @"Unknown";
    }
}

STPFPXBankBrand STPFPXBankBrandFromIdentifier(NSString *identifier) {
    NSString *brand = [identifier lowercaseString];
    if ([brand isEqualToString:@"affin_bank"]) {
        return STPFPXBankBrandAffinBank;
    }
    if ([brand isEqualToString:@"alliance_bank"]) {
        return STPFPXBankBrandAllianceBank;
    }
    if ([brand isEqualToString:@"ambank"]) {
        return STPFPXBankBrandAmbank;
    }
    if ([brand isEqualToString:@"bank_islam"]) {
        return STPFPXBankBrandBankIslam;
    }
    if ([brand isEqualToString:@"bank_muamalat"]) {
        return STPFPXBankBrandBankMuamalat;
    }
    if ([brand isEqualToString:@"bank_rakyat"]) {
        return STPFPXBankBrandBankRakyat;
    }
    if ([brand isEqualToString:@"bsn"]) {
        return STPFPXBankBrandBSN;
    }
    if ([brand isEqualToString:@"cimb"]) {
        return STPFPXBankBrandCIMB;
    }
    if ([brand isEqualToString:@"hong_leong_bank"]) {
        return STPFPXBankBrandHongLeongBank;
    }
    if ([brand isEqualToString:@"hsbc"]) {
        return STPFPXBankBrandHSBC;
    }
    if ([brand isEqualToString:@"kfh"]) {
        return STPFPXBankBrandKFH;
    }
    if ([brand isEqualToString:@"maybank2e"]) {
        return STPFPXBankBrandMaybank2E;
    }
    if ([brand isEqualToString:@"maybank2u"]) {
        return STPFPXBankBrandMaybank2U;
    }
    if ([brand isEqualToString:@"ocbc"]) {
        return STPFPXBankBrandOcbc;
    }
    if ([brand isEqualToString:@"public_bank"]) {
        return STPFPXBankBrandPublicBank;
    }
    if ([brand isEqualToString:@"rhb"]) {
        return STPFPXBankBrandRHB;
    }
    if ([brand isEqualToString:@"standard_chartered"]) {
        return STPFPXBankBrandStandardChartered;
    }
    if ([brand isEqualToString:@"uob"]) {
        return STPFPXBankBrandUOB;
    }
    return STPFPXBankBrandUnknown;
}

NSString * STPIdentifierFromFPXBankBrand(STPFPXBankBrand brand) {
    switch (brand) {
        case STPFPXBankBrandAffinBank:
            return @"affin_bank";
        case STPFPXBankBrandAllianceBank:
            return @"alliance_bank";
        case STPFPXBankBrandAmbank:
            return @"ambank";
        case STPFPXBankBrandBankIslam:
            return @"bank_islam";
        case STPFPXBankBrandBankMuamalat:
            return @"bank_muamalat";
        case STPFPXBankBrandBankRakyat:
            return @"bank_rakyat";
        case STPFPXBankBrandBSN:
            return @"bsn";
        case STPFPXBankBrandCIMB:
            return @"cimb";
        case STPFPXBankBrandHongLeongBank:
            return @"hong_leong_bank";
        case STPFPXBankBrandHSBC:
            return @"hsbc";
        case STPFPXBankBrandKFH:
            return @"kfh";
        case STPFPXBankBrandMaybank2E:
            return @"maybank2e";
        case STPFPXBankBrandMaybank2U:
            return @"maybank2u";
        case STPFPXBankBrandOcbc:
            return @"ocbc";
        case STPFPXBankBrandPublicBank:
            return @"public_bank";
        case STPFPXBankBrandRHB:
            return @"rhb";
        case STPFPXBankBrandStandardChartered:
            return @"standard_chartered";
        case STPFPXBankBrandUOB:
            return @"uob";
        case STPFPXBankBrandUnknown:
            return @"unknown";
    }
}
