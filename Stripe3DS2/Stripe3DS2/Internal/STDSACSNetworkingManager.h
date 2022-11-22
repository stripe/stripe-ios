//
//  STDSACSNetworkingManager.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 4/3/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSChallengeRequestParameters;
@class STDSErrorMessage;
@protocol STDSChallengeResponse;

NS_ASSUME_NONNULL_BEGIN

@interface STDSACSNetworkingManager : NSObject

- (instancetype)initWithURL:(NSURL *)acsURL
    sdkContentEncryptionKey:(NSData *)sdkCEK
    acsContentEncryptionKey:(NSData *)acsCEK
   acsTransactionIdentifier:(NSString *)acsTransactionID;

- (void)submitChallengeRequest:(STDSChallengeRequestParameters *)request withCompletion:(void (^)(id<STDSChallengeResponse> _Nullable, NSError * _Nullable))completion;

- (void)sendErrorMessage:(STDSErrorMessage *)errorMessage;

@end

NS_ASSUME_NONNULL_END
