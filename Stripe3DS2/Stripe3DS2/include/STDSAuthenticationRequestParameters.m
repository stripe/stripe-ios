//
//  STDSAuthenticationRequestParameters.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSAuthenticationRequestParameters.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSAuthenticationRequestParameters ()

@property (nonatomic, nullable, readonly) NSDictionary *sdkEphemeralPublicKeyJSON;

@end

@implementation STDSAuthenticationRequestParameters

- (instancetype)initWithSDKTransactionIdentifier:(NSString *)sdkTransactionIdentifier
                                      deviceData:(nullable NSString *)deviceData
                           sdkEphemeralPublicKey:(NSString *)sdkEphemeralPublicKey
                                sdkAppIdentifier:(NSString *)sdkAppIdentifier
                              sdkReferenceNumber:(NSString *)sdkReferenceNumber
                                  messageVersion:(NSString *)messageVersion {
    self = [super init];
    if (self) {
        _sdkTransactionIdentifier = [sdkTransactionIdentifier copy];
        _deviceData = [deviceData copy];
        _sdkEphemeralPublicKey = [sdkEphemeralPublicKey copy];
        _sdkAppIdentifier = [sdkAppIdentifier copy];
        _sdkReferenceNumber = [sdkReferenceNumber copy];
        _messageVersion = [messageVersion copy];
    }
    return self;
}

- (nullable NSDictionary *)sdkEphemeralPublicKeyJSON {
    NSData *data = [self.sdkEphemeralPublicKey dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        return nil;
    }

    return [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
}

#pragma mark - STDSJSONEncodable

+ (NSDictionary *)propertyNamesToJSONKeysMapping {
    return @{
             NSStringFromSelector(@selector(sdkTransactionIdentifier)): @"sdkTransID",
             NSStringFromSelector(@selector(deviceData)): @"sdkEncData",
             NSStringFromSelector(@selector(sdkEphemeralPublicKeyJSON)): @"sdkEphemPubKey",
             NSStringFromSelector(@selector(sdkAppIdentifier)): @"sdkAppID",
             NSStringFromSelector(@selector(sdkReferenceNumber)): @"sdkReferenceNumber",
             NSStringFromSelector(@selector(messageVersion)): @"messageVersion",
             };
}

@end

NS_ASSUME_NONNULL_END
