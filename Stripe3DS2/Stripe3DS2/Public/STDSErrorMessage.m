//
//  STDSErrorMessage.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSErrorMessage.h"

#import "NSDictionary+DecodingHelpers.h"
#import "STDSJSONEncoder.h"
#import "STDSStripe3DS2Error.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSErrorMessage

- (instancetype)initWithErrorCode:(NSString *)errorCode
                   errorComponent:(NSString *)errorComponent
                 errorDescription:(NSString *)errorDescription
                     errorDetails:(nullable NSString *)errorDetails
                   messageVersion:(NSString *)messageVersion
         acsTransactionIdentifier:(nullable NSString *)acsTransactionIdentifier
                 errorMessageType:(NSString *)errorMessageType {
    self = [super init];
    if (self) {
        _errorCode = [errorCode copy];
        _errorComponent = [errorComponent copy];
        _errorDescription = [errorDescription copy];
        _errorDetails = [errorDetails copy];
        _messageVersion = [messageVersion copy];
        _acsTransactionIdentifier = [acsTransactionIdentifier copy];
        _errorMessageType = [errorMessageType copy];
    }
    return self;
}

- (NSString *)messageType {
    return @"Erro";
}

- (NSError *)NSErrorValue {
    return [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                               code:[self.errorCode integerValue]
                           userInfo: [STDSJSONEncoder dictionaryForObject:self]];
}

#pragma mark - STDSJSONEncodable

+ (NSDictionary *)propertyNamesToJSONKeysMapping {
    return @{
             NSStringFromSelector(@selector(errorCode)): @"errorCode",
             NSStringFromSelector(@selector(errorComponent)): @"errorComponent",
             NSStringFromSelector(@selector(errorDescription)): @"errorDescription",
             NSStringFromSelector(@selector(errorDetails)): @"errorDetail",
             NSStringFromSelector(@selector(messageType)): @"messageType",
             NSStringFromSelector(@selector(messageVersion)): @"messageVersion",
             NSStringFromSelector(@selector(acsTransactionIdentifier)): @"acsTransID",
             NSStringFromSelector(@selector(errorMessageType)): @"errorMessageType",
             };
}

#pragma mark - STDSJSONDecodable

+ (nullable instancetype)decodedObjectFromJSON:(nullable NSDictionary *)json error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
    if (json == nil) {
        return nil;
    }
    NSError *error;

    // Required
    NSString *errorCode = [json _stds_stringForKey:@"errorCode" required:YES error:&error];
    NSString *errorComponent = [json _stds_stringForKey:@"errorComponent" required:YES error:&error];
    NSString *errorDescription = [json _stds_stringForKey:@"errorDescription" required:YES error:&error];
    NSString *errorDetail = [json _stds_stringForKey:@"errorDetail" required:YES error:&error];
    NSString *messageVersion = [json _stds_stringForKey:@"messageVersion" required:YES error:&error];

    // Optional
    NSString *errorMessageType = [json _stds_stringForKey:@"errorMessageType" required:NO error:&error];
    NSString *acsTransactionIdentifier = [json _stds_stringForKey:@"acsTransID" required:NO error:nil];

    if (error) {
        if (outError) {
            *outError = error;
        }
        return nil;
    }
    return [[self alloc] initWithErrorCode:errorCode errorComponent:errorComponent errorDescription:errorDescription errorDetails:errorDetail messageVersion:messageVersion acsTransactionIdentifier:acsTransactionIdentifier errorMessageType:errorMessageType];
}

@end

NS_ASSUME_NONNULL_END
