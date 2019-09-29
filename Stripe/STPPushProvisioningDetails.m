//
//  STPPushProvisioningDetails.m
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPushProvisioningDetails.h"

#import "NSDictionary+Stripe.h"

@interface STPPushProvisioningDetails ()
    
@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) BOOL livemode;
@property (nonatomic, readwrite) NSData *encryptedPassData;
@property (nonatomic, readwrite) NSData *activationData;
@property (nonatomic, readwrite) NSData *ephemeralPublicKey;
@property (nonatomic, readwrite, copy) NSDictionary *allResponseFields;

@end

@implementation STPPushProvisioningDetails

+ (instancetype)detailsWithCardId:(NSString *)cardId
                         livemode:(BOOL)livemode
                encryptedPassData:(NSData *)encryptedPassData
                   activationData:(NSData *)activationData
               ephemeralPublicKey:(NSData *)ephemeralPublicKey {
    STPPushProvisioningDetails *details = [[self alloc] init];
    details.cardId = cardId;
    details.livemode = livemode;
    details.encryptedPassData = encryptedPassData;
    details.activationData = activationData;
    details.ephemeralPublicKey = ephemeralPublicKey;
    return details;
}
    
#pragma mark  - STPAPIResponseDecodable
    
+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    // required fields
    NSString *cardId = [dict stp_stringForKey:@"card"];
    BOOL livemode = [dict stp_boolForKey:@"livemode" or:NO];
    NSString *encryptedPassString = [dict stp_stringForKey:@"contents"];
    NSData *encryptedPassData = encryptedPassString ? [[NSData alloc] initWithBase64EncodedString:encryptedPassString options:0] : nil;
    
    NSString *activationString = [dict stp_stringForKey:@"activation_data"];
    NSData *activationData = activationString ? [[NSData alloc] initWithBase64EncodedString:activationString options:0] : nil;
    
    NSString *ephemeralPublicKeyString = [dict stp_stringForKey:@"ephemeral_public_key"];
    NSData *ephemeralPublicKeyData = ephemeralPublicKeyString ? [[NSData alloc] initWithBase64EncodedString:ephemeralPublicKeyString options:0] : nil;
    
    if (cardId == nil || encryptedPassData == nil || activationData == nil || ephemeralPublicKeyData == nil) {
        return nil;
    }
    
    STPPushProvisioningDetails *details = [self detailsWithCardId:cardId
                                                         livemode:livemode
                                                encryptedPassData:encryptedPassData
                                                   activationData:activationData
                                               ephemeralPublicKey:ephemeralPublicKeyData];
    details.allResponseFields = dict;
    
    return details;
}

    
#pragma mark - Equality

- (BOOL)isEqual:(STPPushProvisioningDetails *)details {
    return [self isEqualToDetails:details];
}

- (NSUInteger)hash {
    return [self.activationData hash];
}

- (BOOL)isEqualToDetails:(STPPushProvisioningDetails *)details {
    if (self == details) {
        return YES;
    }
    
    if (!details || ![details isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.activationData isEqualToData:details.activationData];
}

@end
