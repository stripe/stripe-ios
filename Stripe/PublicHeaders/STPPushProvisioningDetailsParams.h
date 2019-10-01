//
//  STPPushProvisioningDetailsParams.h
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A helper class for turning the raw certificate array, nonce, and nonce signature emitted by PKAddPaymentPassViewController into a format that is understandable by the Stripe API.
 If you are using STPPushProvisioningContext to implement your integration, you do not need to use this class.
 */
@interface STPPushProvisioningDetailsParams : NSObject

@property (nonatomic, readonly) NSString *cardId;
@property (nonatomic, readonly) NSArray<NSData *> *certificates;
@property (nonatomic, readonly) NSData *nonce;
@property (nonatomic, readonly) NSData *nonceSignature;

/// Implemented for convenience - the Stripe API expects the certificate chain as an array of base64-encoded strings.
@property (nonatomic, readonly) NSArray<NSString *> *certificatesBase64;
/// Implemented for convenience - the Stripe API expects the nonce as a hex-encoded string.
@property (nonatomic, readonly) NSString *nonceHex;
/// Implemented for convenience - the Stripe API expects the nonce signature as a hex-encoded string.
@property (nonatomic, readonly) NSString *nonceSignatureHex;
    
+(instancetype)paramsWithCardId:(NSString *)cardId
                   certificates:(NSArray<NSData *>*)certificates
                          nonce:(NSData *)nonce
                 nonceSignature:(NSData *)nonceSignature;
    
@end

NS_ASSUME_NONNULL_END
