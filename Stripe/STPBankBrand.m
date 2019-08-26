//
//  STPBankBrand.m
//  StripeiOS
//
//  Created by David Estes on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPBankBrand.h"

NSString * STPStringFromBankBrand(STPBankBrand brand) {
    switch (brand) {
        case STPBankBrandAffinBank:
            return @"Affin Bank";
        case STPBankBrandAllianceBank:
            return @"Alliance Bank";
        case STPBankBrandAmbank:
            return @"AmBank";
        case STPBankBrandBankIslam:
            return @"Bank Islam";
        case STPBankBrandBankMuamalat:
            return @"Bank Muamalat";
        case STPBankBrandBankRakyat:
            return @"Bank Rakyat";
        case STPBankBrandBsn:
            return @"BSN";
        case STPBankBrandCimb:
            return @"CIMB Clicks";
        case STPBankBrandHongLeongBank:
            return @"Hong Leong Bank";
        case STPBankBrandHsbc:
            return @"HSBC BANK";
        case STPBankBrandKfh:
            return @"KFH";
        case STPBankBrandMaybank2E:
            return @"Maybank2E";
        case STPBankBrandMaybank2U:
            return @"Maybank2U";
        case STPBankBrandOcbc:
            return @"OCBC Bank";
        case STPBankBrandPublicBank:
            return @"Public Bank";
        case STPBankBrandRhb:
            return @"RHB Bank";
        case STPBankBrandStandardChartered:
            return @"Standard Chartered";
        case STPBankBrandUob:
            return @"UOB Bank";
        case STPBankBrandUnknown:
            return @"Unknown";
    }
}

STPBankBrand STPBankBrandFromIdentifier(NSString *identifier) {
    NSString *brand = [identifier lowercaseString];
    if ([brand isEqualToString:@"affin_bank"]) {
        return STPBankBrandAffinBank;
    }
    if ([brand isEqualToString:@"alliance_bank"]) {
        return STPBankBrandAllianceBank;
    }
    if ([brand isEqualToString:@"ambank"]) {
        return STPBankBrandAmbank;
    }
    if ([brand isEqualToString:@"bank_islam"]) {
        return STPBankBrandBankIslam;
    }
    if ([brand isEqualToString:@"bank_muamalat"]) {
        return STPBankBrandBankMuamalat;
    }
    if ([brand isEqualToString:@"bank_rakyat"]) {
        return STPBankBrandBankRakyat;
    }
    if ([brand isEqualToString:@"bsn"]) {
        return STPBankBrandBsn;
    }
    if ([brand isEqualToString:@"cimb"]) {
        return STPBankBrandCimb;
    }
    if ([brand isEqualToString:@"hong_leong_bank"]) {
        return STPBankBrandHongLeongBank;
    }
    if ([brand isEqualToString:@"hsbc"]) {
        return STPBankBrandHsbc;
    }
    if ([brand isEqualToString:@"kfh"]) {
        return STPBankBrandKfh;
    }
    if ([brand isEqualToString:@"maybank2e"]) {
        return STPBankBrandMaybank2E;
    }
    if ([brand isEqualToString:@"maybank2u"]) {
        return STPBankBrandMaybank2U;
    }
    if ([brand isEqualToString:@"ocbc"]) {
        return STPBankBrandOcbc;
    }
    if ([brand isEqualToString:@"public_bank"]) {
        return STPBankBrandPublicBank;
    }
    if ([brand isEqualToString:@"rhb"]) {
        return STPBankBrandRhb;
    }
    if ([brand isEqualToString:@"standard_chartered"]) {
        return STPBankBrandStandardChartered;
    }
    if ([brand isEqualToString:@"uob"]) {
        return STPBankBrandUob;
    }
    return STPBankBrandUnknown;
}

NSString * STPIdentifierFromBankBrand(STPBankBrand brand) {
    switch (brand) {
        case STPBankBrandAffinBank:
            return @"affin_bank";
        case STPBankBrandAllianceBank:
            return @"alliance_bank";
        case STPBankBrandAmbank:
            return @"ambank";
        case STPBankBrandBankIslam:
            return @"bank_islam";
        case STPBankBrandBankMuamalat:
            return @"bank_muamalat";
        case STPBankBrandBankRakyat:
            return @"bank_rakyat";
        case STPBankBrandBsn:
            return @"bsn";
        case STPBankBrandCimb:
            return @"cimb";
        case STPBankBrandHongLeongBank:
            return @"hong_leong_bank";
        case STPBankBrandHsbc:
            return @"hsbc";
        case STPBankBrandKfh:
            return @"kfh";
        case STPBankBrandMaybank2E:
            return @"maybank2e";
        case STPBankBrandMaybank2U:
            return @"maybank2u";
        case STPBankBrandOcbc:
            return @"ocbc";
        case STPBankBrandPublicBank:
            return @"public_bank";
        case STPBankBrandRhb:
            return @"rhb";
        case STPBankBrandStandardChartered:
            return @"standard_chartered";
        case STPBankBrandUob:
            return @"uob";
        case STPBankBrandUnknown:
            return @"unknown";
    }
}
