//
//  STDSErrorMessage+Internal.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 4/9/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSErrorMessage+Internal.h"
#import "STDSStripe3DS2Error.h"

@implementation STDSErrorMessage (Internal)

+ (NSString *)_stringForErrorCode:(STDSErrorMessageCode)errorCode {
    return [NSString stringWithFormat:@"%ld", (long)errorCode];
}

+ (instancetype)errorForInvalidMessageWithACSTransactionID:(nonnull NSString *)acsTransactionID messageVersion:(nonnull NSString *)messageVersion {
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageCodeInvalidMessage]
                                    errorComponent:@"C"
                                  errorDescription:@"Message not recognized"
                                      errorDetails:@"Unknown message type"
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
    
}

+ (nullable instancetype)errorForJSONFieldMissingWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion error:(NSError *)error {
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageCodeRequiredDataElementMissing]
                                    errorComponent:@"C"
                                  errorDescription:@"Missing Field"
                                      errorDetails:error.userInfo[STDSStripe3DS2ErrorFieldKey]
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
}

+ (nullable instancetype)errorForJSONFieldInvalidWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion error:(NSError *)error {
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageErrorInvalidDataElement]
                                    errorComponent:@"C"
                                  errorDescription:@"Invalid Field"
                                      errorDetails:error.userInfo[STDSStripe3DS2ErrorFieldKey]
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
}

+ (instancetype)errorForDecryptionErrorWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion {
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageErrorDataDecryptionFailure]
                                    errorComponent:@"C"
                                  errorDescription:@"Response could not be decrypted."
                                      errorDetails:@"Response could not be decrypted.s"
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
}

+ (instancetype)errorForTimeoutWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion {
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageErrorTimeout]
                                    errorComponent:@"C"
                                  errorDescription:@"Transaction timed out."
                                      errorDetails:@"Transaction timed out."
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
}

+ (instancetype)errorForUnrecognizedIDWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion {
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageErrorTransactionIDNotRecognized]
                                    errorComponent:@"C"
                                  errorDescription:@"Unrecognized transaction ID"
                                      errorDetails:@"Unrecognized transaction ID"
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
}

+ (instancetype)errorForUnrecognizedCriticalMessageExtensionsWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion error:(NSError *)error {
    NSArray *unrecognizedIDs = error.userInfo[STDSStripe3DS2UnrecognizedCriticalMessageExtensionsKey];
    
    return [[[self class] alloc] initWithErrorCode:[self _stringForErrorCode:STDSErrorMessageCodeUnrecognizedCriticalMessageExtension]
                                    errorComponent:@"C"
                                  errorDescription:@"Critical message extension not recognised."
                                      errorDetails:[unrecognizedIDs componentsJoinedByString:@","]
                                    messageVersion:messageVersion
                          acsTransactionIdentifier:acsTransactionID
                                  errorMessageType:@"CRes"];
}

@end
