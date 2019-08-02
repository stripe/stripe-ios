//
//  STPConnectAccountParams.h
//  Stripe
//
//  Created by Daniel Jackson on 1/4/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

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
 
 @see https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual
 */
@property (nonatomic, nullable, readonly) NSDictionary *individual;

/**
 Information about the company or business.
 
 @see https://stripe.com/docs/api/tokens/create_account#create_account_token-account-company
 */
@property (nonatomic, nullable, readonly) NSDictionary *company;

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
 @param individual Information about the person represented by the account, as documented
 here: https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual
 */
- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                 individual:(NSDictionary *)individual;

/**
 Initialize `STPConnectAccountParams` with tosShownAndAccepted = YES
 
 This method cannot be called with `wasAccepted == NO`, guarded by a `NSParameterAssert()`.
 
 Use this init method if you want to set the `tosShownAndAccepted` parameter. If you
 don't, use the `initWithCompany:` version instead.
 
 @param wasAccepted Must be YES, but only if the user was shown & accepted the ToS
 @param company Information about the company or business, as documented
 here https://stripe.com/docs/api/tokens/create_account#create_account_token-account-company
 */
- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                    company:(NSDictionary *)company;

/**
 Initialize `STPConnectAccountParams` with the provided `individual` dictionary.
 
 @param individual Information about the person represented by the account, as documented
 here: https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual
 

 This init method cannot change the `tosShownAndAccepted` parameter. Use
 `initWithTosShownAndAccepted:individual:` instead if you need to do that.
 */
- (instancetype)initWithIndividual:(NSDictionary *)individual;

/**
 Initialize `STPConnectAccountParams` with the provided `company` dictionary.
 
 @param company Information about the company or business, as documented
 here https://stripe.com/docs/api/tokens/create_account#create_account_token-account-company
 
 This init method cannot change the `tosShownAndAccepted` parameter. Use
 `initWithTosShownAndAccepted:company:` instead if you need to do that.
 */
- (instancetype)initWithCompany:(NSDictionary *)company;

@end

NS_ASSUME_NONNULL_END
