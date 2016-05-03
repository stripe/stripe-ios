//
//  STPAddress.h
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#import <AddressBook/AddressBook.h>
#pragma clang diagnostic pop

#define FAUXPAS_IGNORED_IN_METHOD(...)
#define FAUXPAS_IGNORED_ON_LINE(...)

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

/**
 *  What set of billing address information you need to collect from your user.
 */
typedef NS_ENUM(NSUInteger, STPBillingAddressFields) {
    /**
     *  No billing address information
     */
    STPBillingAddressFieldsNone,
    /**
     *  Just request the user's billing ZIP code
     */
    STPBillingAddressFieldsZip,
    /**
     *  Request the user's full billing address
     */
    STPBillingAddressFieldsFull,
};

/**
 *  STPAddress wraps ABRecordRef and CNContact objects returned by iOS and adapts them to the Stripe API.
 */
@interface STPAddress : NSObject

/**
 *  The user's full name (e.g. "Jane Doe")
 */
@property (nonatomic, strong) NSString *name;

/**
 *  The first line of the user's street address (e.g. "123 Fake St")
 */
@property (nonatomic, strong) NSString *line1;

/**
 *  The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
 */
@property (nonatomic, strong) NSString *line2;

/**
 *  The city in which the user resides (e.g. "San Francisco")
 */
@property (nonatomic, strong) NSString *city;

/**
 *  The state in which the user resides (e.g. "CA")
 */
@property (nonatomic, strong) NSString *state;

/**
 *  The postal code in which the user resides (e.g. "90210")
 */
@property (nonatomic, strong) NSString *postalCode;

/**
 *  The ISO country code of the address (e.g. "US")
 */
@property (nonatomic, strong) NSString *country;

/**
 *  The phone number of the address (e.g. "8885551212")
 */
@property (nonatomic, strong) NSString *phone;

/**
 *  The email of the address (e.g. "jane@doe.com")
 */
@property (nonatomic, strong) NSString *email;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (instancetype)initWithABRecord:(ABRecordRef)record;
#pragma clang diagnostic pop

- (BOOL)containsRequiredFields:(STPBillingAddressFields)requiredFields;

+ (PKAddressField)applePayAddressFieldsFromBillingAddressFields:(STPBillingAddressFields)billingAddressFields; FAUXPAS_IGNORED_ON_LINE(APIAvailability);

@end
