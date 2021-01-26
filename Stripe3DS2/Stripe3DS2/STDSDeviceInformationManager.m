//
//  STDSDeviceInformationManager.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSDeviceInformationManager.h"

#import "STDSDeviceInformation.h"
#import "STDSDeviceInformationParameter.h"
#import "STDSWarning.h"

NS_ASSUME_NONNULL_BEGIN

static const NSString * const k3DSDataVersion = @"1.1";

static const NSString * const kDataVersionKey = @"DV";
static const NSString * const kDeviceDataKey = @"DD";
static const NSString * const kDeviceParameterNotAvailableKey = @"DPNA";
static const NSString * const kDeviceWarningsKey = @"SW";

@implementation STDSDeviceInformationManager

+ (STDSDeviceInformation *)deviceInformationWithWarnings:(NSArray<STDSWarning *> *)warnings
                                    ignoringRestrictions:(BOOL)ignoreRestrictions {
    NSMutableDictionary *deviceInformation = [NSMutableDictionary dictionaryWithObject:k3DSDataVersion forKey:kDataVersionKey];

    for (STDSDeviceInformationParameter *parameter in [STDSDeviceInformationParameter allParameters]) {

        [parameter collectIgnoringRestrictions:ignoreRestrictions withHandler:^(BOOL collected, NSString * _Nonnull identifier, id _Nonnull value) {
            if (collected) {
                NSMutableDictionary *deviceData = deviceInformation[kDeviceDataKey];
                if (deviceData == nil) {
                    deviceData = [NSMutableDictionary dictionary];
                    deviceInformation[kDeviceDataKey] = deviceData;
                }
                deviceData[identifier] = value;
            } else {
                NSMutableDictionary *notAvailableData = deviceInformation[kDeviceParameterNotAvailableKey];
                if (notAvailableData == nil) {
                    notAvailableData = [NSMutableDictionary dictionary];
                    deviceInformation[kDeviceParameterNotAvailableKey] = notAvailableData;
                }
                notAvailableData[identifier] = value;
            }
        }];
    }

    NSMutableArray<NSString *> *warningIDs = [NSMutableArray arrayWithCapacity:warnings.count];
    for (STDSWarning *warning in warnings) {
        [warningIDs addObject:warning.identifier];
    }
    if (warningIDs.count > 0) {
        deviceInformation[kDeviceWarningsKey] = [warningIDs copy];
    }

    return [[STDSDeviceInformation alloc] initWithDictionary:deviceInformation];
}

@end

NS_ASSUME_NONNULL_END
