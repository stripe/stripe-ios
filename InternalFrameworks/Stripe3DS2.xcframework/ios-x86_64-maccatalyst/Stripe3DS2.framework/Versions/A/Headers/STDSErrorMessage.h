//
//  STDSErrorMessage.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSJSONEncodable.h"
#import "STDSJSONDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/// Error codes as defined by the 3DS2 spec.
typedef NS_ENUM(NSInteger, STDSErrorMessageCode) {
    /// The SDK received a message that is not an ARes, CRes, or ErrorMessage.
    STDSErrorMessageCodeInvalidMessage = 101,
    
    /// A required data element is missing from the network response.
    STDSErrorMessageCodeRequiredDataElementMissing = 201,
    
    // Critical message extension not recognised
    STDSErrorMessageCodeUnrecognizedCriticalMessageExtension = 202,
    
    /// A data element is not in the required format or the value is invalid.
    STDSErrorMessageErrorInvalidDataElement = 203,
    
    // Transaction ID not recognized
    STDSErrorMessageErrorTransactionIDNotRecognized = 301,
    
    /// A network response could not be decrypted or verified.
    STDSErrorMessageErrorDataDecryptionFailure = 302,
    
    /// The SDK timed out
    STDSErrorMessageErrorTimeout = 402,
};

/**
 `STDSErrorMessage` represents an error message that is returned by the ACS or to be sent to the ACS.
 */
@interface STDSErrorMessage : NSObject <STDSJSONEncodable, STDSJSONDecodable>

/**
 Designated initializer for `STDSErrorMessage`.
 
 @param errorCode               The error code.
 @param errorComponent          The component that identified the error.
 @param errorDescription        Text describing the error.
 @param errorDetails            Additional error details.  Optional.
 */
- (instancetype)initWithErrorCode:(NSString *)errorCode
                   errorComponent:(NSString *)errorComponent
                 errorDescription:(NSString *)errorDescription
                     errorDetails:(nullable NSString *)errorDetails
                   messageVersion:(NSString *)messageVersion
         acsTransactionIdentifier:(nullable NSString *)acsTransactionIdentifier
                 errorMessageType:(NSString *)errorMessageType;

/**
 `STDSErrorMessage` should not be directly initialized.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 The error code.
 */
@property (nonatomic, readonly) NSString *errorCode;

/**
 The 3-D Secure component that identified the error.
 */
@property (nonatomic, readonly) NSString *errorComponent;

/**
 Text describing the error.
 */
@property (nonatomic, readonly) NSString *errorDescription;

/**
 Additional error details.
 */
@property (nonatomic, nullable, readonly) NSString *errorDetails;

/**
 The protocol version identifier.
 */
@property (nonatomic, readonly) NSString *messageVersion;

/**
 The ACS transaction identifier.
 */
@property (nonatomic, readonly, nullable) NSString *acsTransactionIdentifier;

/**
 The message type that was identified as erroneous.
 */
@property (nonatomic, readonly) NSString *errorMessageType;

/**
 A representation of the `STDSErrorMessage` as an `NSError`
 */
- (NSError *)NSErrorValue;

@end

NS_ASSUME_NONNULL_END
