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

typedef NS_ENUM(NSUInteger, STPBillingAddressFields) {
    STPBillingAddressFieldsNone,
    STPBillingAddressFieldsZip,
    STPBillingAddressFieldsFull,
};

@interface STPAddress : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *line1;
@property (nonatomic, strong) NSString *line2;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *postalCode;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (instancetype)initWithABRecord:(ABRecordRef)record;
#pragma clang diagnostic pop

- (BOOL)containsRequiredFields:(STPBillingAddressFields)requiredFields;

+ (PKAddressField)applePayAddressFieldsFromBillingAddressFields:(STPBillingAddressFields)billingAddressFields; FAUXPAS_IGNORED_ON_LINE(APIAvailability);

@end
