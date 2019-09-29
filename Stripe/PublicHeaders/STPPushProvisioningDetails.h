//
//  STPPushProvisioningDetails.h
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPushProvisioningDetails : NSObject <STPAPIResponseDecodable>

@property (nonatomic, readonly) NSString *cardId;
@property (nonatomic, readonly) BOOL livemode;
@property (nonatomic, readonly) NSData *encryptedPassData;
@property (nonatomic, readonly) NSData *activationData;
@property (nonatomic, readonly) NSData *ephemeralPublicKey;
    
+ (instancetype)detailsWithCardId:(NSString *)cardId
                         livemode:(BOOL)livemode
                encryptedPassData:(NSData *)encryptedPassData
                   activationData:(NSData *)activationData
               ephemeralPublicKey:(NSData *)ephemeralPublicKey;

@end

NS_ASSUME_NONNULL_END
