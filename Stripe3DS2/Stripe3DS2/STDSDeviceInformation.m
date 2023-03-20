//
//  STDSDeviceInformation.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSDeviceInformation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSDeviceInformation

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)deviceInformationDict {
    self = [super init];
    if (self) {
        _dictionaryValue = [deviceInformationDict copy];
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ : %@", [super description], _dictionaryValue];
}

@end

NS_ASSUME_NONNULL_END
