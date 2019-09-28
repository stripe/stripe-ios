//
//  STPAPIClient+PushProvisioning.m
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient+PushProvisioning.h"
#import "STPAPIRequest.h"

@implementation STPAPIClient (PushProvisioning)

- (void)retrievePushProvisioningDetailsWithParams:(STPPushProvisioningDetailsParams *)params
                                    completion:(STPPushProvisioningDetailsCompletionBlock)completion {
    
    NSString *endpoint = [NSString stringWithFormat:@"issuing/cards/%@/push_provisioning_details", params.cardId];
    NSMutableArray<NSString*>* base64Certificates = [NSMutableArray arrayWithCapacity:params.certificates.count];
    for (NSData *certificate in params.certificates) {
        NSString *base64Certificate = [certificate base64EncodedStringWithOptions:kNilOptions];
        [base64Certificates addObject:base64Certificate];
    }
    
    NSString *nonceHexString = [self.class hexadecimalStringForData:params.nonce];
    NSString *nonceSignatureHexString = [self.class hexadecimalStringForData:params.nonceSignature];
    
    NSDictionary *parameters = @{
                                 @"ios": @{
                                         @"certificates": base64Certificates,
                                         @"nonce": nonceHexString,
                                         @"nonce_signature": nonceSignatureHexString,
                                         },
                                 };
    
    [STPAPIRequest<STPPushProvisioningDetails *> getWithAPIClient:self
                                                      endpoint:endpoint
                                                    parameters:parameters
                                                  deserializer:[STPPushProvisioningDetails new]
                                                    completion:^(STPPushProvisioningDetails *details, __unused     NSHTTPURLResponse *response, NSError *error) {
                                                        completion(details, error);
                                                    }];
}

+ (NSString *)hexadecimalStringForData:(NSData *)data {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (NSUInteger i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}
    
@end
