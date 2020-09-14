//
//  STPConnectAccountCompanyParams.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPConnectAccountAddress.h"
#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Information about the company or business to use with `STPConnectAccountParams`.

 @see https://stripe.com/docs/api/tokens/create_account#create_account_token-account-company
 */
@interface STPConnectAccountCompanyParams : NSObject <STPFormEncodable>

/**
 The company’s primary address.
 */
@property (nonatomic, strong) STPConnectAccountAddress *address;

/**
 The Kana variation of the company’s primary address (Japan only).
 */
@property (nonatomic, nullable) STPConnectAccountAddress *kanaAddress;

/**
 The Kanji variation of the company’s primary address (Japan only).
 */
@property (nonatomic, nullable) STPConnectAccountAddress *kanjiAddress;

/**
 Whether the company’s directors have been provided.
 
 Set this Boolean to true after creating all the company’s directors with the Persons API (https://stripe.com/docs/api/persons) for accounts with a relationship.director requirement.
 This value is not automatically set to true after creating directors, so it needs to be updated to indicate all directors have been provided.
 */
@property (nonatomic, nullable) NSNumber *directorsProvided;

/**
 The company’s legal name.
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 The Kana variation of the company’s legal name (Japan only).
 */
@property (nonatomic, copy, nullable) NSString *kanaName;

/**
 The Kanji variation of the company’s legal name (Japan only).
 */
@property (nonatomic, copy, nullable) NSString *kanjiName;

/**
 Whether the company’s owners have been provided.
 
 Set this Boolean to true after creating all the company’s owners with the Persons API (https://stripe.com/docs/api/persons) for accounts with a relationship.owner requirement.
 */
@property (nonatomic, nullable) NSNumber *ownersProvided;

/**
 The company’s phone number (used for verification).
 */
@property (nonatomic, copy, nullable) NSString *phone;

/**
 The business ID number of the company, as appropriate for the company’s country.
 
 (Examples are an Employer ID Number in the U.S., a Business Number in Canada, or a Company Number in the UK.)
 */
@property (nonatomic, copy, nullable) NSString *taxID;

/**
 The jurisdiction in which the taxID is registered (Germany-based companies only).
 */
@property (nonatomic, copy, nullable) NSString *taxIDRegistrar;

/**
 The VAT number of the company.
 */
@property (nonatomic, copy, nullable) NSString *vatID;

@end

NS_ASSUME_NONNULL_END
