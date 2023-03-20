//
//  STDSStripe3DS2Error.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const STDSStripe3DS2ErrorDomain;

/**
 NSError.userInfo contains this key if we received an ErrorMessage instead of the expected response object.
 The value of this key is the ErrorMessage.
 */
FOUNDATION_EXPORT NSString * const STDSStripe3DS2ErrorMessageErrorKey;

/**
 NSError.userInfo contains this key if we errored parsing JSON.
 The value of this key is the invalid or missing field.
 */
FOUNDATION_EXPORT NSString * const STDSStripe3DS2ErrorFieldKey;

/**
 NSError.userInfo contains this key if we couldn't recognize critical message extension(s)
 The value of this key is an array of identifiers.
 */
FOUNDATION_EXPORT NSString * const STDSStripe3DS2UnrecognizedCriticalMessageExtensionsKey;


typedef NS_ENUM(NSInteger, STDSErrorCode) {

    /// Code triggered an assertion
    STDSErrorCodeAssertionFailed = 204,
    
    // JSON Parsing
    /// Received invalid or malformed data
    STDSErrorCodeJSONFieldInvalid = 203,
    /// Expected field missing
    STDSErrorCodeJSONFieldMissing = 201,

    /// Critical message extension not recognised
    STDSErrorCodeUnrecognizedCriticalMessageExtension = 202,
    
    /// Decryption or verification error
    STDSErrorCodeDecryptionVerification = 302,

    /// Error code corresponding to a `STDSRuntimeErrorEvent` for an unparseable network response
    STDSErrorCodeRuntimeParsing = 400,
    /// Error code corresponding to a `STDSRuntimeErrorEvent` for an error with decrypting or verifying a network response
    STDSErrorCodeRuntimeEncryption = 401,
    
    // Networking
    /// We received an ErrorMessage instead of the expected response object.  `userInfo[STDSStripe3DS2ErrorMessageErrorKey]` will contain the ErrorMessage object.
    STDSErrorCodeReceivedErrorMessage = 1000,
    /// We received an unknown message type.
    STDSErrorCodeUnknownMessageType = 1001,
    /// Request timed out
    STDSErrorCodeTimeout = 1002,
    
    /// Unknown
    STDSErrorCodeUnknownError = 2000,
};

NS_ASSUME_NONNULL_END
