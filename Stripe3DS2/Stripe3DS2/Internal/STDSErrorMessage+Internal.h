//
//  STDSErrorMessage+Internal.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 4/9/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STDSErrorMessage.h"

NS_ASSUME_NONNULL_BEGIN

// Constructors for the circumstances in which we are required to send an ErrorMessage to the ACS
@interface STDSErrorMessage (Internal)

/// Received an invalid message type
+ (instancetype)errorForInvalidMessageWithACSTransactionID:(NSString *)acsTransactionID
                                            messageVersion:(NSString *)messageVersion;

/// Encountered an invalid field parsing a JSON response
+ (nullable instancetype)errorForJSONFieldInvalidWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion error:(NSError *)error;

/// Encountered a missing field parsing a JSON response
+ (nullable instancetype)errorForJSONFieldMissingWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion error:(NSError *)error;

/// Encountered an error decrypting a networking response
+ (instancetype)errorForDecryptionErrorWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion;

/// Timed out
+ (instancetype)errorForTimeoutWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion;

+ (instancetype)errorForUnrecognizedIDWithACSTransactionID:(NSString *)transactionID messageVersion:(NSString *)messageVersion;

/// Encountered unrecognized critical message extension(s)
+ (instancetype)errorForUnrecognizedCriticalMessageExtensionsWithACSTransactionID:(NSString *)acsTransactionID messageVersion:(NSString *)messageVersion error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
