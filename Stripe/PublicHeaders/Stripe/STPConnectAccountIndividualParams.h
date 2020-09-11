//
//  STPConnectAccountIndividualParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPConnectAccountAddress.h"
#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

@class STPConnectAccountIndividualVerification, STPConnectAccountVerificationDocument;

/**
 Information about the person represented by the account for use with `STPConnectAccountParams`.
 
 @see https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual
 */
@interface STPConnectAccountIndividualParams : NSObject <STPFormEncodable>

/**
 The individual’s primary address.
 */
@property (nonatomic, nullable) STPConnectAccountAddress *address;

/**
 The Kana variation of the the individual’s primary address (Japan only).
 */
@property (nonatomic, nullable) STPConnectAccountAddress *kanaAddress;

/**
 The Kanji variation of the the individual’s primary address (Japan only).
 */
@property (nonatomic, nullable) STPConnectAccountAddress *kanjiAddress;

/**
 The individual’s date of birth.

 Must include `day`, `month`, and `year`, and only those fields are used.
 */
@property (nonatomic, copy, nullable) NSDateComponents *dateOfBirth;

/**
 The individual's email address.
 */
@property (nonatomic, copy, nullable) NSString *email;

/**
 The individual’s first name.
 */
@property (nonatomic, copy, nullable) NSString *firstName;

/**
 The Kana variation of the the individual’s first name (Japan only).
 */
@property (nonatomic, copy, nullable) NSString *kanaFirstName;

/**
 The Kanji variation of the individual’s first name (Japan only).
 */
@property (nonatomic, copy, nullable) NSString *kanjiFirstName;

/**
 The individual’s gender
 
 International regulations require either “male” or “female”.
 */
@property (nonatomic, copy, nullable) NSString *gender;

/**
 The government-issued ID number of the individual, as appropriate for the representative’s country.
 Examples are a Social Security Number in the U.S., or a Social Insurance Number in Canada.
 
 Instead of the number itself, you can also provide a PII token created with Stripe.js (see https://stripe.com/docs/stripe-js/reference#collecting-pii-data).
 */
@property (nonatomic, copy, nullable) NSString *idNumber;

/**
 The individual’s last name.
 */
@property (nonatomic, copy, nullable) NSString *lastName;

/**
 The Kana varation of the individual’s last name (Japan only).
 */
@property (nonatomic, copy, nullable) NSString *kanaLastName;

/**
 The Kanji varation of the individual’s last name (Japan only).
 */
@property (nonatomic, copy, nullable) NSString *kanjiLastName;

/**
 The individual’s maiden name.
 */
@property (nonatomic, copy, nullable) NSString *maidenName;

/**
 Set of key-value pairs that you can attach to an object.
 
 This can be useful for storing additional information about the object in a structured format.
 */
@property (nonatomic, copy, nullable) NSDictionary *metadata;

/**
 The individual’s phone number.
 */
@property (nonatomic, copy, nullable) NSString *phone;

/**
 The last four digits of the individual’s Social Security Number (U.S. only).
 */
@property (nonatomic, copy, nullable) NSString *ssnLast4;

/**
 The individual’s verification document information.
 */
@property (nonatomic, strong, nullable) STPConnectAccountIndividualVerification *verification;

@end

#pragma mark -

/**
 The individual’s verification document information for use with `STPConnectAccountIndividualParams`.
 */
@interface STPConnectAccountIndividualVerification: NSObject <STPFormEncodable>

/**
 An identifying document, either a passport or local ID card.
 */
@property (nonatomic, strong, nullable) STPConnectAccountVerificationDocument *document;

@end
           
#pragma mark -

/**
 An identifying document, either a passport or local ID card for use with `STPConnectAccountIndividualVerification`.
 */
@interface STPConnectAccountVerificationDocument: NSObject<STPFormEncodable>
           
/**
 The back of an ID returned by a file upload with a `purpose` value of `identity_document`.
 
 @see https://stripe.com/docs/api/files/create for file uploads
 */
@property (nonatomic, copy, nullable) NSString *back;

/**
 The front of an ID returned by a file upload with a `purpose` value of `identity_document`.

 @see https://stripe.com/docs/api/files/create for file uploads
 */
@property (nonatomic, copy, nullable) NSString *front;

@end

#pragma mark - Date of Birth

/**
 An individual's date of birth.
 
 See https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual-dob
 */
@interface STPDateOfBirth : NSObject <STPFormEncodable>

/**
 The day of birth, between 1 and 31.
 */
@property (nonatomic) NSInteger day;

/**
 The month of birth, between 1 and 12.
 */
@property (nonatomic) NSInteger month;

/**
 The four-digit year of birth.
 */
@property (nonatomic) NSInteger year;

@end

NS_ASSUME_NONNULL_END
