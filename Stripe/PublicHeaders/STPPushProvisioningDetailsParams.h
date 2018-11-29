//
//  STPPushProvisioningDetailsParams.h
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPushProvisioningDetailsParams : NSObject

@property (nonatomic, readonly) NSString *cardId;
@property (nonatomic, readonly) NSArray<NSData *> *certificates;
@property (nonatomic, readonly) NSData *nonce;
@property (nonatomic, readonly) NSData *nonceSignature;
    
+(instancetype)paramsWithCardId:(NSString *)cardId
                   certificates:(NSArray<NSData *>*)certificates
                          nonce:(NSData *)nonce
                 nonceSignature:(NSData *)nonceSignature;
    
@end

NS_ASSUME_NONNULL_END
