//
//  STPPushProvisioningContext.h
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>
#import "STPEphemeralKeyProvider.h"
#import "STPCard.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPushProvisioningContext : NSObject

+ (PKAddPaymentPassRequestConfiguration *)requestConfigurationWithName:(NSString *)name
                                                           description:(nullable NSString *)description
                                                                 last4:(nullable NSString *)last4
                                                                 brand:(STPCardBrand)brand;
- (instancetype)initWithKeyProvider:(id<STPIssuingCardEphemeralKeyProvider>)keyProvider;
- (void)addPaymentPassViewController:(PKAddPaymentPassViewController *)controller
 generateRequestWithCertificateChain:(NSArray<NSData *> *)certificates
                               nonce:(NSData *)nonce
                      nonceSignature:(NSData *)nonceSignature
                   completionHandler:(void (^)(PKAddPaymentPassRequest *))handler;
@end

NS_ASSUME_NONNULL_END
