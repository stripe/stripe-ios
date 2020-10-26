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
                               [NSString stringWithFormat:@"rootCertificateStrings = %@", self.rootCertificateStrings.count > 0 ? @"<redacted>" : nil],
                               [NSString stringWithFormat:@"threeDSSourceID = %@", self.threeDSSourceID],
                               [NSString stringWithFormat:@"type = %@", self.allResponseFields[@"type"]],
                               [NSString stringWithFormat:@"redirectURL = %@", self.redirectURL],
                               
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
    } else if ([typeString isEqualToString:@"three_d_secure_redirect"]) {
        type = STPIntentActionUseStripeSDKType3DS2Redirect;
    }

    NSString *directoryServer = [dict stp_stringForKey:@"directory_server_name"];


    NSDictionary *encryptionInfo = [dict stp_dictionaryForKey:@"directory_server_encryption"];


    NSString *certificate = [encryptionInfo stp_stringForKey:@"certificate"];
    NSArray<NSString *> *rootCertificates = [encryptionInfo stp_arrayForKey:@"root_certificate_authorities"];
    NSString *directoryServerID = [encryptionInfo stp_stringForKey:@"directory_server_id"];

    NSString *directoryServerKeyID = [encryptionInfo stp_stringForKey:@"key_id"];

    NSURL *redirectURL = [dict stp_urlForKey:@"stripe_js"];
    NSString *threeDSSourceID = nil;

    // required checks
    switch (type) {
        case STPIntentActionUseStripeSDKType3DS2Fingerprint:
            if (directoryServer == nil || directoryServer.length == 0) {
                return nil;
            } else if (encryptionInfo == nil) {
                return nil;
            } else if (certificate.length == 0 || directoryServerID.length == 0) {
                return nil;
            }
            threeDSSourceID = [[dict stp_stringForKey:@"three_d_secure_2_source"] copy];
            break;

        case STPIntentActionUseStripeSDKType3DS2Redirect:
            if (redirectURL == nil) {
                return nil;
            }
            if ([redirectURL.lastPathComponent hasPrefix:@"src_"]) {
                threeDSSourceID = [redirectURL.lastPathComponent copy];
            }
            break;

        case STPIntentActionUseStripeSDKTypeUnknown:
            break;
    }



    STPIntentActionUseStripeSDK *action = [[self alloc] init];
    action->_type = type;
    action->_directoryServerName = [directoryServer copy];
    action->_directoryServerCertificate = [certificate copy];
    action->_rootCertificateStrings = rootCertificates;
    action->_directoryServerID = [directoryServerID copy];
    action->_directoryServerKeyID = [directoryServerKeyID copy];
    action->_serverTransactionID = [[dict stp_stringForKey:@"server_transaction_id"] copy];
    action->_threeDSSourceID = [threeDSSourceID copy];
    action->_redirectURL = redirectURL;
    action->_allResponseFields = dict;
    return action;
}

@end

NS_ASSUME_NONNULL_END
