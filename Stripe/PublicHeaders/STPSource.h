//
//  STPSource.h
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"
#import "STPSourceCardDetails.h"
#import "STPSourceProtocol.h"
#import "STPSourceOwner.h"
#import "STPSourceReceiver.h"
#import "STPSourceRedirect.h"
#import "STPSourceVerification.h"

/**
 *  Authentication flows for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceFlow) {
    STPSourceFlowRedirect,
    STPSourceFlowReceiver,
    STPSourceFlowVerification,
    STPSourceFlowNone,
    STPSourceFlowUnknown
};

/**
 *  Usage types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceUsage) {
    STPSourceUsageReusable,
    STPSourceUsageSingleUse,
    STPSourceUsageUnknown
};

/**
 *  Status types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceStatus) {
    STPSourceStatusPending,
    STPSourceStatusChargeable,
    STPSourceStatusConsumed,
    STPSourceStatusCanceled,
    STPSourceStatusUnknown,
};

/**
 *  Types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceType) {
    STPSourceTypeBancontact,
    STPSourceTypeBitcoin,
    STPSourceTypeCard,
    STPSourceTypeGiropay,
    STPSourceTypeIDEAL,
    STPSourceTypeSEPADebit,
    STPSourceTypeSofort,
    STPSourceTypeThreeDSecure,
    STPSourceTypeUnknown,
};

@class STPSourceOwner, STPSourceReceiver, STPSourceRedirect, STPSourceVerification;

@interface STPSource : NSObject<STPAPIResponseDecodable, STPSourceProtocol>

/**
 *  You cannot directly instantiate an `STPSource`. You should only use one that has been returned from an `STPAPIClient` callback.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPSource. You should only use one that has been returned from an STPAPIClient callback.")));

/**
 *  The amount associated with the source.
 */
@property (nonatomic, readonly, nullable) NSNumber *amount;

/**
 *  The client secret of the source. Used for client-side polling using a publishable key.
 */
@property (nonatomic, readonly, nullable) NSString *clientSecret;

/**
 *  When the source was created.
 */
@property (nonatomic, readonly, nullable) NSDate *created;

/**
 *  The currency associated with the source.
 */
@property (nonatomic, readonly, nullable) NSString *currency;

/**
 *  The authentication flow of the source.
 */
@property (nonatomic, readonly) STPSourceFlow flow;

/**
 *  Whether or not this source was created in livemode.
 */
@property (nonatomic, readonly) BOOL livemode;

/**
 *  A set of key/value pairs associated with the source object.
 */
@property (nonatomic, readonly, nullable) NSDictionary *metadata;

/**
 *  Information about the owner of the payment instrument.
 */
@property (nonatomic, readonly, nullable) STPSourceOwner *owner;

/**
 *  Information related to the receiver flow. Present if the source is a receiver.
 */
@property (nonatomic, readonly, nullable) STPSourceReceiver *receiver;

/**
 *  Information related to the redirect flow. Present if the source is authenticated by a redirect.
 */
@property (nonatomic, readonly, nullable) STPSourceRedirect *redirect;

/**
 *  The status of the source.
 */
@property (nonatomic, readonly) STPSourceStatus status;

/**
 *  The type of the source.
 */
@property (nonatomic, readonly) STPSourceType type;

/**
 *   Whether this source should be reusable or not.
 */
@property (nonatomic, readonly) STPSourceUsage usage;

/**
 *  Information related to the verification flow. Present if the source is authenticated by a verification.
 */
@property (nonatomic, readonly, nullable) STPSourceVerification *verification;

/**
 *  Information about the source specific to its type
 */
@property (nonatomic, readonly, nullable) NSDictionary *details;

/**
 *  If this is a card source, this property provides typed access to the
 *  contents of the `details` dictionary.
 */
@property (nonatomic, readonly, nullable) STPSourceCardDetails *cardDetails;

@end
