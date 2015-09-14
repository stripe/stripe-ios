//
//  STPBankAccount.h
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import <Foundation/Foundation.h>



/**
 *  Representation of a user's credit card details. You can assemble these with information that your user enters and
 *  then create Stripe tokens with them using an STPAPIClient. @see https://stripe.com/docs/api#create_bank_account_token
 */
@interface STPBankAccount : NSObject

/**
 *  The account number for the bank account. Currently must be a checking account.
 */
@property (nonatomic, copy, nullable) NSString *accountNumber;

/**
 *  The routing number for the bank account. This should be the ACH routing number, not the wire routing number.
 */
@property (nonatomic, copy, nullable) NSString *routingNumber;

/**
 *  The country the bank account is in.
 */
@property (nonatomic, copy, nullable) NSString *country;

/**
 *  The default currency for the bank account.
 */
@property (nonatomic, copy, nullable) NSString *currency;

#pragma mark - These fields are only present on objects returned from the Stripe API.
/**
 *  The Stripe ID for the bank account.
 */
@property (nonatomic, readonly, nullable) NSString *bankAccountId;

/**
 *  The last 4 digits of the account number.
 */
@property (nonatomic, readonly, nullable) NSString *last4;

/**
 *  The name of the bank that owns the account.
 */
@property (nonatomic, readonly, nullable) NSString *bankName;

/**
 *  A proxy for the account number, this uniquely identifies the account and can be used to compare equality of different bank accounts.
 */
@property (nonatomic, readonly, nullable) NSString *fingerprint;

/**
 *  Whether or not the bank account has been validated via microdeposits or other means.
 */
@property (nonatomic, readonly) BOOL validated;

/**
 *  Whether or not the bank account is currently disabled.
 */
@property (nonatomic, readonly) BOOL disabled;

@end


// This method is used internally by Stripe to deserialize API responses and exposed here for convenience and testing purposes only. You should not use it in your own code.
@interface STPBankAccount (PrivateMethods)

- (nonnull instancetype)initWithAttributeDictionary:(nonnull NSDictionary *)attributeDictionary;

@end
