//
//  STDSWarning.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 2/12/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSWarning.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSWarning

- (instancetype)initWithIdentifier:(NSString *)identifier
                           message:(NSString *)message
                          severity:(STDSWarningSeverity)severity {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _message = [message copy];
        _severity = severity;
    }

    return self;
}

@end

NS_ASSUME_NONNULL_END
