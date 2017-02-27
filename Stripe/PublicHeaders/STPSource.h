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
#import "STPSourceSEPADebitDetails.h"
#import "STPSourceVerification.h"

/**
 *  Authentication flows for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceFlow) {
    // No action is required from your customer.
    STPSourceFlowNone,
    // Your customer must be redirected to their online banking service (either a website or mobile banking app) to approve the payment.
    STPSourceFlowRedirect,
    // Your customer must verify ownership of their account by providing a code that you post to the Stripe API for authentication.
    STPSourceFlowCodeVerification,
    // Your customer must push funds to the account information provided.
    STPSourceFlowReceiver,
    // The source's flow is unknown. You shouldn't encounter this value.
    STPSourceFlowUnknown
};

/**
 *  Usage types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceUsage) {
    // The source can be reused.
    STPSourceUsageReusable,
    // The source can only be used once.
    STPSourceUsageSingleUse,
    // The source's usage is unknown. You shouldn't encounter this value.
    STPSourceUsageUnknown
};

/**
 *  Status types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceStatus) {
    // The source has been created and is awaiting customer action.
    STPSourceStatusPending,
    // The source is ready to use. The customer action has been completed or the payment method requires no customer action.
    STPSourceStatusChargeable,
    // The source has been used. This status only applies to single-use sources.
    STPSourceStatusConsumed,
    // The source, which was chargeable, has expired because it was not used to make a charge request within a specified amount of time.
    STPSourceStatusCanceled,
    // Your customer has not taken the required action or revoked your access (e.g., did not authorize the payment with their bank or canceled their mandate acceptance for SEPA direct debits).
    STPSourceStatusFailed,
    // The source status is unknown. You shouldn't encounter this value.
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

/**
 *  Representation of a customer's payment instrument created with the Stripe API. @see https://stripe.com/docs/api#sources
 */
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

/**
 *  If this is a SEPA Debit source, this property provides typed access to the
 *  contents of the `details` dictionary.
 */
@property (nonatomic, readonly, nullable) STPSourceSEPADebitDetails *sepaDebitDetails;

@end
