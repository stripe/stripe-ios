//
//  STPIntentActionUseStripeSDK.m
//  StripeiOS
//
//  Created by Cameron Sabol on 5/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPIntentActionUseStripeSDK.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPIntentActionUseStripeSDK

@synthesize allResponseFields = _allResponseFields;

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                               
                               // IntentActionUseStripeSDK details (alphabetical)
                               [NSString stringWithFormat:@"directoryServer = %@", self.directoryServerName],
                               [NSString stringWithFormat:@"directoryServerID = %@", self.directoryServerID],
                               [NSString stringWithFormat:@"directoryServerKeyID = %@", self.directoryServerKeyID],
                               [NSString stringWithFormat:@"serverTransactionID = %@", self.serverTransactionID],
                               [NSString stringWithFormat:@"directoryServerCertificate = %@", self.directoryServerCertificate.length > 0 ? @"<redacted>" : nil],
                               [NSString stringWithFormat:@"threeDS2SourceID = %@", self.threeDS2SourceID],
                               [NSString stringWithFormat:@"type = %@", self.allResponseFields[@"type"]],
                               
                               ] mutableCopy];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    STPIntentActionUseStripeSDKType type = STPIntentActionUseStripeSDKTypeUnknown;
    NSString *typeString = [dict stp_stringForKey:@"type"];
    if ([typeString isEqualToString:@"stripe_3ds2_fingerprint"]) {
        type = STPIntentActionUseStripeSDKType3DS2Fingerprint;
    }

    if (type == STPIntentActionUseStripeSDKTypeUnknown) {
        return nil;
    }

    NSString *directoryServer = [dict stp_stringForKey:@"directory_server_name"];
    if (directoryServer == nil || directoryServer.length == 0) {
        return nil;
    }

    NSDictionary *encryptionInfo = [dict stp_dictionaryForKey:@"directory_server_encryption"];
    if (encryptionInfo == nil) {
        return nil;
    }

    NSString *certificate = encryptionInfo[@"certificate"];
    NSString *directoryServerID = encryptionInfo[@"directory_server_id"];
    if (certificate.length == 0 || directoryServerID.length == 0) {
        return nil;
    }

    NSString *directoryServerKeyID = encryptionInfo[@"key_id"];



    STPIntentActionUseStripeSDK *action = [[self alloc] init];
    action->_type = type;
    action->_directoryServerName = [directoryServer copy];
    action->_directoryServerCertificate = [certificate copy];
    action->_directoryServerID = [directoryServerID copy];
    action->_directoryServerKeyID = [directoryServerKeyID copy];
    action->_serverTransactionID = [[dict stp_stringForKey:@"server_transaction_id"] copy];
    action->_threeDS2SourceID = [[dict stp_stringForKey:@"three_d_secure_2_source"] copy];
    action->_allResponseFields = dict;
    return action;
}

@end

NS_ASSUME_NONNULL_END
