//
//  STPAddress.h
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#define FAUXPAS_IGNORED_IN_METHOD(...)
#define FAUXPAS_IGNORED_ON_LINE(...)

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#import <AddressBook/AddressBook.h>
#pragma clang diagnostic pop

#import "STPAPIResponseDecodable.h"

@class CNContact;

NS_ASSUME_NONNULL_BEGIN

/**
 What set of billing address information you need to collect from your user.

 @note If the user is from a country that does not use zip/postal codes,
 the user may not be asked for one regardless of this setting.
 */
typedef NS_ENUM(NSUInteger, STPBillingAddressFields) {
    /**
     No billing address information
     */
    STPBillingAddressFieldsNone,
    /**
     Just request the user's billing ZIP code
     */
    STPBillingAddressFieldsZip,
    /**
     Request the user's full billing address
     */
    STPBillingAddressFieldsFull,
};

/**
 STPAddress Contains an address as represented by the Stripe API.
 */
@interface STPAddress : NSObject<STPAPIResponseDecodable>

/**
 The user's full name (e.g. "Jane Doe")
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 The first line of the user's street address (e.g. "123 Fake St")
 */
@property (nonatomic, copy, nullable) NSString *line1;

/**
 The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
 */
@property (nonatomic, copy, nullable) NSString *line2;

/**
 The city in which the user resides (e.g. "San Francisco")
 */
@property (nonatomic, copy, nullable) NSString *city;

/**
 The state in which the user resides (e.g. "CA")
 */
@property (nonatomic, copy, nullable) NSString *state;

/**
 The postal code in which the user resides (e.g. "90210")
 */
@property (nonatomic, copy, nullable) NSString *postalCode;

/**
 The ISO country code of the address (e.g. "US")
 */
@property (nonatomic, copy, nullable) NSString *country;

/**
 The phone number of the address (e.g. "8885551212")
 */
@property (nonatomic, copy, nullable) NSString *phone;

/**
 The email of the address (e.g. "jane@doe.com")
 */
@property (nonatomic, copy, nullable) NSString *email;

/**
 When creating a charge on your backend, you can attach shipping information
 to prevent fraud on a physical good. You can use this method to turn your user's
 shipping address and selected shipping method into a hash suitable for attaching 
 to a charge. You should pass this to your backend, and use it as the `shipping`
 parameter when creating a charge.
 @see https://stripe.com/docs/api#create_charge-shipping

 @param address  The user's shipping address. If nil, this method will return nil.
 @param method   The user's selected shipping method. May be nil.
 */
+ (nullable NSDictionary *)shippingInfoForChargeWithAddress:(nullable STPAddress *)address
                                             shippingMethod:(nullable PKShippingMethod *)method;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

/**
 Initializes a new STPAddress with data from an Address Book record.

 @param record The Address Book record you want to populate the STPAddress from.
 @return A new STPAddress instance with data copied from the passed in record.
 */
- (instancetype)initWithABRecord:(ABRecordRef)record;


/**
 Generates an Address Book record representation of this STPAddress.

 @return A new autoreleased Address Book record with data copied from this 
 STPAddress instance.
 */
- (ABRecordRef)ABRecordValue;
#pragma clang diagnostic pop

/**
 Initializes a new STPAddress with data from an PassKit contact.

 @param contact The PassKit contact you want to populate the STPAddress from.
 @return A new STPAddress instance with data copied from the passed in contact.
 */
- (instancetype)initWithPKContact:(PKContact *)contact NS_AVAILABLE_IOS(9_0); FAUXPAS_IGNORED_ON_LINE(APIAvailability);

/**
 Generates a PassKit contact representation of this STPAddress.

 @return A new PassKit contact with data copied from this STPAddress instance.
 */
- (PKContact *)PKContactValue NS_AVAILABLE_IOS(9_0); FAUXPAS_IGNORED_ON_LINE(APIAvailability);

/**
 Initializes a new STPAddress with a contact from the Contacts framework.

 @param contact The CNContact you want to populate the STPAddress from.

 @return A new STPAddress instance with data copied from the passed in contact.
 */
- (instancetype)initWithCNContact:(CNContact *)contact NS_AVAILABLE_IOS(9_0); FAUXPAS_IGNORED_ON_LINE(APIAvailability);


/**
 Checks if this STPAddress has the level of valid address information
 required by the passed in setting.

 @param requiredFields The required level of billing address information to 
 check against.

 @return YES if this address contains at least the necessary information,
 NO otherwise.
 */
- (BOOL)containsRequiredFields:(STPBillingAddressFields)requiredFields;

/**
 Checks if this STPAddress has any content (possibly invalid) in any of the
 desired billing address fields.

 Where `containsRequiredFields:` validates that this STPAddress contains valid data in
 all of the required fields, this method checks for the existence of *any* data.

 For example, if `desiredFields` is `STPBillingAddressFieldsZip`, this will check
 if the postalCode is empty.

 Note: When `desiredFields == STPBillingAddressFieldsNone`, this method always returns
 NO.

 @parameter desiredFields The billing address information the caller is interested in.
 @return YES if there is any data in this STPAddress that's relevant for those fields.
 */
- (BOOL)containsContentForBillingAddressFields:(STPBillingAddressFields)desiredFields;

/**
 Checks if this STPAddress has the level of valid address information
 required by the passed in setting.

 @param requiredFields The required shipping address information to check against.

 @return YES if this address contains at least the necessary information,
 NO otherwise.
 */
- (BOOL)containsRequiredShippingAddressFields:(PKAddressField)requiredFields;

/**
 Checks if this STPAddress has any content (possibly invalid) in any of the
 desired shipping address fields.

 Where `containsRequiredShippingAddressFields:` validates that this STPAddress
 contains valid data in all of the required fields, this method checks for the
 existence of *any* data.

 Note: When `desiredFields == PKAddressFieldNone`, this method always returns
 NO.

 @parameter desiredFields The shipping address information the caller is interested in.
 @return YES if there is any data in this STPAddress that's relevant for those fields.
 */
- (BOOL)containsContentForShippingAddressFields:(PKAddressField)desiredFields;

/**
 Converts an STPBillingAddressFields enum value into the closest equivalent
 representation of PKAddressField options

 @param billingAddressFields Stripe billing address fields enum value to convert.
 @return The closest represenation of the billing address requirement as 
 a PKAddressField value.
 */
+ (PKAddressField)applePayAddressFieldsFromBillingAddressFields:(STPBillingAddressFields)billingAddressFields;

@end

NS_ASSUME_NONNULL_END
