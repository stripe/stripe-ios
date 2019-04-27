//
//  STPConnectIndividualAccountParams.h
//  Stripe
//
//  Created by Peter Suwara on 27/4/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

@class STPIndividualParams;

NS_ASSUME_NONNULL_BEGIN

/**
 Parameters for creating a Connect Account token.
 */
@interface STPConnectIndividualAccountParams : NSObject<STPFormEncodable>

/**
 Optional boolean indicating that the Terms Of Service were shown to the user &
 the user accepted them.
 */
@property (nonatomic, nullable, readonly) NSNumber *tosShownAndAccepted;

/**
 Required string that defines the business type. In this case it needs to be "individual"
 */
@property (nonatomic, nullable, readonly) NSString *businessType;

/**
 Required property that defines the individual for an account.

 At least one field in the legalEntity must have a value, otherwise the create token
 call will fail.
 */
@property (nonatomic, readonly) STPIndividualParams *individual;

/**
 `STPConnectIndividualAccountParams` cannot be directly instantiated, use `initWithTosShownAndAccepted:businesstype:legalEntity:`
 or `initWithLegalEntity:`
 */
- (instancetype)init __attribute__((unavailable("Cannot be directly instantiated")));

/**
 Initialize `STPConnectIndividualAccountParams` with tosShownAndAccepted = YES

 This method cannot be called with `wasAccepted == NO`, guarded by a `NSParameterAssert()`.

 Use this init method if you want to set the `tosShownAndAccepted` parameter. If you
 don't, use the `initWithLegalEntity:` version instead.

 @param wasAccepted Must be YES, but only if the user was shown & accepted the ToS
 @param individual The data associated with the individual
 @param businessType Indicates whether this will be an individual or company
 */
- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                               businessType:(NSString *)businessType
                                 individual:(STPIndividualParams*)individual;

/**
 Initialize `STPConnectIndividualAccountParams` with the `STPLegalEntityParams` provided.

 This init method cannot change the `tosShownAndAccepted` parameter. Use
 `initWithTosShownAndAccepted:legalEntity:` instead if you need to do that.

 These two init methods exist to avoid the (slightly awkward) NSNumber box that would
 be needed around `tosShownAndAccepted` if it was optional/nullable, and to enforce
 that it is either nil or YES. This also forces the business type to "individual"

 @param individual The data associated with the individual
 */
- (instancetype)initWithIndividual:(STPIndividualParams *)individual;

@end

NS_ASSUME_NONNULL_END


