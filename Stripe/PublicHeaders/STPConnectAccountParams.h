//
//  STPConnectAccountParams.h
//  Stripe
//
//  Created by Daniel Jackson on 1/4/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

/**
 The business type of the Connect account.
 */
typedef NS_ENUM(NSInteger, STPConnectAccountBusinessType) {
    /**
     This Connect account represents an individual.
     */
    STPConnectAccountBusinessTypeIndividual,
    
    /**
     This Connect account represents a company.
     */
    STPConnectAccountBusinessTypeCompany
};

NS_ASSUME_NONNULL_BEGIN

@class STPConnectAccountIndividualParams;
@class STPConnectAccountCompanyParams;

/**
 Parameters for creating a Connect Account token.
 
 @see https://stripe.com/docs/api/tokens/create_account
 */
@interface STPConnectAccountParams : NSObject<STPFormEncodable>

/**
 Optional boolean indicating that the Terms Of Service were shown to the user &
 the user accepted them.
 */
@property (nonatomic, nullable, readonly) NSNumber *tosShownAndAccepted;

/**
 The business type.
 */
@property (nonatomic, readonly) STPConnectAccountBusinessType businessType;

/**
 Information about the individual represented by the account.
 
 */
@property (nonatomic, nullable, readonly) STPConnectAccountIndividualParams *individual;

/**
 Information about the company or business.
 */
@property (nonatomic, nullable, readonly) STPConnectAccountCompanyParams *company;

/**
 `STPConnectAccountParams` cannot be directly instantiated.
 */
- (instancetype)init __attribute__((unavailable("Cannot be directly instantiated")));

/**
 Initialize `STPConnectAccountParams` with tosShownAndAccepted = YES

 This method cannot be called with `wasAccepted == NO`, guarded by a `NSParameterAssert()`.

 Use this init method if you want to set the `tosShownAndAccepted` parameter. If you
 don't, use the `initWithIndividual:` version instead.

 @param wasAccepted Must be YES, but only if the user was shown & accepted the ToS
 @param individual Information about the person represented by the account. See `STPConnectAccountIndividualParams`.
 */
- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                 individual:(STPConnectAccountIndividualParams *)individual;

/**
 Initialize `STPConnectAccountParams` with tosShownAndAccepted = YES
 
 This method cannot be called with `wasAccepted == NO`, guarded by a `NSParameterAssert()`.
 
 Use this init method if you want to set the `tosShownAndAccepted` parameter. If you
 don't, use the `initWithCompany:` version instead.
 
 @param wasAccepted Must be YES, but only if the user was shown & accepted the ToS
 @param company Information about the company or business. See `STPConnectAccountCompanyParams`.
 */
- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                    company:(STPConnectAccountCompanyParams *)company;

/**
 Initialize `STPConnectAccountParams` with the provided `individual` dictionary.
 
 @param individual Information about the person represented by the account

 This init method cannot change the `tosShownAndAccepted` parameter. Use
 `initWithTosShownAndAccepted:individual:` instead if you need to do that.
 */
- (instancetype)initWithIndividual:(STPConnectAccountIndividualParams *)individual;

/**
 Initialize `STPConnectAccountParams` with the provided `company` dictionary.
 
 @param company Information about the company or business

 This init method cannot change the `tosShownAndAccepted` parameter. Use
 `initWithTosShownAndAccepted:company:` instead if you need to do that.
 */
- (instancetype)initWithCompany:(STPConnectAccountCompanyParams *)company;

@end

NS_ASSUME_NONNULL_END
