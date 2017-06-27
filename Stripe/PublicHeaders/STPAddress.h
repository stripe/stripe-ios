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
 *  What set of billing address information you need to collect from your user.
 *
 *  @note If the user is from a country that does not use zip/postal codes,
 *  the user may not be asked for one regardless of this setting.
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
 *  STPAddress Contains an address as represented by the Stripe API.
 */
@interface STPAddress : NSObject<STPAPIResponseDecodable>

/**
 *  The user's full name (e.g. "Jane Doe")
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 *  The first line of the user's street address (e.g. "123 Fake St")
 */
@property (nonatomic, copy, nullable) NSString *line1;

/**
 *  The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
 */
@property (nonatomic, copy, nullable) NSString *line2;

/**
 *  The city in which the user resides (e.g. "San Francisco")
 */
@property (nonatomic, copy, nullable) NSString *city;

/**
 *  The state in which the user resides (e.g. "CA")
 */
@property (nonatomic, copy, nullable) NSString *state;

/**
 *  The postal code in which the user resides (e.g. "90210")
 */
@property (nonatomic, copy, nullable) NSString *postalCode;

/**
 *  The ISO country code of the address (e.g. "US")
 */
@property (nonatomic, copy, nullable) NSString *country;

/**
 *  The phone number of the address (e.g. "8885551212")
 */
@property (nonatomic, copy, nullable) NSString *phone;

/**
 *  The email of the address (e.g. "jane@doe.com")
 */
@property (nonatomic, copy, nullable) NSString *email;

/**
 *  When creating a charge on your backend, you can attach shipping information
 *  to prevent fraud on a physical good. You can use this method to turn your user's
 *  shipping address and selected shipping method into a hash suitable for attaching 
 *  to a charge. You should pass this to your backend, and use it as the `shipping`
 *  parameter when creating a charge.
 *  @see https://stripe.com/docs/api#create_charge-shipping
 *
 *  @param address  The user's shipping address. If nil, this method will return nil.
 *  @param method   The user's selected shipping method. May be nil.
 */
+ (nullable NSDictionary *)shippingInfoForChargeWithAddress:(nullable STPAddress *)address
                                             shippingMethod:(nullable PKShippingMethod *)method;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (instancetype)initWithABRecord:(ABRecordRef)record;
- (ABRecordRef)ABRecordValue;
#pragma clang diagnostic pop

- (instancetype)initWithPKContact:(PKContact *)contact NS_AVAILABLE_IOS(9_0); FAUXPAS_IGNORED_ON_LINE(APIAvailability);
- (PKContact *)PKContactValue NS_AVAILABLE_IOS(9_0); FAUXPAS_IGNORED_ON_LINE(APIAvailability);

- (instancetype)initWithCNContact:(CNContact *)contact NS_AVAILABLE_IOS(9_0); FAUXPAS_IGNORED_ON_LINE(APIAvailability);

- (BOOL)containsRequiredFields:(STPBillingAddressFields)requiredFields;
- (BOOL)containsRequiredShippingAddressFields:(PKAddressField)requiredFields;

+ (PKAddressField)applePayAddressFieldsFromBillingAddressFields:(STPBillingAddressFields)billingAddressFields;

@end

NS_ASSUME_NONNULL_END
