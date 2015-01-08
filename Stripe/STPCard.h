//
//  STPCard.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, STPCardFundingType) {
    STPCardFundingTypeDebit,
    STPCardFundingTypeCredit,
    STPCardFundingTypePrepaid,
    STPCardFundingTypeOther,
};

typedef NS_ENUM(NSInteger, STPCardBrand) {
    STPCardBrandVisa,
    STPCardBrandAmex,
    STPCardBrandMasterCard,
    STPCardBrandDiscover,
    STPCardBrandJCB,
    STPCardBrandDinersClub,
    STPCardBrandUnknown,
};

/**
 *  Representation of a user's credit card details. You can assemble these with information that your user enters and
 *  then create Stripe tokens with them using an STPAPIClient. @see https://stripe.com/docs/api#cards
 */
@interface STPCard : NSObject

/**
 *  The card's number. This will be nil for cards retrieved from the Stripe API.
 */
@property (nonatomic, copy) NSString *number;

/**
 *  The last 4 digits of the card. Unlike number, this will be present on cards retrieved from the Stripe API.
 */
@property (nonatomic, readonly) NSString *last4;

/**
 *  The card's expiration month.
 */
@property (nonatomic) NSUInteger expMonth;

/**
 *  The card's expiration month.
 */
@property (nonatomic) NSUInteger expYear;

/**
 *  The card's security code, found on the back. This will be nil for cards retrieved from the Stripe API.
 */
@property (nonatomic, copy) NSString *cvc;

/**
 *  The cardholder's name.
 */
@property (nonatomic, copy) NSString *name;

/**
 *  The cardholder's address.
 */
@property (nonatomic, copy) NSString *addressLine1;
@property (nonatomic, copy) NSString *addressLine2;
@property (nonatomic, copy) NSString *addressCity;
@property (nonatomic, copy) NSString *addressState;
@property (nonatomic, copy) NSString *addressZip;
@property (nonatomic, copy) NSString *addressCountry;

/**
 *  The Stripe ID for the card.
 */
@property (nonatomic, readonly) NSString *cardId;

/**
 *  The issuer of the card.
 */
@property (nonatomic, readonly) STPCardBrand brand;

/**
 *  The issuer of the card.
 *  Can be one of "Visa", "American Express", "MasterCard", "Discover", "JCB", "Diners Club", or "Unknown"
 *  @deprecated use "brand" instead.
 */
@property (nonatomic, readonly) NSString *type __attribute__((deprecated));

/**
 *  The funding source for the card (credit, debit, prepaid, or other)
 */
@property (nonatomic, readonly) STPCardFundingType funding;

/**
 *  A proxy for the card's number, this uniquely identifies the credit card and can be used to compare different cards.
 */
@property (nonatomic, readonly) NSString *fingerprint;

/**
 *  Two-letter ISO code representing the issuing country of the card.
 */
@property (nonatomic, readonly) NSString *country;

// These validation methods work as described in
// http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/KeyValueCoding/Articles/Validation.html#//apple_ref/doc/uid/20002173-CJBDBHCB

- (BOOL)validateNumber:(id *)ioValue error:(NSError **)outError;
- (BOOL)validateCvc:(id *)ioValue error:(NSError **)outError;
- (BOOL)validateExpMonth:(id *)ioValue error:(NSError **)outError;
- (BOOL)validateExpYear:(id *)ioValue error:(NSError **)outError;

/**
 *  This validates a fully populated card to check for all errors, including ones that come about
 *  from the interaction of more than one property. It will also do all the validations on individual
 *  properties, so if you only want to call one method on your card to validate it after setting all the
 *  properties, call this one
 *
 *  @param outError a pointer to an NSError that, after calling this method, will be populated with an error if the card is not valid. See StripeError.h for
 possible values
 *
 *  @return whether or not the card is valid.
 */
- (BOOL)validateCardReturningError:(NSError **)outError;

@end

// This method is used internally by Stripe to deserialize API responses and exposed here for convenience and testing purposes only. You should not use it in
// your own code.
@interface STPCard (PrivateMethods)
- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;
@end
