//
//  Header.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, STDSDirectoryServer) {
    STDSDirectoryServerULTestRSA,
    STDSDirectoryServerULTestEC,
    STDSDirectoryServerSTPTestRSA,
    STDSDirectoryServerSTPTestEC,
    STDSDirectoryServerAmex,
    STDSDirectoryServerDiscover,
    STDSDirectoryServerMastercard,
    STDSDirectoryServerVisa,
    STDSDirectoryServerCustom,
    STDSDirectoryServerUnknown,
};

static NSString * const kULTestRSADirectoryServerID = @"F000000000";
static NSString * const kULTestECDirectoryServerID = @"F000000001";

static NSString * const kSTDSTestRSADirectoryServerID = @"ul_test";
static NSString * const kSTDSTestECDirectoryServerID = @"ec_test";

static NSString * const kSTDSAmexDirectoryServerID = @"A000000025";
static NSString * const kSTDSDiscoverDirectoryServerID = @"A000000324";
static NSString * const kSTDSDiscoverDirectoryServerID_2 = @"A000000152";
static NSString * const kSTDSMastercardDirectoryServerID = @"A000000004";
static NSString * const kSTDSVisaDirectoryServerID = @"A000000003";


/// Returns the typed directory server enum or STDSDirectoryServerUnknown if the directoryServerID is not recognized
NS_INLINE STDSDirectoryServer STDSDirectoryServerForID(NSString *directoryServerID) {
    if ([directoryServerID isEqualToString:kULTestRSADirectoryServerID]) {
        return STDSDirectoryServerULTestRSA;
    } else if ([directoryServerID isEqualToString:kULTestECDirectoryServerID]) {
        return STDSDirectoryServerULTestEC;
    } else if ([directoryServerID isEqualToString:kSTDSTestRSADirectoryServerID]) {
        return STDSDirectoryServerSTPTestRSA;
    } else if ([directoryServerID isEqualToString:kSTDSTestECDirectoryServerID]) {
        return STDSDirectoryServerSTPTestEC;
    } else if ([directoryServerID isEqualToString:kSTDSAmexDirectoryServerID]) {
        return STDSDirectoryServerAmex;
    } else if ([directoryServerID isEqualToString:kSTDSDiscoverDirectoryServerID] || [directoryServerID isEqualToString:kSTDSDiscoverDirectoryServerID_2]) {
        return STDSDirectoryServerDiscover;
    } else if ([directoryServerID isEqualToString:kSTDSMastercardDirectoryServerID]) {
        return STDSDirectoryServerMastercard;
    } else if ([directoryServerID isEqualToString:kSTDSVisaDirectoryServerID]) {
        return STDSDirectoryServerVisa;
    }
    
    return STDSDirectoryServerUnknown;
}

/// Returns the directory server ID or nil for STDSDirectoryServerUnknown
NS_INLINE NSString * _Nullable STDSDirectoryServerIdentifier(STDSDirectoryServer directoryServer) {
    switch (directoryServer) {
        case STDSDirectoryServerULTestRSA:
            return kULTestRSADirectoryServerID;
            
        case STDSDirectoryServerULTestEC:
            return kULTestECDirectoryServerID;
            
        case STDSDirectoryServerSTPTestRSA:
            return kSTDSTestRSADirectoryServerID;
            
        case STDSDirectoryServerSTPTestEC:
            return kSTDSTestECDirectoryServerID;
            
        case STDSDirectoryServerAmex:
            return kSTDSAmexDirectoryServerID;

        case STDSDirectoryServerDiscover:
            return kSTDSDiscoverDirectoryServerID;

        case STDSDirectoryServerMastercard:
            return kSTDSMastercardDirectoryServerID;

        case STDSDirectoryServerVisa:
            return kSTDSVisaDirectoryServerID;

        case STDSDirectoryServerCustom:
            return nil;
            
        case STDSDirectoryServerUnknown:
            return nil;
    }
}

/// Returns the directory server image name if one exists
NS_INLINE NSString * _Nullable STDSDirectoryServerImageName(STDSDirectoryServer directoryServer) {
    switch (directoryServer) {
        case STDSDirectoryServerAmex:
            return @"amex-logo";
        case STDSDirectoryServerDiscover:
            return @"discover-logo";
        case STDSDirectoryServerMastercard:
            return @"mastercard-logo";
        // just default to an arbitrary logo for the test servers
        case STDSDirectoryServerULTestEC:
        case STDSDirectoryServerULTestRSA:
        case STDSDirectoryServerSTPTestRSA:
        case STDSDirectoryServerSTPTestEC:
        case STDSDirectoryServerVisa:
            if (@available(iOS 13.0, *)) {
                if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
                    return @"visa-white-logo";
                }
            }
            return @"visa-logo";
        case STDSDirectoryServerCustom:
        case STDSDirectoryServerUnknown:
            return nil;

    }
}

NS_ASSUME_NONNULL_END
