//
//  STDSThreeDSProtocolVersion+Private.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSThreeDSProtocolVersion.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, STDSThreeDSProtocolVersion) {
    STDSThreeDSProtocolVersion2_1_0,
    STDSThreeDSProtocolVersion2_2_0,
    STDSThreeDSProtocolVersionUnknown,
    STDSThreeDSProtocolVersionFallbackTest,
};

static NSString * const kThreeDS2ProtocolVersion2_1_0 = @"2.1.0";
static NSString * const kThreeDS2ProtocolVersion2_2_0 = @"2.2.0";
static NSString * const kThreeDSProtocolVersionFallbackTest = @"2.0.0";

NS_INLINE STDSThreeDSProtocolVersion STDSThreeDSProtocolVersionForString(NSString *stringValue) {
    if ([stringValue isEqualToString:kThreeDS2ProtocolVersion2_1_0]) {
        return STDSThreeDSProtocolVersion2_1_0;
    } else if ([stringValue isEqualToString:kThreeDS2ProtocolVersion2_2_0]) {
        return STDSThreeDSProtocolVersion2_2_0;
    } else if ([stringValue isEqualToString:kThreeDSProtocolVersionFallbackTest]) {
        return STDSThreeDSProtocolVersionFallbackTest;
    } else {
        return STDSThreeDSProtocolVersionUnknown;
    }
}

NS_INLINE NSString * _Nullable STDSThreeDSProtocolVersionStringValue(STDSThreeDSProtocolVersion protocolVersion) {
    switch (protocolVersion) {
        case STDSThreeDSProtocolVersion2_1_0:
            return kThreeDS2ProtocolVersion2_1_0;

        case STDSThreeDSProtocolVersion2_2_0:
            return kThreeDS2ProtocolVersion2_2_0;

        case STDSThreeDSProtocolVersionFallbackTest:
            return kThreeDSProtocolVersionFallbackTest;

        case STDSThreeDSProtocolVersionUnknown:
            return nil;
    }
}

NS_ASSUME_NONNULL_END
