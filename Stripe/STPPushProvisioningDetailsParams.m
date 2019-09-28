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
    
@end
