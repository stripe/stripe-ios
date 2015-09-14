//
//  STPCard.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import <Foundation/Foundation.h>

#import "STPCardBrand.h"

/**
 *  The various funding sources for a payment card.
 */
typedef NS_ENUM(NSInteger, STPCardFundingType) {
    STPCardFundingTypeDebit,
    STPCardFundingTypeCredit,
    STPCardFundingTypePrepaid,
    STPCardFundingTypeOther,
};

/**
 *  Representation of a user's credit card details. You can assemble these with information that your user enters and
 *  then create Stripe tokens with them using an STPAPIClient. @see https://stripe.com/docs/api#cards
 */
@interface STPCard : NSObject

/**
 *  The card's number. This will be nil for cards retrieved from the Stripe API.
 */
@property (nonatomic, copy, nullable) NSString *number;

/**
 *  The last 4 digits of the card. Unlike number, this will be present on cards retrieved from the Stripe API.
 */
@property (nonatomic, readonly, nullable) NSString *last4;

/**
 *  For cards made with Apple Pay, this refers to the last 4 digits of the "Device Account Number" for the tokenized card. For regular cards, it will be nil.
 */
@property (nonatomic, readonly, nullable) NSString *dynamicLast4;

/**
 *  The card's expiration month.
 */
@property (nonatomic) NSUInteger expMonth;

/**
 *  The card's expiration year.
 */
@property (nonatomic) NSUInteger expYear;

/**
 *  The card's security code, found on the back. This will be nil for cards retrieved from the Stripe API.
 */
@property (nonatomic, copy, nullable) NSString *cvc;

/**
 *  The cardholder's name.
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 *  The cardholder's address.
 */
@property (nonatomic, copy, nullable) NSString *addressLine1;
@property (nonatomic, copy, nullable) NSString *addressLine2;
@property (nonatomic, copy, nullable) NSString *addressCity;
@property (nonatomic, copy, nullable) NSString *addressState;
@property (nonatomic, copy, nullable) NSString *addressZip;
@property (nonatomic, copy, nullable) NSString *addressCountry;

/**
 *  The Stripe ID for the card.
 */
@property (nonatomic, readonly, nullable) NSString *cardId;

/**
 *  The issuer of the card.
 */
@property (nonatomic, readonly) STPCardBrand brand;

/**
 *  The issuer of the card.
 *  Can be one of "Visa", "American Express", "MasterCard", "Discover", "JCB", "Diners Club", or "Unknown"
 *  @deprecated use "brand" instead.
 */
@property (nonatomic, readonly, nonnull) NSString *type __attribute__((deprecated));

/**
 *  The funding source for the card (credit, debit, prepaid, or other)
 */
@property (nonatomic, readonly) STPCardFundingType funding;

/**
 *  A proxy for the card's number, this uniquely identifies the credit card and can be used to compare different cards.
 *  @deprecated This field will no longer be present in responses when using your publishable key. If you want to access the value of this field, you can look it up on your backend using your secret key.
 */
@property (nonatomic, readonly, nullable) NSString *fingerprint __attribute__((deprecated("This field will no longer be present in responses when using your publishable key. If you want to access the value of this field, you can look it up on your backend using your secret key.")));

/**
 *  Two-letter ISO code representing the issuing country of the card.
 */
@property (nonatomic, readonly, nullable) NSString *country;

/**
 *  This is only applicable when tokenizing debit cards to issue payouts to managed accounts. You should not set it otherwise. The card can then be used as a transfer destination for funds in this currency.
 */
@property (nonatomic, copy, nullable) NSString *currency;

/**
 *  Validate each field of the card.
 *  @return whether or not that field is valid.
 *  @deprecated use STPCardValidator instead.
 */
- (BOOL)validateNumber:(__nullable id * __nullable )ioValue
                 error:(NSError * __nullable * __nullable )outError __attribute__((deprecated("Use STPCardValidator instead.")));
- (BOOL)validateCvc:(__nullable id * __nullable )ioValue
              error:(NSError * __nullable * __nullable )outError __attribute__((deprecated("Use STPCardValidator instead.")));
- (BOOL)validateExpMonth:(__nullable  id * __nullable )ioValue
                   error:(NSError * __nullable * __nullable )outError __attribute__((deprecated("Use STPCardValidator instead.")));
- (BOOL)validateExpYear:(__nullable id * __nullable)ioValue
                  error:(NSError * __nullable * __nullable )outError __attribute__((deprecated("Use STPCardValidator instead.")));

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
 *  @deprecated use STPCardValidator instead.
 */
- (BOOL)validateCardReturningError:(NSError * __nullable * __nullable)outError __attribute__((deprecated("Use STPCardValidator instead.")));

@end

// This method is used internally by Stripe to deserialize API responses and exposed here for convenience and testing purposes only. You should not use it in
// your own code.
@interface STPCard (PrivateMethods)
- (nonnull instancetype)initWithAttributeDictionary:(nonnull NSDictionary *)attributeDictionary;
@end
