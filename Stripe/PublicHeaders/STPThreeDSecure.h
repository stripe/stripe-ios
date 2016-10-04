//
//  STPThreeDSecure.h
//  Stripe
//
//  Created by Brian Dorfman on 9/26/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@class STPCard;

typedef NS_ENUM(NSInteger, STPThreeDSecureStatus) {
    STPThreeDSecureStatusRedirectPending,
    STPThreeDSecureStatusSucceeded,
    STPThreeDSecureStatusFailed,
};

@interface STPThreeDSecure : NSObject <STPAPIResponseDecodable, STPSource>
@property (nonatomic, readonly, nullable) NSString *threeDSecureId;
@property (nonatomic, readonly) NSInteger paymentAmount;
@property (nonatomic, readonly, nullable) NSString *paymentCurrency;
@property (nonatomic, readonly) BOOL authenticated;
@property (nonatomic, readonly, nullable) STPCard *card;
@property (nonatomic, readonly, nullable) NSString *redirectURL;
@property (nonatomic, readonly,) STPThreeDSecureStatus status;
@end

@interface STPThreeDSecureParams : NSObject
@property (nonatomic) NSInteger paymentAmount;
@property (nonatomic) NSString *paymentCurrency;
@property (nonatomic) NSString *cardId;
@end

NS_ASSUME_NONNULL_END
