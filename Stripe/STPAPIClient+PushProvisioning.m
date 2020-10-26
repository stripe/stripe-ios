//
//  STPAPIClient+PushProvisioning.m
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient+PushProvisioning.h"
#import "STPAPIClient+Private.h"

@implementation STPAPIClient (PushProvisioning)

- (void)retrievePushProvisioningDetailsWithParams:(STPPushProvisioningDetailsParams *)params
                                     ephemeralKey:(STPEphemeralKey *)ephemeralKey
                                       completion:(STPPushProvisioningDetailsCompletionBlock)completion {
    
    NSString *endpoint = [NSString stringWithFormat:@"issuing/cards/%@/push_provisioning_details", params.cardId];
    NSDictionary *parameters = @{
                                 @"ios": @{
                                         @"certificates": params.certificatesBase64,
                                         @"nonce": params.nonceHex,
                                         @"nonce_signature": params.nonceSignatureHex,
                                         },
                                 };
    
    [STPAPIRequest<STPPushProvisioningDetails *> getWithAPIClient:self
                                                         endpoint:endpoint
                                                additionalHeaders:[self authorizationHeaderUsingEphemeralKey:ephemeralKey]
                                                       parameters:parameters
                                                     deserializer:[STPPushProvisioningDetails new]
                                                       completion:^(STPPushProvisioningDetails *details, __unused     NSHTTPURLResponse *response, NSError *error) {
        completion(details, error);
    }];
}
    
@end

void linkSTPAPIClientPushProvisioningCategory(void){}
