//
//  STDSRuntimeErrorEvent.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSRuntimeErrorEvent.h"

#import "STDSStripe3DS2Error.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kSTDSRuntimeErrorCodeParsingError = @"STDSRuntimeErrorCodeParsingError";
NSString * const kSTDSRuntimeErrorCodeEncryptionError = @"STDSRuntimeErrorCodeEncryptionError";

@implementation STDSRuntimeErrorEvent

- (instancetype)initWithErrorCode:(NSString *)errorCode errorMessage:(NSString *)errorMessage {
    self = [super init];
    if (self) {
        _errorCode = [errorCode copy];
        _errorMessage = [errorMessage copy];
    }
    return self;
}

- (NSError *)NSErrorValue {
    return [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                               code:[self.errorCode isEqualToString:kSTDSRuntimeErrorCodeParsingError] ? STDSErrorCodeRuntimeParsing : STDSErrorCodeRuntimeEncryption
                           userInfo:@{@"errorMessage": self.errorMessage}];
}

@end

NS_ASSUME_NONNULL_END
