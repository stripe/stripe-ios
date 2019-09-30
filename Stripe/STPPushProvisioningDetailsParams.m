//
//  STPPushProvisioningDetailsParams.m
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPushProvisioningDetailsParams.h"

@interface STPPushProvisioningDetailsParams ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSArray<NSData *> *certificates;
@property (nonatomic, readwrite) NSData *nonce;
@property (nonatomic, readwrite) NSData *nonceSignature;
    
@end

@implementation STPPushProvisioningDetailsParams

+(instancetype)paramsWithCardId:(NSString *)cardId
                   certificates:(NSArray<NSData *>*)certificates
                          nonce:(NSData *)nonce
                 nonceSignature:(NSData *)nonceSignature {
    STPPushProvisioningDetailsParams *params = [[self alloc] init];
    params.cardId = cardId;
    params.certificates = certificates;
    params.nonce = nonce;
    params.nonceSignature = nonceSignature;
    return params;
}

- (NSArray<NSString *> *)certificatesBase64 {
    NSMutableArray *base64Certificates = [NSMutableArray array];
    for (NSData *certificate in self.certificates) {
        [base64Certificates addObject:[certificate base64EncodedStringWithOptions:kNilOptions]];
    }
    return base64Certificates;
}

- (NSString *)nonceHex {
    return [self.class hexadecimalStringForData:self.nonce];
}

- (NSString *)nonceSignatureHex {
    return [self.class hexadecimalStringForData:self.nonceSignature];
}

// Adapted from https://stackoverflow.com/questions/1305225/best-way-to-serialize-an-nsdata-into-a-hexadeximal-string
+ (NSString *)hexadecimalStringForData:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer) {
        return [NSString string];
    }
    
    NSUInteger dataLength  = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (NSUInteger i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    return [NSString stringWithString:hexString];
}
    
@end
