//
//  STDSProtocolErrorEvent.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSProtocolErrorEvent.h"

#import "STDSErrorMessage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSProtocolErrorEvent

- (instancetype)initWithSDKTransactionIdentifier:(NSString *)identifier errorMessage:(STDSErrorMessage *)errorMessage {
    self = [super init];
    if (self) {
        _sdkTransactionIdentifier = identifier;
        _errorMessage = errorMessage;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
