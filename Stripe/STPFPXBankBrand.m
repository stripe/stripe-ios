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
        case STPFPXBankBrandBsn:
            return @"BSN";
        case STPFPXBankBrandCimb:
            return @"CIMB Clicks";
        case STPFPXBankBrandHongLeongBank:
            return @"Hong Leong Bank";
        case STPFPXBankBrandHsbc:
            return @"HSBC BANK";
        case STPFPXBankBrandKfh:
            return @"KFH";
        case STPFPXBankBrandMaybank2E:
            return @"Maybank2E";
        case STPFPXBankBrandMaybank2U:
            return @"Maybank2U";
        case STPFPXBankBrandOcbc:
            return @"OCBC Bank";
        case STPFPXBankBrandPublicBank:
            return @"Public Bank";
        case STPFPXBankBrandRhb:
            return @"RHB Bank";
        case STPFPXBankBrandStandardChartered:
            return @"Standard Chartered";
        case STPFPXBankBrandUob:
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
        return STPFPXBankBrandBsn;
    }
    if ([brand isEqualToString:@"cimb"]) {
        return STPFPXBankBrandCimb;
    }
    if ([brand isEqualToString:@"hong_leong_bank"]) {
        return STPFPXBankBrandHongLeongBank;
    }
    if ([brand isEqualToString:@"hsbc"]) {
        return STPFPXBankBrandHsbc;
    }
    if ([brand isEqualToString:@"kfh"]) {
        return STPFPXBankBrandKfh;
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
        return STPFPXBankBrandRhb;
    }
    if ([brand isEqualToString:@"standard_chartered"]) {
        return STPFPXBankBrandStandardChartered;
    }
    if ([brand isEqualToString:@"uob"]) {
        return STPFPXBankBrandUob;
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
        case STPFPXBankBrandBsn:
            return @"bsn";
        case STPFPXBankBrandCimb:
            return @"cimb";
        case STPFPXBankBrandHongLeongBank:
            return @"hong_leong_bank";
        case STPFPXBankBrandHsbc:
            return @"hsbc";
        case STPFPXBankBrandKfh:
            return @"kfh";
        case STPFPXBankBrandMaybank2E:
            return @"maybank2e";
        case STPFPXBankBrandMaybank2U:
            return @"maybank2u";
        case STPFPXBankBrandOcbc:
            return @"ocbc";
        case STPFPXBankBrandPublicBank:
            return @"public_bank";
        case STPFPXBankBrandRhb:
            return @"rhb";
        case STPFPXBankBrandStandardChartered:
            return @"standard_chartered";
        case STPFPXBankBrandUob:
            return @"uob";
        case STPFPXBankBrandUnknown:
            return @"unknown";
    }
}
