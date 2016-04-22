//
//  STPAddress.h
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <PassKit/PassKit.h>

typedef NS_ENUM(NSUInteger, STPBillingAddressField) {
    STPBillingAddressFieldNone,
    STPBillingAddressFieldZip,
    STPBillingAddressFieldFull,
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

- (instancetype)initWithABRecord:(ABRecordRef)record;
- (BOOL)containsRequiredFields:(PKAddressField)requiredFields;

@end

#pragma clang diagnostic pop
